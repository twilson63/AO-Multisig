bint = require('.bint')(256)
local json = require("json")

local gtZero = function(a)
    a = a or 0
    if bint(a) < bint(0) then
        return bint(0)
    end
    return bint(a)
end

local calc = {
  add = function(a,b)
    a = gtZero(a)
    b = gtZero(b)

    return tostring(a + b)
  end,
  sub = function(a,b)
    a = gtZero(a)
    b = gtZero(b)
    
    return tostring(gtZero(a - b))
  end,
  isGreaterThan = function(a,b)
    return bint(a) > bint(b)
  end,
  isGreaterThanOrEqual = function(a,b)
    return bint(a) >= bint(b)
  end
}

-- Main contract state
local Multisig = {
    -- Map of owner addresses to bool
    Owners = {},
    -- Map of transaction IDs to transaction objects
    Transactions = {},
    -- Map of token IDs to balances
    TokenBalances = {},
    -- Contract settings
    Settings = {
        threshold = 0,
        owner_count = 0
    }
}

-- Validates AO address format
local function isValidAddress(address)
    return type(address) == "string" and address:match("^[a-zA-Z0-9_-]+$")
end

-- Notifies all owners about contract events
local function notifyOwners(action, payload)
    for owner in pairs(Multisig.Owners) do
        Send({
            Target = owner,
            Data = json.encode(payload),
            Tags = {
                Action = action,
                ["Process-Id"] = ao.id,
                ["Transaction-Id"] = payload.tx_id or ""
            }
        })
    end
end

-- Initialize the multisig contract
-- Expects: Owners (JSON array of addresses), Threshold (number)
Handlers.once("Init", function(msg)
    assert(not next(Multisig.Owners), "Contract already initialized")
    assert(msg.Target == ao.id, "Message must be sent to process")
    
    local owners = msg.Data.Owners
    local threshold = msg.Tags.Threshold
    
    assert(owners and threshold, "Missing required parameters")
    -- local success, decoded_owners = pcall(json.decode, owners)
    -- assert(success and type(decoded_owners) == "table", "Invalid owners format")

    -- Process owners from JSON array
    local owner_count = 0
    for _, address in ipairs(owners) do
        assert(isValidAddress(address), "Invalid owner address: " .. tostring(address))
        Multisig.Owners[address] = true
        owner_count = owner_count + 1
    end

    -- Set and validate threshold
    threshold = tonumber(threshold)
    assert(threshold > 0 and threshold <= owner_count, "Invalid threshold")
    Multisig.Settings.threshold = threshold
    Multisig.Settings.owner_count = owner_count

    msg.reply({
        Action = "Init-Reply", 
        Status = "success",
        Data = {
            owners = Multisig.Owners,
            threshold = threshold,
            owner_count = owner_count
        }
    })
end)

-- Handle token deposits into the multisig
-- Expects: From (address), Quantity (number)
Handlers.add("Credit-Notice", function(msg)
    local token = msg.From
    local amount = tonumber(msg.Quantity)
    
    assert(amount and amount > 0, "Invalid deposit parameters")

    -- Update token balance
    Multisig.TokenBalances[token] = calc.add(Multisig.TokenBalances[token], amount)

    notifyOwners("Token-Deposited", { 
        token = token, 
        amount = amount,
        balance = Multisig.TokenBalances[token]
    })
    
    print({
      Action = "Deposit-Reply",
      Status = "success",
      Token = token,
      Amount = tostring(amount),
      Balance = tostring(Multisig.TokenBalances[token]),
      Data = "Deposit-Reply success"
    })
end)

