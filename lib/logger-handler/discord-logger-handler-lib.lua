-- Discord Logger Handler Lib
-- Author: Navatusein
-- License: MIT
-- Version: 1.4

local internet = require("internet")

---@class DiscordLoggerHandlerConfig
---@field logLevel "debug"|"info"|"warning"|"error"
---@field messageFormat string
---@field discordWebhookUrl string

local discordLoggerHandler = {}

---Crate new DiscordLoggerHandler object from config
---@param config DiscordLoggerHandlerConfig
---@return DiscordLoggerHandler
function discordLoggerHandler:newFormConfig(config)
  return self:new(config.logLevel, config.messageFormat, config.discordWebhookUrl)
end

---Crate new DiscordLoggerHandler object
---@param logLevel "debug"|"info"|"warning"|"error"
---@param messageFormat string
---@param discordWebhookUrl string
---@return DiscordLoggerHandler
function discordLoggerHandler:new(logLevel, messageFormat, discordWebhookUrl)

  ---@class DiscordLoggerHandler: LoggerHandler
  local obj = {}

  obj.logLevel = logLevel
  obj.messageFormat = messageFormat
  obj.discordWebhookUrl = discordWebhookUrl

  obj.chunkSize = 1900

  ---Send log to discord webhook
  ---@param logger Logger
  ---@param level "debug"|"info"|"warning"|"error"
  ---@param message string
  function obj:log(logger, level, message)
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

  setmetatable(obj, self)
  self.__index = self
  return obj
end

return discordLoggerHandler