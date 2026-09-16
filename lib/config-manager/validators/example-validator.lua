local classBuilder = require("lib.class-builder.index")

---@class ExampleValidatorOptions: BaseConfigValidatorOptions

---@class ExampleValidator: BaseConfigValidator
local exampleValidator = {}

---Constructor
---@param options? ExampleValidatorOptions
---@return ExampleValidator
function exampleValidator:constructor(options)
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
function exampleValidator:validate(value, config)
  if self.skipper ~= nil and self.skipper(value, config) == true then
    return true, nil
  end

  if self.isNullable == true and type(value) == "nil" then
    return true, nil
  end

  if type(value) ~= "" then
    return false, "invalid type expected: "
  end

  if self.checker ~= nil and self.checker.value(value, config) == false then
    return false, self.checker.message or "didn't pass the checker"
  end

  return true, nil
end

---Factory
---@param value any
---@return any
function exampleValidator:factory(value)
  return value
end

return classBuilder.createClass(exampleValidator, exampleValidator.constructor, "ExampleValidator")