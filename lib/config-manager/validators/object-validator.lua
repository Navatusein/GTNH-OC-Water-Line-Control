local classBuilder = require("lib.class-builder.index")

local helper = require("lib.config-manager.helpers.helper")

---@class ObjectValidatorOptions: BaseConfigValidatorOptions
---@field objectFactory? fun(config: table): table
---@field template ConfigTemplate

---@class ObjectValidator: BaseConfigValidator
---@field template ConfigTemplate
local objectValidator = {}

---Constructor
---@param options ObjectValidatorOptions
---@return ObjectValidator
function objectValidator:constructor(options)
  self.template = options.template
  self.objectFactory = options.objectFactory
  self.skipper = options.skipper
  self.isNullable = options.isNullable or false
  self.checker = options.checker

  return self
end

---Validate
---@param value any
---@param config table<string, any>
---@return boolean isValid
---@return string? message
function objectValidator:validate(value, config)
  if self.skipper ~= nil and self.skipper(value, config) == true then
    return true, nil
  end

  if self.isNullable == true and type(value) == "nil" then
    return true, nil
  end

  if type(value) ~= "table" then
    return false, "invalid type expected: table"
  end

  if self.checker ~= nil and self.checker.value(value, config) == false then
    return false, self.checker.message or ("didn't pass the checker")
  end

  local isValid, message = helper.validate(self.template, value, config)

  if isValid == false then
    return false, message
  end

  return true, nil
end

---Factory
---@param value table
---@return table
function objectValidator:factory(value)
  local buildedConfig = helper.build(self.template, value)

  if self.objectFactory then
    return self.objectFactory(buildedConfig)
  else
    return buildedConfig
  end
end


return classBuilder.createClass(objectValidator, objectValidator.constructor, "ObjectValidator")