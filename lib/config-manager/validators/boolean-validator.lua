local classBuilder = require("lib.class-builder.index")

---@class BooleanValidatorOptions: BaseConfigValidatorOptions

---@class BooleanValidator: BaseConfigValidator
local booleanValidator = {}

---Constructor
---@param options? BooleanValidatorOptions
---@return BooleanValidator
function booleanValidator:constructor(options)
  options = options or {}

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
function booleanValidator:validate(value, config)
  if self.skipper ~= nil and self.skipper(value, config) == true then
    return true, nil
  end

  if self.isNullable == true and type(value) == "nil" then
    return true, nil
  end

  if type(value) ~= "boolean" then
    return false, "invalid type expected: boolean"
  end

  if self.checker ~= nil and self.checker.value(value, config) == false then
    return false, self.checker.message or ("didn't pass the checker")
  end

  return true, nil
end

---Factory
---@param value boolean
---@return boolean
function booleanValidator:factory(value)
  return value
end

return classBuilder.createClass(booleanValidator, booleanValidator.constructor, "BooleanValidator")