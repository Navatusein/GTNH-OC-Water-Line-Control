local classBuilder = require("lib.class-builder.index")

---@class EnumValidatorOptions: BaseConfigValidatorOptions

---@class EnumValidator: BaseConfigValidator
---@field values table<string>
local enumValidator = {}

---Constructor
---@param values table<string>
---@param options? EnumValidatorOptions
---@return EnumValidator
function enumValidator:constructor(values, options)
  options = options or {}

  self.values = values
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
function enumValidator:validate(value, config)
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
    return false, self.checker.message or ("didn't pass the checker")
  end

  for _, enumValue in pairs(self.values) do
    if value == enumValue then
      return true, nil
    end
  end

  return false, "invalid value: " .. value
end

---Factory
---@param value string
---@return string
function enumValidator:factory(value)
  return value
end

return classBuilder.createClass(enumValidator, enumValidator.constructor, "EnumValidator")