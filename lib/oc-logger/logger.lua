local filesystem = require("filesystem")
local event = require("event")

local classBuilder = require("lib.class-builder.index")
local stringUtilities = require("lib.string-utilities.index")

local logLevels = {debug = 0, info = 1, warning = 2, error = 3}

---@class Logger
---@field timeCorrection number
---@field handlers table<string, LoggerHandler>
local logger = {}

---@return Logger
---@param name string
---@param timeZone number
---@param handlers table<string, LoggerHandler>
function logger:constructor(name, timeZone, handlers)
  self.timeCorrection = timeZone * 3600
  self.name = name
  self.handlers = handlers

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

  return self
end

---Format logger message
---@param format string
---@param logLevel "debug"|"info"|"warning"|"error"
---@param message string
---@return string
---@private
function logger:formatMessage(format, logLevel, message)
  local result = format

  local timeFormat = format:match("{Time:([^}]+)}")

  result = result:gsub("{Message}", message)
  result = result:gsub("{LogLevel}", logLevel)
  result = result:gsub("{Time:[^}]+}", self:getTime(timeFormat))

  return result
end

---Get handler be name
---@param name string
---@return LoggerHandler
function logger:getLogger(name)
  return self.handlers[name]
end

---Log
---@param logLevel "debug"|"info"|"warning"|"error"
---@param ... any
function logger:log(logLevel, ...)
  local message = ""

  local args = {...}

  for key, _ in ipairs(args) do
    local serialized = stringUtilities.objectToString(args[key]):gsub("^['\"]", ""):gsub("['\"]$", "")
    message = message..serialized
  end

  for _, handler in pairs(self.handlers) do
    if logLevels[logLevel] >= logLevels[handler.logLevel] then
      local formatted = self:formatMessage(handler.messageFormat, logLevel, message)
      handler:log(self, logLevel, formatted)
    end
  end
end

---Debug
---@param ... any
function logger:debug(...)
  self:log("debug", ...)
end

---Info
---@param ... any
function logger:info(...)
  self:log("info", ...)
end

---Warning
---@param ... any
function logger:warning(...)
  self:log("warning", ...)
end

---Error
---@param ... any
function logger:error(...)
  self:log("error", ...)
end

---Get real time
---@param format string|nil
---@return string
---@private
function logger:getTime(format)
  format = format or "%d.%m.%Y %H:%M:%S"

  local file = assert(io.open("/tmp/unix.tmp", "w"))

  file:write("")
  file:close()

  local lastModified = tonumber(string.sub(filesystem.lastModified("/tmp/unix.tmp"), 1, -4)) + self.timeCorrection
  local dateTime = tostring(os.date(format, lastModified))
  return dateTime
end

return classBuilder.createClass(logger, logger.constructor, "Logger")