local KEY = "ABCMECH"
local chambers = {} -- id -> {computerId, state}

local wired = peripheral.find("modem", function(_, m) return not m.isWireless() end)
local wireless = peripheral.find("modem", function(_, m) return m.isWireless() end)

wired.open(1)
wireless.open(2)

-- crypto helpers here (same as above)

local function broadcastState()
  local msg = { type = "state", chambers = chambers }
  wireless.transmit(2, 2, encrypt(msg))
end

print("Router online")

while true do
  local _, side, ch, _, data = os.pullEvent("modem_message")
  local msg = decrypt(data)
  if not msg then goto continue end

  -- Client registers chamber
  if msg.type == "register" then
    chambers[msg.id] = {
      computerId = msg.computerId,
      state = msg.state
    }
    print("Registered stasis", msg.id)
    broadcastState()
  end

  -- Client state update
  if msg.type == "update" then
    if chambers[msg.id] then
      chambers[msg.id].state = msg.state
      broadcastState()
    end
  end

  -- External toggle request
  if msg.type == "toggle" then
    local target = chambers[msg.id]
    if target then
      wired.transmit(1, target.computerId, encrypt({
        type = "set",
        state = msg.state
      }))
    end
  end

  ::continue::
end
