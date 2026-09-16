local classBuilder = require("lib.class-builder.index")

local helper = require("lib.config-manager.helpers.helper")

---@class ObjectListValidatorOptions: BaseConfigValidatorOptions
---@field template ConfigTemplate

---@class ObjectListValidator: BaseConfigValidator
---@field template ConfigTemplate
local objectListValidator = {}

---Constructor
---@param options ObjectListValidatorOptions
---@return ObjectListValidator
function objectListValidator:constructor(options)
  self.template = options.template
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
function objectListValidator:validate(value, config)
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
    return false, self.checker.message or "didn't pass the checker"
  end

  for objectIndex, object in ipairs(value) do
    local isValid, message = helper.validate(self.template, object, config)

      if isValid == false then
        return false, "("..objectIndex..") "..message
      end
  end

  return true, nil
end

---Factory
---@param value table
---@return table
function objectListValidator:factory(value)
  return value
end

return classBuilder.createClass(objectListValidator, objectListValidator.constructor, "ObjectListValidator")