-- Propose a new transaction
-- Expects: Recipient (address), Token (address), Quantity (number)
Handlers.add("Propose", function(msg)
    assert(Multisig.Owners[msg.From], "Not an owner")
    
    local recipient = msg.Recipient
    local token = msg.Token
    local value = tonumber(msg.Quantity)
    
    -- Validate transaction parameters
    assert(recipient and token and value, "Missing transaction parameters")
    assert(isValidAddress(recipient), "Invalid target address")
    assert(isValidAddress(token), "Invalid token address")
    assert(calc.isGreaterThan(value, 0), "Value must be positive")
    assert(calc.isGreaterThanOrEqual(Multisig.TokenBalances[token], value), "Insufficient balance")
    -- Create transaction with automatic approval from proposer
    local tx = {
        proposer = msg.From,
        recipient = recipient,
        token = token,
        value = value,
        data = msg.Data,
        approvals = { [msg.From] = true },
        approval_count = 1,
        state = "pending"
    }
    print(tx)
    Multisig.Transactions[msg.Id] = tx

    -- Auto-execute if threshold is 1
    if Multisig.Settings.threshold == 1 then
        tx.state = "executed"

        local notice = Send({
            Target = tx.token, 
            Action = "Transfer",
            Recipient = recipient,
            Quantity = tostring(value)
        }).receive()

        if notice.Action == "Debit-Notice" then
            assert(notice.Quantity, "Missing Quantity tag")
            Multisig.TokenBalances[tx.token] = calc.sub(Multisig.TokenBalances[tx.token], notice.Quantity)

            notifyOwners("Transaction-Executed", { 
                tx_id = msg.Id,
                token = token,
                amount = notice.Quantity,
                balance = Multisig.TokenBalances[token]
            })
        end
    else
        notifyOwners("Transaction-Proposed", { 
            tx_id = msg.Id, 
            proposer = msg.From, 
            token = token, 
            value = value,
            needed = Multisig.Settings.threshold - 1
        })
    end

    msg.reply({
      Action = "Propose-Reply",
      Status = "success",
      TxId = msg.Id,
      State = tx.state,
      Data = "Propose-Reply Success"
    })
end)

-- Approve a pending transaction
-- Expects: TxId (transaction ID)
Handlers.add("Approve", function(msg)
    assert(Multisig.Owners[msg.From], "Not an owner")
    assert(msg.TxId, "Transaction ID required")

    local tx = Multisig.Transactions[msg.TxId]
    assert(tx and tx.state == "pending", "Invalid or non-pending transaction")
    assert(not tx.approvals[msg.From], "Already approved")
    assert(calc.isGreaterThanOrEqual(Multisig.TokenBalances[tx.token], tx.value), "Insufficient balance")

    -- Record approval
    tx.approvals[msg.From] = true
    tx.approval_count = tx.approval_count + 1

    -- Execute if threshold reached
    if tx.approval_count >= Multisig.Settings.threshold then
        tx.state = "executed"
 
        local notice = Send({
          Target = tx.token,
          Action = "Transfer",
          Recipient = tx.recipient,
          Quantity = tostring(tx.value),
          ["X-Transaction-Id"] = msg.Tags.TxId,
          Data = "Transfer " .. tostring(tx.value) .. " to " .. tx.token
        }).receive()
        if notice.Action == "Debit-Notice" then
            Multisig.TokenBalances[tx.token] = calc.sub(Multisig.TokenBalances[tx.token], notice.Quantity)
            notifyOwners("Transaction-Executed", { 
                tx_id = msg.Tags.TxId,
                token = tx.token,
                amount = tx.value,
                balance = Multisig.TokenBalances[tx.token]
            })
        end
    else
        notifyOwners("Transaction-Approved", {
            tx_id = msg.Tags.TxId,
            approvals = tx.approval_count,
            required = Multisig.Settings.threshold,
            needed = Multisig.Settings.threshold - tx.approval_count
        })
    end
    
    msg.reply({
      Action = "Approve-Reply",
      Status = "success",
      TxId = msg.Tags.TxId,
      State = tx.state,
      Approvals = tostring(tx.approval_count),
      Required = tostring(Multisig.Settings.threshold),
      Data = "Approve-Reply Success"
    })
end)

-- Query Handlers
Handlers.add("Balances", function(msg)
    msg.reply({
        Action = "Balances-Reply",
        Data = Multisig.TokenBalances
    })
end)

Handlers.add("GetTransactions", function(msg)
    msg.reply({
      Action = "GetTransactions-Reply",
      Data = Multisig.Transactions
    })  
end)

Handlers.add("GetOwners", function(msg)
    msg.reply({
      Action = "GetOwners-Reply",
      Data = Multisig.Owners
    })  
end)

Handlers.add("GetSettings", function(msg)
    msg.reply({
      Action = "GetSettings-Reply",
      Data = Multisig.Settings
    })  
end)

return Multisig