-- Scroll List Logger Handler Lib
-- Author: Navatusein
-- License: MIT
-- Version: 1.1

local listLib = require("lib.list-lib")

---@class ScrollListLoggerConfig
---@field logLevel "debug"|"info"|"warning"|"error"
---@field logsListSize number

local scrollListLoggerHandler = {}

---Crate new ScrollListLoggerHandler object from config
---@param config ScrollListLoggerConfig
---@return ScrollListLoggerHandler
function scrollListLoggerHandler:newFormConfig(config)
  return self:new(config.logLevel, config.logsListSize)
end

---Crate new ScrollListLoggerHandler object
---@param logLevel "debug"|"info"|"warning"|"error"
---@param logsListSize number
---@return ScrollListLoggerHandler
function scrollListLoggerHandler:new(logLevel, logsListSize)

  ---@class ScrollListLoggerHandler: LoggerHandler
  local obj = {}

  obj.logLevel = logLevel
  obj.messageFormat = "{Message}"
  obj.logs = listLib:new(logsListSize)

  ---Send log to list
  ---@param logger Logger
  ---@param level "debug"|"info"|"warning"|"error"
  ---@param message string
  function obj:log(logger, level, message)
    if level == "debug" then
      self.logs:pushFront("&lightBlue;"..message.."&white;")
    elseif level == "info" then
      self.logs:pushFront(message)
    elseif level == "warning" then
      self.logs:pushFront("&yellow;"..message.."&white;")
    elseif level == "error" then
      self.logs:pushFront("&red;[Error] "..message.."&white;")
    end
  end

  function obj:clearList()
    self.logs:clear()
  end

  setmetatable(obj, self)
  self.__index = self
  return obj
end

return scrollListLoggerHandler