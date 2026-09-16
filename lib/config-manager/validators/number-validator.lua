local classBuilder = require("lib.class-builder.index")

---@class NumberValidatorOptions: BaseConfigValidatorOptions
---@field min? BaseConfigValidatorOption<number>
---@field max? BaseConfigValidatorOption<number>
---@field isInteger? BaseConfigValidatorOption<boolean>

---@class NumberValidator: BaseConfigValidator
---@field min? BaseConfigValidatorOption<number>
---@field max? BaseConfigValidatorOption<number>
---@field isInteger? BaseConfigValidatorOption<boolean>
local numberValidator = {}

---Constructor
---@param options? NumberValidatorOptions
---@return NumberValidator
function numberValidator:constructor(options)
  options = options or {}

  self.skipper = options.skipper
  self.isNullable = options.isNullable or false
  self.min = options.min
  self.max = options.max
  self.isInteger = options.isInteger

  return self
end

---Validate
---@param value any
---@param config table<string, any>
---@return boolean isValid
---@return string? message
function numberValidator:validate(value, config)
  if self.skipper ~= nil and self.skipper(value, config) == true then
    return true, nil
  end

  if self.isNullable == true and type(value) == "nil" then
    return true, nil
  end

  if type(value) ~= "number" then
    return false, "invalid type expected: number"
  end

  if self.checker ~= nil and self.checker.value(value, config) == false then
    return false, self.checker.message or "didn't pass the checker"
  end

  if self.isInteger ~= nil and self.isInteger.value == true and math.type(value) ~= "integer" then
    return false, self.isInteger.message or "only integer is allowed"
  end

  if self.min ~= nil and value < self.min.value then
    return false, self.min.message or ("minimum allowed value: "..self.min.value)
  end

  if self.max ~= nil and value > self.max.value then
    return false, self.max.message or ("maximum allowed value: "..self.max.value)
  end

  return true, nil
end

---Factory
---@param value number
---@return number
function numberValidator:factory(value)
  return value
end

return classBuilder.createClass(numberValidator, numberValidator.constructor, "NumberValidator")