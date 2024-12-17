-- File Logger Handler Lib
-- Author: Navatusein
-- License: MIT
-- Version: 1.4

---@class FileLoggerConfig
---@field logLevel "debug"|"info"|"warning"|"error"
---@field messageFormat string
---@field filePath string

local fileLoggerHandler = {}

---Crate new FileLoggerHandler object from config
---@param config FileLoggerConfig
---@return FileLoggerHandler
function fileLoggerHandler:newFormConfig(config)
  return self:new(config.logLevel, config.messageFormat, config.filePath)
end

---Crate new FileLoggerHandler object
---@param logLevel "debug"|"info"|"warning"|"error"
---@param messageFormat string
---@param filePath string
---@return FileLoggerHandler
function fileLoggerHandler:new(logLevel, messageFormat, filePath)

  ---@class FileLoggerHandler: LoggerHandler
  local obj = {}

  obj.logLevel = logLevel
  obj.messageFormat = messageFormat
  obj.filePath = filePath

  ---Send log to file
  ---@param logger Logger
  ---@param level "debug"|"info"|"warning"|"error"
  ---@param message string
  function obj:log(logger, level, message)
    local file = assert(io.open(self.filePath, "a"))
    file:write(message)
    file:write("\n")
    file:close()
  end

  setmetatable(obj, self)
  self.__index = self
  return obj
end

return fileLoggerHandler