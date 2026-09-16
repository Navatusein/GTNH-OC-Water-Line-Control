local classBuilder = require("lib.class-builder.index")

---@class StateDefinition
---@field key string
---@field name string
---@field onInit? fun()
---@field onUpdate? fun()
---@field onExit? fun()
local stateDefinition = {}

---Constructor
---@return StateDefinition
function stateDefinition:constructor(key, name)
  self.key = key
  self.name = name

  self.onInit = nil
  self.onUpdate = nil
  self.onExit = nil

  return self
end

---Register on init function
---@param callback fun()
---@return StateDefinition
function stateDefinition:registerOnInit(callback)
  self.onInit = callback
  return self
end

---Register on update function
---@param callback fun()
---@return StateDefinition
function stateDefinition:registerOnUpdate(callback)
  self.onUpdate = callback
  return self
end

---Register on exit function
---@param callback fun()
---@return StateDefinition
function stateDefinition:registerOnExit(callback)
  self.onExit = callback
  return self
end

return classBuilder.createClass(stateDefinition, stateDefinition.constructor, "StateDefinition")