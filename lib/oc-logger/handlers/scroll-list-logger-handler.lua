local classBuilder = require("lib.class-builder.index")
local tableUtilities = require("lib.table-utilities.index")

---@class ScrollListLoggerHandler
---@field logs table<string>
local scrollListLoggerHandler = {}

---Constructor
---@param logLevel "debug"|"info"|"warning"|"error"
---@param logListSize number
---@return ScrollListLoggerHandler
function scrollListLoggerHandler:constructor(logLevel, logListSize)

  self.logLevel = logLevel
  self.logListSize = logListSize

  self.messageFormat = "{Message}"
  self.logs = {}

  return self
end

---Log
---@param logger Logger
---@param level "debug"|"info"|"warning"|"error"
---@param message string
function scrollListLoggerHandler:log(logger, level, message)
  if level == "debug" then
    tableUtilities.pushFront(self.logs, "&lightBlue;"..message.."&white;", self.logListSize)
  elseif level == "info" then
    tableUtilities.pushFront(self.logs, message, self.logListSize)
  elseif level == "warning" then
    tableUtilities.pushFront(self.logs, "&yellow;"..message.."&white;", self.logListSize)
  elseif level == "error" then
    tableUtilities.pushFront(self.logs, "&red;[Error] "..message.."&white;", self.logListSize)
  end
end

---Get logs list
function scrollListLoggerHandler:getLogs()
  return self.logs
end

---Clear logs list
function scrollListLoggerHandler:clearLogs()
  tableUtilities.clear(self.logs)
end

return classBuilder.createClass(scrollListLoggerHandler, scrollListLoggerHandler.constructor, "ScrollListLoggerHandler")