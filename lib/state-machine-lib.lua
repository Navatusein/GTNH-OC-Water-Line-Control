-- State Machine Lib
-- Author: Navatusein
-- License: MIT
-- Version: 1.3

---@class State
---@field name string
---@field init? fun()
---@field update? fun()
---@field exit? fun()

local stateMachine = {}

---Crate new StateMachine object
---@return StateMachine
function stateMachine:new()

  ---@class StateMachine
  local obj = {}

  obj.states = {}
  obj.data = {}

  obj.currentState = nil

  ---Create new state
  ---@param name string
  ---@return State
  function obj:createState(name)
    return {name = name}
  end

  ---Update
  function obj:update()
    if self.currentState ~= nil then
      if self.currentState.update then
        self.currentState:update()
      end
    end
  end

  ---Set state
  ---@param state State
  function obj:setState(state)
    assert(state ~= nil, "Cannot set a nil state.")

    if self.currentState ~= nil then
      if self.currentState.exit then
        self.currentState:exit()
      end
    end

    self.currentState = state

    if self.currentState.init then
      self.currentState:init()
    end
  end

  setmetatable(obj, self)
  self.__index = self
  return obj
end

return stateMachine