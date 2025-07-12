-- Logger Lib
-- Author: Navatusein
-- License: MIT
-- Version: 2.4

local filesystem = require("filesystem")
local event = require("event")

---@class LoggerConfig
---@field name string
---@field timeZone number
---@field handlers LoggerHandler[]

---@class LoggerHandler
---@field log fun(self, logger:Logger, level, message)
---@field logLevel "debug"|"info"|"warning"|"error"
---@field messageFormat string

local logLevels = {debug = 0, info = 1, warning = 2, error = 3}

local logger = {}

---Crate new Logger object from config
---@param config LoggerConfig
---@return Logger
function logger:newFormConfig(config)
  return self:new(config.name, config.timeZone, config.handlers)
end

---Crate new Logger object
---@param name string
---@param timeZone number
---@param handlers LoggerHandler[]
---@return Logger
function logger:new(name, timeZone, handlers)

  ---@class Logger
  local obj = {}

  obj.name = name
  obj.timeCorrection = timeZone * 3600
  obj.handlers = handlers

  obj.nestingLimit = 5
  obj.enable = false

  function obj:init()
    event.listen("log_debug", function (_, ...)
      self:debug(...)
    end)

    event.listen("log_info", function (_, ...)
      self:info(...)
    end)

    event.listen("log_warning", function (_, ...)
      self:warning(...)
    end)

    event.listen("log_error", function (_, ...)
      self:error(...)
    end)

  end

  ---Get real time
  ---@param format string|nil
  ---@return string
  ---@private
  function obj:getTime(format)
    format = format or "%d.%m.%Y %H:%M:%S"

    local file = assert(io.open("/tmp/unix.tmp", "w"))

    file:write("")
    file:close()

    local lastModified = tonumber(string.sub(filesystem.lastModified("/tmp/unix.tmp"), 1, -4)) + self.timeCorrection
    local dateTime = tostring(os.date(format, lastModified))
    return dateTime
  end

  ---Convert object ot string
  ---@param level number
  ---@param object table|boolean|number|string
  ---@return string
  ---@private
  function obj:objectToString(level, object)
    level = level or 0
    local message = ""
    if object == nil then
        message = message .. "nil"
    elseif type(object) == "boolean" or type(object) == "number" then
        message = message..tostring(object) 
    elseif type(object) == "string" then
        message = message..object
    elseif type(object) == "function" then
        message = message.."\"__function\""
    elseif type(object) == "table" then
      if level <= self.nestingLimit then
        message = message.."\n"..string.rep(" ", level).."{\n"
        for key, nextObject in pairs(object) do
            message = message..string.rep(" ", level + 1).."\""..key.."\""..":"..self:objectToString(level + 1, nextObject)..",\n";
        end
        message = message..string.rep(" ", level).."}"
      else
        message = message.."\"".."__table".."\""
      end
    end

    return message
  end

  ---Convert object ot string
  ---@param object table|boolean|number|string
  ---@param ... any
  ---@return string
  ---@private
  function obj:objectToStringRecursion(object, ...)
    local args = {...}
    if #args > 0 then
        return self:objectToString(0, object) .. self:objectToStringRecursion(...)
    else
        return self:objectToString(0, object)
    end
  end

  ---Format logger message
  ---@param format string
  ---@param logLevel "debug"|"info"|"warning"|"error"
  ---@param message string
  ---@return string
  ---@private
  function obj:formatMessage(format, logLevel, message)
    local result = format

    local timeFormat = format:match("{Time:([^}]+)}")

    result = result:gsub("{Message}", message)
    result = result:gsub("{LogLevel}", logLevel)
    result = result:gsub("{Time:[^}]+}", self:getTime(timeFormat))

    return result
  end

  function obj:getLogger(name)
    
  end

  ---Log
  ---@param logLevel "debug"|"info"|"warning"|"error"
  ---@param ... any
  function obj:log(logLevel, ...)
    local message = self:objectToStringRecursion(...)

    for _, handler in pairs(self.handlers) do
      if logLevels[logLevel] >= logLevels[handler.logLevel] then
        local formatted = self:formatMessage(handler.messageFormat, logLevel, message)
        handler:log(self, logLevel, formatted)
      end
    end
  end

  ---Debug
  ---@param ... any
  function obj:debug(...)
    self:log("debug", ...)
  end

  ---Info
  ---@param ... any
  function obj:info(...)
    self:log("info", ...)
  end

  ---Warning
  ---@param ... any
  function obj:warning(...)
    self:log("warning", ...)
  end

  ---Error
  ---@param ... any
  function obj:error(...)
    self:log("error", ...)
  end

  setmetatable(obj, self)
  self.__index = self
  return obj
end

return logger