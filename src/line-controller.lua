local event = require("event")

local componentDiscoverLib = require("lib.component-discover-lib")

---@class LineControllerConfig

local lineController = {}

---Crate new LineController object from config
---@return LineController
function lineController:newFormConfig()
  return self:new()
end

---Crate new LineController object
function lineController:new()

  ---@class LineController
  local obj = {}

  obj.controllerProxy = nil

  local lastWorkProgress = 0

  ---Init LineController
  function obj:init()
    self:findMachineProxy()
  end

  ---Find controller proxy
  function obj:findMachineProxy()
    self.controllerProxy = componentDiscoverLib.discoverGtMachine("multimachine.purificationplant")

    if self.controllerProxy == nil then
      error("[Line] Water Purification Plant not found")
    end
  end

  ---Loop
  function obj:loop()
    local workProgress = self.controllerProxy.getWorkProgress()

    if lastWorkProgress > workProgress or (self.controllerProxy.hasWork() == false and lastWorkProgress ~= 0) then
      event.push("cycle_end")
      lastWorkProgress = 0
    end

    if self.controllerProxy.hasWork() then 
      lastWorkProgress = workProgress
    end
  end

  ---Get current state
  ---@return string
  function obj:getState()
    if self.controllerProxy == nil then
      return "nil"
    end

    if self.controllerProxy.hasWork() then
      return tostring(math.ceil(self.controllerProxy.getWorkProgress() / 20)).."/"..tostring(math.ceil(self.controllerProxy.getWorkMaxProgress()/20))
    end

    return "Disable"
  end

  setmetatable(obj, self)
  self.__index = self
  return obj
end

return lineController