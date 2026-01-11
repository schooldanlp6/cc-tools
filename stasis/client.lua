local KEY = "ABCMECH"
local modem = peripheral.find("modem")
modem.open(2)

-- crypto helpers here

local chambers = {}
local selected = 1

local function draw()
  term.clear()
  term.setCursorPos(1,1)
  print("Stasis Chambers")
  print("----------------")
  local i = 1
  for id, c in pairs(chambers) do
    local prefix = (i == selected) and "> " or "  "
    print(prefix .. "Stasis " .. id .. ": " .. c.state)
    i = i + 1
  end
end

while true do
  local e = { os.pullEvent() }

  if e[1] == "modem_message" then
    local msg = decrypt(e[5])
    if msg and msg.type == "state" then
      chambers = msg.chambers
      draw()
    end
  end

  if e[1] == "key" and e[2] == keys.enter then
    local i = 1
    for id, c in pairs(chambers) do
      if i == selected then
        modem.transmit(2, 2, encrypt({
          type = "toggle",
          id = id,
          state = (c.state == "open") and "closed" or "open"
        }))
        break
      end
      i = i + 1
    end
  end

  if e[1] == "key" and e[2] == keys.down then selected = selected + 1 end
  if e[1] == "key" and e[2] == keys.up then selected = math.max(1, selected - 1) end
end
