local classBuilder = require("lib.class-builder.index")

---@class FileLoggerHandler: LoggerHandler
---@field filePath string
local fileLoggerHandler = {}

---Constructor
---@param logLevel "debug"|"info"|"warning"|"error"
---@param messageFormat string
---@param filePath string
---@return FileLoggerHandler
function fileLoggerHandler:constructor(logLevel, messageFormat, filePath)
  self.logLevel = logLevel
  self.messageFormat = messageFormat
  self.filePath = filePath

  return self
end

---Log
---@param logger Logger
---@param level "debug"|"info"|"warning"|"error"
---@param message string
function fileLoggerHandler:log(logger, level, message)
  local file = assert(io.open(self.filePath, "a"))
  file:write(message)
  file:write("\n")
  file:close()
end

return classBuilder.createClass(fileLoggerHandler, fileLoggerHandler.constructor, "FileLoggerHandler")