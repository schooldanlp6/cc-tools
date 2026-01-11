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

local wired, wireless
for _, n in ipairs(peripheral.getNames()) do
  if peripheral.getType(n) == "modem" then
    local m = peripheral.wrap(n)
    if m.isWireless() then wireless = m else wired = m end
  end
end

assert(wired and wireless, "Need wired + wireless modem")

wired.open(100)
wireless.open(200)

local chambers = {}

local function broadcast()
  wireless.transmit(200, 200, encrypt({
    type = "state",
    chambers = chambers
  }))
end

while true do
  local _, _, _, reply, raw = os.pullEvent("modem_message")
  local msg = decrypt(raw)
  if not msg then goto skip end

  if msg.type == "register" then
    chambers[msg.chamberId] = {
      channel = reply,
      state = msg.state
    }
    broadcast()
  end

  if msg.type == "update" and chambers[msg.chamberId] then
    chambers[msg.chamberId].state = msg.state
    broadcast()
  end

  if msg.type == "toggle" and chambers[msg.chamberId] then
    wired.transmit(
      chambers[msg.chamberId].channel,
      100,
      encrypt({
        type = "set",
        chamberId = msg.chamberId,
        state = msg.state
      })
    )
  end

  ::skip::
end
