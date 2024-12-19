import { test } from 'node:test'
import assert from 'node:assert'

import { aoslocal } from '@permaweb/loco'

test("Approve", async () => {
  const aos = await aoslocal()
  await aos.src('./main.lua')

  await aos.send({
    Action: "Init",
    "Content-Type": "application/json",
    Threshold: "2",
    Data: JSON.stringify({ Owners: ["vh-NTHVvlKZqRxc8LyyTNok65yQ55a_PJ1zWLb9G2JI", "JITBuxQjCLTYTKaEO663oShR5KD09hxO-Zpo27BF4gM"] })
  })

  await aos.send({
    Action: "Credit-Notice",
    From: "6poPdECzioaWeCSCf1YnZ9lkavQqaCmr3xywOWSEtm8",
    Quantity: "1000"
  })

  const proposeResult = await aos.send({
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
  const txId = JSON.parse(proposeResult.Messages[0].Data)["tx_id"]
  const result = await aos.send({
    Action: "Approve",
    Owner: "JITBuxQjCLTYTKaEO663oShR5KD09hxO-Zpo27BF4gM",
    TxId: txId
  })

  if (result.Error) {
    console.log(result.Error)
  }

  // console.log(result.Messages[0])

  // Mock Debit-Notice from Token Transfer
  const transfer = result.Messages[0]
  const noticeResult = await aos.send({
    Action: "Debit-Notice",
    "X-Reference": transfer.Tags.find(t => t.name === "Reference").value,
    From: transfer.Target,
    Quantity: transfer.Tags.find(t => t.name === "Quantity").value
  })
  // handle Debit-Notice
  //console.log(noticeResult)
  assert.equal(JSON.parse(noticeResult.Messages[0].Data).data?.Quantity, "500")

})

