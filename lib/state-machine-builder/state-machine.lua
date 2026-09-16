local classBuilder = require("lib.class-builder.index")

local stateDefinition = require("lib.state-machine-builder.state-definition")

---@class StateMachine<T>
---@field states table<string, StateDefinition>
---@field data T
---@field currentState? StateDefinition
local stateMachine = {}

---Constructor
---@return StateMachine
function stateMachine:constructor()

  self.states = {}
  self.data = {}

  self.currentState = nil

  return self
end

---Create new state
---@param key string
---@param name string
---@param options? StateDefinitionOptions
---@return StateDefinition
function stateMachine:createState(key, name, options)
  assert(self.states[key] == nil, "State ["..key.."] already exists")

  self.states[key] = stateDefinition:new(key, name)

  if options ~= nil and options.onInit ~= nil then
    self.states[key]:registerOnInit(options.onInit)
  end

  if options ~= nil and options.onUpdate ~= nil then
    self.states[key]:registerOnUpdate(options.onUpdate)
  end

  if options ~= nil and options.onExit ~= nil then
    self.states[key]:registerOnExit(options.onExit)
  end

  return self.states[key]
end

---Set state
---@param key string
function stateMachine:setState(key)
  assert(self.states[key] ~= nil, "Undefined state key ["..key.."]")

  if self.currentState ~= nil then
    if self.currentState.onExit then
      self.currentState:onExit()
    end
  end

  self.currentState = self.states[key]

  if self.currentState.onInit then
    self.currentState:onInit()
  end
end

---Get current state
---@return StateDefinition|nil
function stateMachine:getCurrentState()
  return self.currentState
end

---Get current state key
---@return string
function stateMachine:getCurrentStateKey()
  return self.currentState.key or self.currentState.key and "nil"
end

---Get current state name
---@return string
function stateMachine:getCurrentStateName()
  return self.currentState.name or self.currentState.name and "nil"
end

---Set state machine data
---@param key string
---@param value any
function stateMachine:setData(key, value)
  self.data[key] = value
end

---Get state machine data
---@param key string
---@return any
function stateMachine:getData(key)
  assert(self.data[key] ~= nil, "Undefined state data key ["..key.."]")

  return self.data[key]
end

---Loop
function stateMachine:loop()
  if self.currentState ~= nil then
    if self.currentState.onUpdate then
      self.currentState:onUpdate()
    end
  end
end

return classBuilder.createClass(stateMachine, stateMachine.constructor, "StateMachine")