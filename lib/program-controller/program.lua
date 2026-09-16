local event = require("event")
local thread = require("thread")
local component = require("component")
local keyboard = require("keyboard")
local term = require("term")

local classBuilder = require("lib.class-builder.index")
local programUpdater = require("lib.program-controller.program-updater")

---Try Catch
---@param callback function
---@return function
local function try(callback)
  return function(...)
    local result = table.pack(xpcall(callback, debug.traceback, ...))
    if not result[1] then
      event.push("exit", result[2])
    end
    return table.unpack(result, 2)
  end
end

---@class Program
---@field enableAutoUpdate? boolean
---@field version? ProgramVersion
---@field repository? string
---@field archiveName? string
---@field debug boolean
---@field coroutines table
---@field keyHandlers table<number, fun()>
---@field defaultLoopInterval number
---@field defaultWidth number
---@field defaultHeight number
---@field defaultForeground number
---@field defaultBackground number
---@field logo? string[]
---@field onInit? fun()
---@field onExit? fun()
---@field updater ProgramUpdater
local program = {}

---Constructor
---@param enableAutoUpdate? boolean
---@param version? ProgramVersion
---@param repository? string
---@param archiveName? string
---@return Program
function program:constructor(enableAutoUpdate, version, repository, archiveName)
  self.enableAutoUpdate = enableAutoUpdate
  self.version = version
  self.repository = repository
  self.archiveName = archiveName

  self.debug = false
  self.coroutines = {}
  self.keyHandlers = {}

  self.defaultLoopInterval = 1/20
  self.defaultWidth = 0
  self.defaultHeight = 0
  self.defaultForeground = 0
  self.defaultBackground = 0

  self.logo = nil

  self.onInit = nil
  self.onExit = nil

  self.updater = programUpdater:new(self)

  return self
end

---Register logo
---@param logo string[]
function program:registerLogo(logo)
  self.logo = logo
end

---Register onInit function
---@param callback function
function program:registerOnInit(callback)
  self.onInit = callback
end

---Register onExit function
---@param callback function
function program:registerOnExit(callback)
  self.onExit = callback
end

---Register timer
---@param callback function
---@param times? number
---@param interval? number
function program:registerTimer(callback, times, interval)
  interval = interval or self.defaultLoopInterval

  local coroutineDescriptor = {
    type = "timer",
    interval = interval,
    callback = callback,
    times = times
  }

  table.insert(self.coroutines, coroutineDescriptor)
end

---Register thread
---@param callback function
function program:registerThread(callback)
  local coroutineDescriptor = {
    type = "thread",
    callback = callback,
  }

  table.insert(self.coroutines, coroutineDescriptor)
end

---Register button handler
---@param keyCode number
---@param callback function
function program:registerKeyHandler(keyCode, callback)
  if self.keyHandlers[keyCode] ~= nil then
    error("[Program] "..keyCode.." key is busy")
  end

  self.keyHandlers[keyCode] = try(callback)
end

---Remove button handler
---@param keyCode number
function program:removeKeyHandler(keyCode)
  self.keyHandlers[keyCode] = nil
end

---Program start
function program:start()
  self.defaultWidth, self.defaultHeight = component.gpu.getResolution()
  self.defaultForeground = component.gpu.getForeground()
  self.defaultBackground = component.gpu.getBackground()

  if self.logo then
    self:displayLogo()
  end

  if self.enableAutoUpdate then
    self.updater:autoUpdate()
    self:registerTimer(self.updater:checkUpdateTimer())
  end

  if self.onInit then
    try(self.onInit)()
  end

  for i = 1, #self.coroutines do
    local coroutine = self.coroutines[i]

    if coroutine.type == "timer" then
      self.coroutines[i] = event.timer(coroutine.interval, try(coroutine.callback), coroutine.times)
    elseif coroutine.type == "thread" then
      self.coroutines[i] = thread.create(try(coroutine.callback))
      self.coroutines[i]:detach()
    end
  end

  self:registerKeyHandler(keyboard.keys.q, function()
    event.push("exit")
  end)

  table.insert(self.coroutines, event.listen("key_up", try(function (_, address, char, keyCode)
    if self.debug == true then 
      event.push("log_debug", "Pressed ["..string.char(char).."]: "..keyCode.."\n")
    end

    if self.keyHandlers[keyCode] then
      if self.debug == true then
        event.push("log_debug", "Action ["..string.char(char).."]: "..keyCode.."\n");
      end

      self.keyHandlers[keyCode]()
    end
  end)))

  local _, exception = event.pull("exit")
  self:exit(exception)
end

---Program exit
---@param exception any
function program:exit(exception)
  for _, coroutine in pairs(self.coroutines) do
    if type(coroutine) == "table" and coroutine.kill then
      coroutine:kill()
    elseif type(coroutine) == "number" then
      event.cancel(coroutine)
    end
  end

  component.gpu.freeAllBuffers()
  component.gpu.setResolution(self.defaultWidth, self.defaultHeight)
  component.gpu.setForeground(self.defaultForeground)
  component.gpu.setBackground(self.defaultBackground)

  term.clear()

  if self.onExit then
    try(self.onExit)()
  end

  if exception then
    io.stderr:write(exception)
    event.push("log_error", exception);
    os.exit(1)
  else
    os.exit(0)
  end
end

---Display logo
---@private
function program:displayLogo()
  local width = #self.logo[1] + 2
  local height = #self.logo + 2

  component.gpu.setResolution(width, height)
  component.gpu.fill(1, 1, width, height, " ")

  term.setCursor(1, 2)

  for _, line in pairs(self.logo) do
    term.write(" "..line.."\n")
  end

  os.sleep(1)

  component.gpu.fill(1, 1, width, height, " ")
  component.gpu.setResolution(self.defaultWidth, self.defaultHeight)
end

return classBuilder.createClass(program, program.constructor, "Program")