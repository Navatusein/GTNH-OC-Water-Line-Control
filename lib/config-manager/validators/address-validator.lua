local component = require("component")

local classBuilder = require("lib.class-builder.index")

---@class AddressValidatorOptions: BaseConfigValidatorOptions

---@class AddressValidator: BaseConfigValidator
local addressValidator = {}

---Constructor
---@param options? AddressValidatorOptions
---@return AddressValidator
function addressValidator:constructor(options)
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
function addressValidator:validate(value, config)
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

  local address = component.get(value)

  if address == nil then
    return false, "invalid address"
  end

  return true, nil
end

---Factory
---@param value string
---@return string
function addressValidator:factory(value)
  return value
end

return classBuilder.createClass(addressValidator, addressValidator.constructor, "AddressValidator")