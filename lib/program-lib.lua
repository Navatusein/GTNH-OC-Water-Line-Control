-- Program Lib
-- Author: Navatusein
-- License: MIT
-- Version: 2.3

local event = require("event")
local thread = require("thread")
local component = require("component")
local keyboard = require("keyboard")
local term = require("term")

---@class ProgramConfig
---@field logger Logger

local function try(callback)
  return function(...)
    local result = table.pack(xpcall(callback, debug.traceback, ...))
    if not result[1] then
      event.push("exit", result[2])
    end
    return table.unpack(result, 2)
  end
end

local program = {}

---Crate new List object from config
---@param config ProgramConfig
---@return Program
function program:newFormConfig(config)
  return self:new(config.logger)
end

---Crate new Program object
---@param logger Logger
---@return Program
function program:new(logger)

  ---@class Program
  local obj = {}

  obj.logger = logger

  obj.gpu = component.gpu

  obj.debug = false
  obj.coroutines = {}
  obj.keyHandlers = {}

  obj.defaultLoopInterval = 1/20
  obj.defaultWidth = 0
  obj.defaultHeight = 0
  obj.defaultForeground = 0
  obj.defaultBackground = 0

  obj.logo = nil
  obj.init = nil

  ---Register logo
  ---@param logo string[]
  function obj:registerLogo(logo)
    self.logo = logo
  end

  ---Register init function
  ---@param callback function
  function obj:registerInit(callback)
    self.init = callback
  end

  ---Register timer
  ---@param callback function
  ---@param times? number
  ---@param interval? number
  function obj:registerTimer(callback, times, interval)
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
  function obj:registerThread(callback)
    local coroutineDescriptor = {
      type = "thread",
      callback = callback,
    }

    table.insert(self.coroutines, coroutineDescriptor)
  end

  ---Register button handler
  ---@param keyCode number
  ---@param callback function
  function obj:registerKeyHandler(keyCode, callback)
    if self.keyHandlers[keyCode] ~= nil then
      error("This Key Is Busy")
    end

    self.keyHandlers[keyCode] = try(callback)
  end

 ---Remove button handler
  ---@param keyCode number
  function obj:removeKeyHandler(keyCode)
    self.keyHandlers[keyCode] = nil
  end

  ---Program exit
  ---@param exception any
  function obj:exit(exception)
    for _, coroutine in pairs(self.coroutines) do
      if type(coroutine) == "table" and coroutine.kill then
        coroutine:kill()
      else
        event.cancel(coroutine)
      end
    end

    self.gpu.freeAllBuffers()

    self.gpu.setResolution(self.defaultWidth, self.defaultHeight)

    self.gpu.setForeground(self.defaultForeground)
    self.gpu.setBackground(self.defaultBackground)

    self.gpu.fill(1, 1, self.defaultWidth, self.defaultHeight, " ")

    term.setCursor(1, 1)

    if exception then
      io.stderr:write(exception)
      logger:error(exception)
      os.exit(1)
    else
      os.exit(0)
    end
  end

  ---Program start
  function obj:start()
    self.defaultWidth, self.defaultHeight = self.gpu.getResolution()

    self.defaultForeground = self.gpu.getForeground()
    self.defaultBackground = self.gpu.getBackground()

    if self.logo then 
      local width = #self.logo[1] + 2
      local height = #self.logo + 2

      self.gpu.setResolution(width, height)
      self.gpu.fill(1, 1, width, height, " ")

      term.setCursor(1, 2)

      for _, line in pairs(self.logo) do
        print(" "..line)
      end

      os.sleep(1)

      self.gpu.fill(1, 1, width, height, " ")
      self.gpu.setResolution(self.defaultWidth, self.defaultHeight)
    end

    logger:init()

    if self.init then
      try(self.init)()
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
        logger:debug("Pressed ["..string.char(char).."]: "..keyCode.."\n")
      end

      if self.keyHandlers[keyCode] then

        if self.debug == true then 
          logger:debug("Action ["..string.char(char).."]: "..keyCode.."\n")
        end

        self.keyHandlers[keyCode]()
      end
    end)))

    local _, exception = event.pull("exit")
    self:exit(exception)
  end

  setmetatable(obj, self)
  self.__index = self
  return obj
end

return program