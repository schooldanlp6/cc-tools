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
-- ==== PERIPHERALS ====
local modem = peripheral.find("modem")
assert(modem, "No modem")

-- Find BOTH chambers
local chambers = {}
for _, n in ipairs(peripheral.getNames()) do
  if peripheral.getType(n):lower():find("stasis") then
    table.insert(chambers, peripheral.wrap(n))
  end
end

assert(#chambers == 2, "Exactly 2 stasis chambers required")

-- ==== CONFIG ====
local ID = os.getComputerID()
local CHANNEL = 1000 + ID
modem.open(CHANNEL)

local states = { "closed", "closed" }

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

print("Client online with 2 chambers")

-- ==== LOOP ====
while true do
  local _, _, _, _, raw = os.pullEvent("modem_message")
  local msg = decrypt(raw)

  if msg and msg.type == "set" then
    local idx = tonumber(msg.chamberId:match(":(%d+)$"))
    if idx and chambers[idx] then
      if msg.state == "open" then
        chambers[idx].open()
        states[idx] = "open"
      else
        chambers[idx].close()
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
