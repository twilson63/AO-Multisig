import { test } from 'node:test'
import assert from 'node:assert'

import { aoslocal, LATEST } from '@permaweb/loco'

test("GetTransactions", async () => {
  const aos = await aoslocal(LATEST)
  await aos.src("./main.lua")

  await aos.send({
    Action: "Init",
    "Content-Type": "application/json",
    Data: JSON.stringify({ Owners: ["vh-NTHVvlKZqRxc8LyyTNok65yQ55a_PJ1zWLb9G2JI"] }),
    Threshold: "1"
  })

  await aos.send({
    Action: "Credit-Notice",
    From: "6poPdECzioaWeCSCf1YnZ9lkavQqaCmr3xywOWSEtm8",
    Quantity: "1000"
  })

  const proposalResult = await aos.send({
    Action: "Propose",
    Owner: "vh-NTHVvlKZqRxc8LyyTNok65yQ55a_PJ1zWLb9G2JI",
    "Content-Type": "application/json",
    Data: JSON.stringify({
      Target: "6poPdECzioaWeCSCf1YnZ9lkavQqaCmr3xywOWSEtm8",
      Action: "Transfer",
      Quantity: "500",
      Recipient: "x7nvOYgVrPePV1siG3b3i7J0IWAmdiqBx3d_AxZlCqA"
    })
  })

  // Mock Debit-Notice from Token Transfer
  const transfer = proposalResult.Messages[0]
  await aos.send({
    Action: "Debit-Notice",
    "X-Reference": transfer.Tags.find(t => t.name === "Reference").value,
    From: transfer.Target,
    Quantity: transfer.Tags.find(t => t.name === "Quantity").value
  })


  const result = await aos.send({
    Action: 'GetTransactions'
  })
  // console.log()
  // assert(true)
  assert.equal(JSON.parse(result.Messages[0].Data)["MESSAGE_ID"].state, "executed")
})