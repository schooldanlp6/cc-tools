-- client.lua
peripheral.find("modem", rednet.open)

local serverID = rednet.lookup("ssh", "ssh_server")
if not serverID then
  error("Server not found")
end

while true do
  write("ssh> ")
  local cmd = read()
  if cmd == "exit" then break end

  rednet.send(serverID, cmd, "ssh")
  local _, reply = rednet.receive("ssh", 5)
  print(reply or "No response")
end
