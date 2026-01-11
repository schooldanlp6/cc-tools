-- server.lua
peripheral.find("modem", rednet.open)
local host = "ssh_server"

rednet.host("ssh", host)
print("SSH server online as:", host)

while true do
  local id, msg = rednet.receive("ssh")
  if type(msg) == "string" then
    print("CMD from", id, ":", msg)

    local ok, output = pcall(function()
      local handle = io.popen(msg .. " 2>&1")
      local result = handle:read("*a")
      handle:close()
      return result
    end)

    rednet.send(id, ok and output or "ERROR", "ssh")
  end
end
