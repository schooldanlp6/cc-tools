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

-- ==== MODEM ====
local modem = peripheral.find("modem")
assert(modem, "No modem found")

-- ==== CONFIG ====
local ID = os.getComputerID()
local CHANNEL = 1000 + ID
modem.open(CHANNEL)

-- Chamber index → redstone side
local SIDES = {
  [1] = "left",
  [2] = "right"
}

-- Local state
local states = {
  [1] = "closed",
  [2] = "closed"
}

-- Force safe startup (both OFF)
for _, side in pairs(SIDES) do
  redstone.setOutput(side, false)
end

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

print("Client online (redstone only)")
print("Chamber 1 → left")
print("Chamber 2 → right")

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
