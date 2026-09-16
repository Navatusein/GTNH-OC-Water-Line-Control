local classBuilder = require("lib.class-builder.index")

---@class StringValidatorOptions: BaseConfigValidatorOptions
---@field minLength? BaseConfigValidatorOption<number>
---@field maxLength? BaseConfigValidatorOption<number>
---@field regex? BaseConfigValidatorOption<string>

---@class StringValidator: BaseConfigValidator
---@field minLength? BaseConfigValidatorOption<number>
---@field maxLength? BaseConfigValidatorOption<number>
---@field regex? BaseConfigValidatorOption<string>
local stringValidator = {}

---Constructor
---@param options? StringValidatorOptions
---@return StringValidator
function stringValidator:constructor(options)
  options = options or {}

  self.skipper = options.skipper
  self.isNullable = options.isNullable or false
  self.checker = options.checker
  self.minLength = options.minLength
  self.maxLength = options.maxLength
  self.regex = options.regex

  return self
end

---Validate
---@param value any
---@param config table<string, any>
---@return boolean isValid
---@return string? message
function stringValidator:validate(value, config)
  if self.skipper ~= nil and self.skipper(value, config) == true then
    return true, nil
  end

  if self.isNullable == true and type(value) == "nil" then
    return true, nil
  end

  if type(value) ~= "string" then
    return false, "invalid type expected: string"
  end

  if self.checker ~= nil and self.checker.value(value, config) == false then
    return false, self.checker.message or "didn't pass the checker"
  end

  if self.minLength ~= nil and #value < self.minLength.value then
    return false, self.minLength.message or ("minimum allowed length: "..self.minLength.value)
  end

  if self.maxLength ~= nil and #value > self.maxLength.value then
    return false, self.maxLength.message or ("maximum allowed length: "..self.maxLength.value)
  end

  if self.regex ~= nil and string.match(value, self.regex.value) == nil then
    return false, self.regex.message or ("mismatched regex: "..self.regex.value)
  end

  return true, nil
end

---Factory
---@param value string
---@return string
function stringValidator:factory(value)
  return value
end


return classBuilder.createClass(stringValidator, stringValidator.constructor, "StringValidator")