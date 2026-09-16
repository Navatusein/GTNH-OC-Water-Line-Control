local classBuilder = require("lib.class-builder.index")

local helper = require("lib.config-manager.helpers.helper")

---@class ConfigManager
---@field template ConfigTemplate
local configManager = {}

---Constructor
---@param template ConfigTemplate
---@return ConfigManager
function configManager:constructor(template)
  self.template = template

  return self
end

---Validate config
---@param config table<string, any>
---@return table
function configManager:build(config)
  local isValid, message = helper.validate(self.template, config, config)

if isValid == false then
    error("[Config] "..message)
  end

  return helper.build(self.template, config)
end

return classBuilder.createClass(configManager, configManager.constructor, "ConfigManager")