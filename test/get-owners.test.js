import { test } from 'node:test'
import assert from 'node:assert'

import { aoslocal, LATEST } from '@permaweb/loco'

test("GetOwners", async () => {
  const aos = await aoslocal(LATEST)
  await aos.src("./main.lua")

  await aos.send({
    Action: "Init",
    "Content-Type": "application/json",
    Data: JSON.stringify({ Owners: ["vh-NTHVvlKZqRxc8LyyTNok65yQ55a_PJ1zWLb9G2JI"] }),
    Threshold: "1"
  })
  const result = await aos.send({
    Action: 'GetOwners'
  })
  assert.equal(JSON.parse(result.Messages[0].Data)["vh-NTHVvlKZqRxc8LyyTNok65yQ55a_PJ1zWLb9G2JI"], true)
})