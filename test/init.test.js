import { test } from 'node:test'
import assert from 'node:assert'

import { aoslocal, LATEST } from '@permaweb/loco'

test("Init - should only run once", async () => {
  const aos = await aoslocal(LATEST)
  await aos.src("./main.lua")

  const result = await aos.send({
    Action: "Init",
    "Content-Type": "application/json",
    Data: JSON.stringify({ Owners: ["vh-NTHVvlKZqRxc8LyyTNok65yQ55a_PJ1zWLb9G2JI"] }),
    Threshold: "1"
  })
  assert.deepEqual(JSON.parse(result.Messages[0].Data), { "owners": { "vh-NTHVvlKZqRxc8LyyTNok65yQ55a_PJ1zWLb9G2JI": true }, "threshold": 1, "owner_count": 1 })

  const initResult2 = await aos.send({
    Action: "Init",
    Owners: JSON.stringify(["vh-NTHVvlKZqRxc8LyyTNok65yQ55a_PJ1zWLb9G2JI"]),
    Threshold: "1"
  })
  //assert.equal(initResult2.Messages[0].Data, '{"owners":{"vh-NTHVvlKZqRxc8LyyTNok65yQ55a_PJ1zWLb9G2JI":true},"threshold":1,"owner_count":1}')
  assert.equal(initResult2.Output.data, '\x1B[90mNew Message From \x1B[32mOWN...NER\x1B[90m: \x1B[90mAction = \x1B[34mInit\x1B[0m')
})

test("Init - should require Owners Data", async () => {
  const aos = await aoslocal(LATEST)
  await aos.src("./main.lua")

  const result = await aos.send({
    Action: "Init",
    "Content-Type": "application/json",
    Data: JSON.stringify({}),
    Threshold: "1"
  })
  //console.log(result.Error)
  assert(result.Error.includes("Missing required parameters"))

})

test("Init - should require Threshold Data", async () => {
  const aos = await aoslocal(LATEST)
  await aos.src("./main.lua")

  const result = await aos.send({
    Action: "Init",
    "Content-Type": "application/json",
    Data: JSON.stringify({ Owners: [] })
  })
  //console.log(result.Error)
  assert(result.Error.includes("Missing required parameters"))

})