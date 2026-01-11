-- ==== FIND MODEMS ====
local wired, wireless

for _, name in ipairs(peripheral.getNames()) do
  local p = peripheral.wrap(name)
  if peripheral.getType(name) == "modem" then
    if p.isWireless() then wireless = p
    else wired = p end
  end
end

assert(wired, "No wired modem found")
assert(wireless, "No wireless modem found")

wired.open(100)
wireless.open(200)

-- ==== STATE ====
local chambers = {} -- id -> { channel, state }

print("Router online")

local function broadcastState()
  wireless.transmit(200, 200, encrypt({
    type = "state",
    chambers = chambers
  }))
end

-- ==== EVENT LOOP ====
while true do
  local _, _, channel, replyChannel, raw = os.pullEvent("modem_message")
  local msg = decrypt(raw)
  if not msg then goto skip end

  -- CLIENT REGISTRATION
  if msg.type == "register" then
    chambers[msg.id] = {
      channel = replyChannel,
      state = msg.state
    }
    print("Registered stasis", msg.id)
    broadcastState()
  end

  -- CLIENT STATE UPDATE
  if msg.type == "update" and chambers[msg.id] then
    chambers[msg.id].state = msg.state
    broadcastState()
  end

  -- EXTERNAL TOGGLE REQUEST
  if msg.type == "toggle" and chambers[msg.id] then
    wired.transmit(
      chambers[msg.id].channel,
      100,
      encrypt({
        type = "set",
        state = msg.state
      })
    )
  end

  ::skip::
end
