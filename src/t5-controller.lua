local sides = require("sides")
local event = require("event")

local stateMachineLib = require("lib.state-machine-lib")
local componentDiscoverLib = require("lib.component-discover-lib")
local gtSensorParserLib = require("lib.gt-sensor-parser")

---@class T5ControllerConfig
---@field plasmaTransposerAddress string
---@field coolantTransposerAddress string

local t5controller = {}

---Crate new T5Controller object from config
---@param config T5ControllerConfig
---@return T5Controller
function t5controller:newFormConfig(config)
  return self:new(config.plasmaTransposerAddress, config.coolantTransposerAddress)
end

---Crate new T5Controller object
---@param plasmaTransposerAddress string
---@param coolantTransposerAddress string
function t5controller:new(plasmaTransposerAddress, coolantTransposerAddress)

  ---@class T5Controller
  local obj = {}

  obj.plasmaTransposerProxy = componentDiscoverLib.discoverProxy(plasmaTransposerAddress, "[T5] Plasma Transposer", "transposer")
  obj.coolantTransposerProxy = componentDiscoverLib.discoverProxy(coolantTransposerAddress, "[T5] Coolant Transposer", "transposer")
  obj.controllerProxy = nil

  obj.stateMachine = stateMachineLib:new()
  obj.gtSensorParser = nil

  obj.transposerLiquids = {}

  ---Init T5Controller
  function obj:init()
    self:findMachineProxy()
    self:findTransposerFluid(self.plasmaTransposerProxy, "plasma.helium")
    self:findTransposerFluid(self.coolantTransposerProxy, "supercoolant")

    self.gtSensorParser:getInformation()

    self.stateMachine.states.idle = self.stateMachine:createState("Idle")
    self.stateMachine.states.idle.init = function ()
      local temperature = self.gtSensorParser:getNumber(4, "Current temperature:")

      if self.controllerProxy.hasWork() and temperature ~= 0 then
        self.stateMachine:setState(self.stateMachine.states.waitEnd)
      end
    end
    self.stateMachine.states.idle.update = function()
      if self.controllerProxy.getWorkProgress() > 900 then 
        self.stateMachine:setState(self.stateMachine.states.waitEnd)
        return
      end

      if self.controllerProxy.hasWork() then
        self.stateMachine.data.iterations = 0
        self.stateMachine:setState(self.stateMachine.states.heating)
      end
    end

    self.stateMachine.states.heating = self.stateMachine:createState("Heating")
    self.stateMachine.states.heating.init = function ()
      if self.stateMachine.data.iterations >= 2 then
        self.stateMachine:setState(self.stateMachine.states.waitEnd)
        return
      end

      local result = self.plasmaTransposerProxy.transferFluid(
        self.transposerLiquids["plasma.helium"].side,
        sides.up,
        100,
        self.transposerLiquids["supercoolant"].tank)

      if result == false then
        self.controllerProxy.setWorkAllowed(false)
        event.push("log_warning", "[T5] Not enough Helium Plasma for craft")
      end
    end
    self.stateMachine.states.heating.update = function()
      local temperature = self.gtSensorParser:getNumber(4, "Current temperature:")

      if self.controllerProxy.hasWork() == false then
        self.stateMachine:setState(self.stateMachine.states.idle)
      end

      if temperature >= 10000 then
        self.stateMachine:setState(self.stateMachine.states.cooling)
      end
    end

    self.stateMachine.states.cooling = self.stateMachine:createState("Cooling")
    self.stateMachine.states.cooling.init = function ()
      local result = self.coolantTransposerProxy.transferFluid(
        self.transposerLiquids["supercoolant"].side,
        sides.up,
        2000,
        self.transposerLiquids["supercoolant"].tank)

      if result == false then
        self.controllerProxy.setWorkAllowed(false)
        event.push("log_warning", "[T5] Not enough Super Coolant for craft")
      end
    end
    self.stateMachine.states.cooling.update = function()
      local temperature = self.gtSensorParser:getNumber(4, "Current temperature:")

      if self.controllerProxy.hasWork() == false then
        self.stateMachine:setState(self.stateMachine.states.idle)
      end

      if temperature <= 0 then
        self.stateMachine:setState(self.stateMachine.states.heating)
        self.stateMachine.data.iterations = self.stateMachine.data.iterations + 1
      end
    end

    self.stateMachine.states.waitEnd = self.stateMachine:createState("Wait End")

    event.listen("cycle_end", function ()
      if self.stateMachine.currentState == self.stateMachine.states.waitEnd then
        self.stateMachine:setState(self.stateMachine.states.idle)
      end
    end)

    self.stateMachine:setState(self.stateMachine.states.idle)
  end

  ---Find controller proxy
  function obj:findMachineProxy()
    self.controllerProxy = componentDiscoverLib.discoverGtMachine("multimachine.purificationunitplasmaheater")

    if self.controllerProxy == nil then
      error("[T5] Extreme Temperature Fluctuation Purification Unit not found")
    end

    self.gtSensorParser = gtSensorParserLib:new(self.controllerProxy)
  end

  ---Find side of transposer with fluid
  ---@param proxy transposer
  ---@param fluidName string
  function obj:findTransposerFluid(proxy, fluidName)
    local result, skipped = componentDiscoverLib.discoverTransposerFluidStorage(proxy, {fluidName}, {sides.up})

    if #skipped ~= 0 then
      error("[T5] Can't find liquid: "..table.concat(skipped, ", "))
    end

    for key, value in pairs(result) do
      self.transposerLiquids[key] = value
    end
  end

  ---Loop
  function obj:loop()
    self.gtSensorParser:getInformation()
    self.stateMachine:update()
  end

  ---Get current state
  ---@return string
  function obj:getState()
    if self.controllerProxy.isWorkAllowed() == false then
      return "Controller disabled"
    end

    if self.controllerProxy.hasWork() == false then
      return "Wait cycle"
    end

    local state = self.stateMachine.currentState and self.stateMachine.currentState.name or "nil"
    local successChange = self.gtSensorParser:getNumber(2, "Success chance:")

    if successChange == nil then
      successChange = 0
    end

    return "State: ["..state.."] Success: ["..successChange.."%]"
  end

  setmetatable(obj, self)
  self.__index = self
  return obj
end

return t5controller