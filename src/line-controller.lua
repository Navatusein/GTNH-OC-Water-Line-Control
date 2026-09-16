local event = require("event")
local term = require("term")

local classBuilder = require("lib.class-builder.index")
local componentDiscover = require("lib.component-discover.index")

---@class LineController
---@field lastWorkProgress integer
---@field controllerProxy gt_machine
local lineController = {}

---Constructor
---@return LineController
function lineController:constructor()
  self.lastWorkProgress = 0

  return self
end

---Init
function lineController:init()
  term.write("Init Line components: ")
  self:initComponents()
  term.write("ok\n")
end

---Loop
function lineController:loop()
  local workProgress = self.controllerProxy.getWorkProgress()

  if self.lastWorkProgress > workProgress or (self.controllerProxy.hasWork() == false and self.lastWorkProgress ~= 0) then
    event.push("cycle_end")
    self.lastWorkProgress = 0
  end

  if self.controllerProxy.hasWork() == true then
    self.lastWorkProgress = workProgress
  end
end

---Get current state
---@return string
function lineController:getCurrentState()
  if self.controllerProxy == nil then
    return "nil"
  end

  if self.controllerProxy.hasWork() == true then
    return tostring(math.ceil(self.controllerProxy.getWorkProgress() / 20)).."/"..tostring(math.ceil(self.controllerProxy.getWorkMaxProgress() / 20))
  end

  return "Disable"
end

---Disable line controller
function lineController:disable()
  if self.controllerProxy ~= nil then
    self.controllerProxy.setWorkAllowed(false)
  end
end

---Init components
---@private
function lineController:initComponents()
  self.controllerProxy = componentDiscover.gtMachine("multimachine.purificationplant")

  if self.controllerProxy == nil then
    error("[Line] Water Purification Plant not found")
  end
end

return classBuilder.createClass(lineController, lineController.constructor, "LineController")