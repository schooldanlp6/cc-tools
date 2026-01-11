-- ===== CONFIG =====
local MONITOR_SIDE = "top"     -- monitor is on top
local UPDATE_INTERVAL = 2      -- seconds
local EVENTS_FILE = "events.json"

-- ===== SETUP =====
local monitor = peripheral.wrap(MONITOR_SIDE)
if not monitor then
  error("No monitor found on side: " .. MONITOR_SIDE)
end

monitor.setTextScale(0.5)
monitor.setBackgroundColor(colors.black)
monitor.setTextColor(colors.white)
monitor.clear()

-- ===== UTIL =====
local function loadEvents()
  if not fs.exists(EVENTS_FILE) then
    return {}
  end

  local f = fs.open(EVENTS_FILE, "r")
  local data = textutils.unserializeJSON(f.readAll())
  f.close()

  return data.events or {}
end

local function saveEvents(events)
  local f = fs.open(EVENTS_FILE, "w")
  f.write(textutils.serializeJSON({ events = events }, true))
  f.close()
end

local function getTimeString()
  local t = os.time()
  local hours = math.floor(t)
  local minutes = math.floor((t - hours) * 60)
  return string.format("%02d:%02d", hours, minutes)
end

-- ===== RENDER =====
local function render(events)
  monitor.clear()
  monitor.setCursorPos(1, 1)

  -- Header
  monitor.setTextColor(colors.cyan)
  monitor.write(" Smart Dashboard ")
  monitor.setTextColor(colors.white)

  -- Time
  monitor.setCursorPos(1, 3)
  monitor.write("Time: ")
  monitor.setTextColor(colors.yellow)
  monitor.write(getTimeString())
  monitor.setTextColor(colors.white)

  -- Events
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

-- ===== EVENT INPUT (COMPUTER) =====
local function inputLoop()
  while true do
    term.setTextColor(colors.green)
    write("\nAdd event (or blank to skip): ")
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

-- ===== DASHBOARD LOOP =====
local function dashboardLoop()
  while true do
    local events = loadEvents()
    render(events)
    sleep(UPDATE_INTERVAL)
  end
end

-- ===== RUN =====
parallel.waitForAny(dashboardLoop, inputLoop)
