local internet = require("internet")

local classBuilder = require("lib.class-builder.index")

---@class DiscordLoggerHandler: LoggerHandler
---@field discordWebhookUrl string
---@field chunkSize number
local discordLoggerHandler = {}

---Constructor
---@param logLevel "debug"|"info"|"warning"|"error"
---@param messageFormat string
---@param discordWebhookUrl string
---@return DiscordLoggerHandler
function discordLoggerHandler:constructor(logLevel, messageFormat, discordWebhookUrl)
  self.logLevel = logLevel
  self.messageFormat = messageFormat
  self.discordWebhookUrl = discordWebhookUrl

  self.chunkSize = 1900

  return self
end

---Log
---@param logger Logger
---@param level "debug"|"info"|"warning"|"error"
---@param message string
function discordLoggerHandler:log(logger, level, message)
  if self.discordWebhookUrl == "" then
    return
  end

  local chunks = {}

  for i = 1, #message, self.chunkSize do
    table.insert(chunks, message:sub(i, i + self.chunkSize - 1))
  end

  for _, value in pairs(chunks) do
    local data = {content = "**"..logger.name.."**\n```accesslog\n"..value.."\n```"}
    internet.request(self.discordWebhookUrl, data)

    os.sleep(0.1)
  end
end

return classBuilder.createClass(discordLoggerHandler, discordLoggerHandler.constructor, "DiscordLoggerHandler")