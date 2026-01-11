-- ================= CONFIG =================
local MONITOR_SIDE = "top"      -- set to nil to auto-detect
local UPDATE_INTERVAL = 2
local EVENTS_FILE = "events.json"

-- ================= MONITOR =================
local monitor
if MONITOR_SIDE then
  monitor = peripheral.wrap(MONITOR_SIDE)
else
  monitor = peripheral.find("monitor")
end

if not monitor then
  error("No monitor found")
end

monitor.setTextScale(0.5)
monitor.setBackgroundColor(colors.black)
monitor.setTextColor(colors.white)
monitor.clear()

-- ================= JSON =================
local function loadEvents()
  if not fs.exists(EVENTS_FILE) then
    return {}
  end

  local f = fs.open(EVENTS_FILE, "r")
  local raw = f.readAll()
  f.close()

  if raw == "" then
    return {}
  end

  local ok, data = pcall(textutils.unserializeJSON, raw)
  if not ok or type(data) ~= "table" then
    return {}
  end

  -- Accept both { events = [...] } and [...]
  if type(data.events) == "table" then
    return data.events
  end

  if type(data[1]) == "string" then
    return data
  end

  return {}
end

local function saveEvents(events)
  local f = fs.open(EVENTS_FILE, "w")
  f.write(
    textutils.serializeJSON(
      { events = events },
      true
    )
  )
  f.close()
end

-- ================= TIME =================
local function getTimeString()
  local t = os.time()
  local h = math.floor(t)
  local m = math.floor((t % 1) * 60)
  return string.format("%02d:%02d", h, m)
end

-- ================= RENDER =================
local function render(events)
  monitor.clear()

  monitor.setCursorPos(1, 1)
  monitor.setTextColor(colors.cyan)
  monitor.write(" Smart Dashboard ")
  monitor.setTextColor(colors.white)

  monitor.setCursorPos(1, 3)
  monitor.write("Time: ")
  monitor.setTextColor(colors.yellow)
  monitor.write(getTimeString())
  monitor.setTextColor(colors.white)

  monitor.setCursorPos(1, 5)
  monitor.write("Events:")

  local y = 6
  if #events == 0 then
    monitor.setCursorPos(2, y)
    monitor.setTextColor(colors.gray)
    monitor.write("- none -")
    monitor.setTextColor(colors.white)
  else
    for i, ev in ipairs(events) do
      monitor.setCursorPos(2, y)
      monitor.write("- " .. ev)
      y = y + 1
    end
  end
end

-- ================= INPUT =================
local function inputLoop()
  while true do
    term.setTextColor(colors.green)
    write("\nAdd event (blank = skip): ")
    term.setTextColor(colors.white)

    local input = read()
    if input ~= "" then
      local events = loadEvents()
      table.insert(events, input)
      saveEvents(events)
      print("Event added.")
    end
  end
end

-- ================= DASHBOARD =================
local function dashboardLoop()
  while true do
    local events = loadEvents()
    render(events)
    sleep(UPDATE_INTERVAL)
  end
end

-- ================= RUN =================
parallel.waitForAny(dashboardLoop, inputLoop)
