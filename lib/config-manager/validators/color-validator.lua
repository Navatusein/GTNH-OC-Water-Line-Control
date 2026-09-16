local classBuilder = require("lib.class-builder.index")

---@class ColorValidatorOptions: BaseConfigValidatorOptions

---@class ColorValidator: BaseConfigValidator
local colorValidator = {}

---Constructor
---@param options? ColorValidatorOptions
---@return ColorValidator
function colorValidator:constructor(options)
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
function colorValidator:validate(value, config)
  if self.skipper ~= nil and self.skipper(value, config) == true then
    return true, nil
  end

  if self.isNullable == true and type(value) == "nil" then
    return true, nil
  end

  if type(value) ~= "number" then
    return false, "invalid type expected: color"
  end

  if self.checker ~= nil and self.checker.value(value, config) == false then
    return false, self.checker.message or "didn't pass the checker"
  end

  if value < 0 or value > 15 then
    return false, "invalid color"
  end

  return true, nil
end

---Factory
---@param value number
---@return number
function colorValidator:factory(value)
  return value
end

return classBuilder.createClass(colorValidator, colorValidator.constructor, "ColorValidator")