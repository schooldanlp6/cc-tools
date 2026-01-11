local KEY = "ABCMECH"

local function xorCrypt(data, key)
  local out = {}
  for i = 1, #data do
    local k = key:byte((i - 1) % #key + 1)
    out[i] = string.char(bit.bxor(data:byte(i), k))
  end
  return table.concat(out)
end

local function encrypt(tbl)
  return xorCrypt(textutils.serialize(tbl), KEY)
end

local function decrypt(str)
  local ok, data = pcall(textutils.unserialize, xorCrypt(str, KEY))
  if ok then return data end
end

-- ==== CONFIG ====
local modem = peripheral.find("modem")
assert(modem, "No modem found")

local ID = os.getComputerID()
local CHANNEL = 1000 + ID
modem.open(CHANNEL)

-- Chamber mapping
local SIDES = {
  [1] = "left",
  [2] = "right"
}

local states = {
  [1] = "closed",
  [2] = "closed"
}

-- Ensure chambers start closed
redstone.setOutput("left", false)
redstone.setOutput("right", false)

local function send(msg)
  modem.transmit(100, CHANNEL, encrypt(msg))
end

-- ==== REGISTER BOTH CHAMBERS ====
for i = 1, 2 do
  send({
    type = "register",
    chamberId = ID .. ":" .. i,
    state = states[i]
  })
end

print("Client online (redstone mode)")
print("Left = chamber 1")
print("Right = chamber 2")

-- ==== EVENT LOOP ====
while true do
  local _, _, _, _, raw = os.pullEvent("modem_message")
  local msg = decrypt(raw)

  if msg and msg.type == "set" then
    local idx = tonumber(msg.chamberId:match(":(%d+)$"))
    local side = SIDES[idx]

    if side then
      if msg.state == "open" then
        redstone.setOutput(side, true)
        states[idx] = "open"
      else
        redstone.setOutput(side, false)
        states[idx] = "closed"
      end

      send({
        type = "update",
        chamberId = msg.chamberId,
        state = states[idx]
      })
    end
  end
end
