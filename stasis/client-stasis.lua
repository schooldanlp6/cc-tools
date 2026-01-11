local KEY = "ABCMECH"
local modem = peripheral.find("modem")
local chamber = peripheral.find("stasis_chamber")

modem.open(1)

local ID = os.getComputerID()
local state = "closed"

-- crypto helpers here

local function send(msg)
  modem.transmit(1, 1, encrypt(msg))
end

send({
  type = "register",
  id = ID,
  computerId = ID,
  state = state
})

print("Client online")

while true do
  local _, _, _, _, data = os.pullEvent("modem_message")
  local msg = decrypt(data)
  if not msg then goto continue end

  if msg.type == "set" then
    if msg.state == "open" then
      chamber.open()
      state = "open"
    else
      chamber.close()
      state = "closed"
    end

    send({
      type = "update",
      id = ID,
      state = state
    })
  end

  ::continue::
end
