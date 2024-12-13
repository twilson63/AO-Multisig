# AO Multisig 

A AO Program that allows for multiple parties to deposit tokens into a process in which the group can propose and approve transfers of those tokens.

## Handlers

### Init

Init is a one time handler that takes a list of owners for the multisig process, once these addresses are set, they can not be changed. Also the init takes a `Threshold` tag with the number of approvals to execute the transfer proposal.

Example:

```lua
Send({
  Target = MyMultisig, 
  Action = "Init", 
  Data = {Owners = {"JITBuxQjCLTYTKaEO663oShR5KD09hxO-Zpo27BF4gM", "vh-NTHVvlKZqRxc8LyyTNok65yQ55a_PJ1zWLb9G2JI"}}, Threshold = "2" 
})
```

### Credit-Notice

As one of the members of the Multisig you can transfer tokens quantities to your Multisig process, just doing a normal transfer.

```lua
JackCoin = "6poPdECzioaWeCSCf1YnZ9lkavQqaCmr3xywOWSEtm8"
Send({
  Target = JackCoin, 
  Action = "Transfer",
  Quantity = "1000000000",
  Recipient = MyMultisig
})
```

### Balances

Checking the balances of your Multisig by sending a message or dryrun

Example:

```lua
Send({
  Target = MyMultisig,
  Action = "Balances"
})
```

### Proposal

Propose a transfer for the Multisig, a proposal requires a number of Owner approvals set by the threshold, for example, if you have 5 Owners, maybe you want a threshold of 3, which means any 3 owners can approve a transfer.

Example:

```lua
JackCoin = "6poPdECzioaWeCSCf1YnZ9lkavQqaCmr3xywOWSEtm8"
Send({
  Target = MyMultisig,
  Action = "Propose",
  Token = JackCoin,
  Quantity = "500", -- remember these need to be base units aka winstons or armstrongs
  Recipient = "x7nvOYgVrPePV1siG3b3i7J0IWAmdiqBx3d_AxZlCqA"
})
```

### Approval

Once a proposal is made all Owners will get notified with the proposal tx, using this tx, you can approve the proposal.

Example:

```lua
Send({
  Action = "Approve",
  Owner = "JITBuxQjCLTYTKaEO663oShR5KD09hxO-Zpo27BF4gM",
  TxId = txId
})
```

When the approval threshold is met, the transfer will be executed.




