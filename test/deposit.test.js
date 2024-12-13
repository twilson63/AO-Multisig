import { test } from 'node:test'
import assert from 'node:assert'

import { aoslocal } from '@permaweb/loco'

test("Credit-Notice", async () => {
  const aos = await aoslocal()
  await aos.src('./main.lua')

  await aos.send({
    Action: "Init",
    "Content-Type": "application/json",
    Threshold: "1",
    Data: JSON.stringify({ Owners: ["vh-NTHVvlKZqRxc8LyyTNok65yQ55a_PJ1zWLb9G2JI"] })
  })

  await aos.send({
    Action: "Credit-Notice",
    From: "6poPdECzioaWeCSCf1YnZ9lkavQqaCmr3xywOWSEtm8",
    Quantity: "1000"
  })
  const result = await aos.send({
    Action: "Balances"
  })

  assert.deepEqual(JSON.parse(result.Messages[0].Data), { "6poPdECzioaWeCSCf1YnZ9lkavQqaCmr3xywOWSEtm8": "1000" })

})