local sides = require("sides")
local event = require("event")

local stateMachineLib = require("lib.state-machine-lib")
local componentDiscoverLib = require("lib.component-discover-lib")
local gtSensorParserLib = require("lib.gt-sensor-parser")

---@class T3ControllerConfig
---@field transposerAddress string

local t3controller = {}

---Crate new T3Controller object from config
---@param config T3ControllerConfig
---@return T3Controller
function t3controller:newFormConfig(config)
  return self:new(config.transposerAddress)
end

---Crate new T3Controller object
---@param transposerAddress string
function t3controller:new(transposerAddress)

  ---@class T3Controller
  local obj = {}

  obj.transposerProxy = nil
  obj.controllerProxy = nil

  obj.stateMachine = stateMachineLib:new()
  obj.gtSensorParser = nil

  obj.transposerLiquids = {}

  ---Init T3Controller
  function obj:init()
    self:findMachineProxy()
    self:findTransposerFluid(self.transposerProxy, "polyaluminiumchloride")

    self.stateMachine.states.idle = self.stateMachine:createState("Idle")
    self.stateMachine.states.idle.update = function()
      if self.controllerProxy.hasWork() then
        self.stateMachine:setState(self.stateMachine.states.work)
      end
    end

    self.stateMachine.states.work = self.stateMachine:createState("Work")
    self.stateMachine.states.work.init = function()
      local result = self.transposerProxy.transferFluid(
        self.transposerLiquids["polyaluminiumchloride"].side,
        sides.up,
        900000,
        self.transposerLiquids["polyaluminiumchloride"].tank)

      if result ~= true then
        self.controllerProxy.setWorkAllowed(false)
        event.push("log_warning", "[T3] Not enough Polyaluminium Chloride for craft")
      end

      self.stateMachine:setState(self.stateMachine.states.waitEnd)
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
    self.controllerProxy = componentDiscoverLib.discoverGtMachine("multimachine.purificationunitflocculator")

    if self.controllerProxy == nil then
      error("[T3] Flocculation Purification Unit not found")
    end

    self.transposerProxy = componentDiscoverLib.discoverProxy(transposerAddress, "[T3] Transposer", "transposer")
    self.gtSensorParser = gtSensorParserLib:new(self.controllerProxy)
  end

  ---Find side of transposer with fluid
  ---@param proxy transposer
  ---@param fluidName string
  function obj:findTransposerFluid(proxy, fluidName)
    local result, skipped = componentDiscoverLib.discoverTransposerFluidStorage(proxy, {fluidName}, {sides.up})

    if #skipped ~= 0 then
      error("[T4] Can't find liquid: "..table.concat(skipped, ", "))
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

return t3controller