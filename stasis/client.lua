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

-- ANY MODEM
local modem = peripheral.find("modem")
assert(modem, "No modem found")

modem.open(200)

local chambers = {}
local order = {}
local selected = 1

local function rebuild()
  order = {}
  for id in pairs(chambers) do table.insert(order, id) end
  table.sort(order)
end

local function draw()
  term.clear()
  term.setCursorPos(1,1)
  print("Stasis Chambers")
  print("----------------")
  for i, id in ipairs(order) do
    local p = (i == selected) and "> " or "  "
    print(p .. id .. ": " .. chambers[id].state)
  end
end

while true do
  local e, a, b, c, raw = os.pullEvent()

  if e == "modem_message" then
    local msg = decrypt(raw)
    if msg and msg.type == "state" then
      chambers = msg.chambers
      rebuild()
      draw()
    end
  end

  if e == "key" then
    if a == keys.up then
      selected = math.max(1, selected - 1)
    elseif a == keys.down then
      selected = math.min(#order, selected + 1)
    elseif a == keys.enter and order[selected] then
      local id = order[selected]
      local new =
        (chambers[id].state == "open") and "closed" or "open"

      modem.transmit(200, 200, encrypt({
        type = "toggle",
        chamberId = id,
        state = new
      }))
    end
    draw()
  end
end
