--[[
Name: OC Logger
Author: Navatusein
License: MIT
Version: 3.2
Dependencies: Class Builder, String Utilities
--]]

return {
  logger = require("lib.oc-logger.logger"),
  handlers = {
    file = require("lib.oc-logger.handlers.file-logger-handler"),
    discord = require("lib.oc-logger.handlers.discord-logger-handler"),
    scrollList = require("lib.oc-logger.handlers.scroll-list-logger-handler"),
  }
}