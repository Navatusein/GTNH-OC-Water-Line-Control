local sides = require("sides")
local event = require("event")

local stateMachineLib = require("lib.state-machine-lib")
local componentDiscoverLib = require("lib.component-discover-lib")
local gtSensorParserLib = require("lib.gt-sensor-parser")

---@class T7ControllerConfig
---@field inertGasTransposerAddress string
---@field superConductorTransposerAddress string
---@field netroniumTransposerAddress string
---@field coolantTransposerAddress string

local t7controller = {}

---Crate new T7Controller object from config
---@param config T7ControllerConfig
---@return T7Controller
function t7controller:newFormConfig(config)
  return self:new(
    config.inertGasTransposerAddress,
    config.superConductorTransposerAddress,
    config.netroniumTransposerAddress,
    config.coolantTransposerAddress)
end

---Crate new T7Controller object
---@param inertGasTransposerAddress string
---@param superConductorTransposerAddress string
---@param netroniumTransposerAddress string
---@param coolantTransposerAddress string
---@return T7Controller
function t7controller:new(
  inertGasTransposerAddress,
  superConductorTransposerAddress,
  netroniumTransposerAddress,
  coolantTransposerAddress)

  ---@class T7Controller
  local obj = {}

  obj.inertGasTransposerProxy = nil
  obj.superConductorTransposerProxy = nil
  obj.netroniumTransposerProxy = nil
  obj.coolantTransposerProxy = nil
  obj.controllerProxy = nil

  ---@type TransposerFluidStorageDescriptor[]
  obj.transposerLiquids = {}

  obj.stateMachine = stateMachineLib:new()
  obj.gtSensorParser = nil

  ---Init T7Controller
  function obj:init()
    self:findMachineProxy()

    self:findTransposerFluid(self.inertGasTransposerProxy, {"helium", "neon", "krypton", "xenon"})
    self:findTransposerFluid(self.superConductorTransposerProxy, {"superconductor"})
    self:findTransposerFluid(self.netroniumTransposerProxy, {"neutronium"})
    self:findTransposerFluid(self.coolantTransposerProxy, {"supercoolant"})

    self.gtSensorParser:getInformation()

    self.stateMachine.states.idle = self.stateMachine:createState("Idle")
    self.stateMachine.states.idle.update = function()
      if self.controllerProxy.hasWork() then
        self.stateMachine:setState(self.stateMachine.states.work)
      end
    end

    self.stateMachine.states.work = self.stateMachine:createState("Work")
    self.stateMachine.states.work.init = function()
      local bitString = self.gtSensorParser:getString(4, "Current control signal (binary): 0b")

      if bitString == nil then
        bitString = "0000"
      end

      local bits = self:bitParser(bitString)

      if bits[1] == false and bits[2] == false and bits[3] == false and bits[4] == false then
        self:putCoolant()
        self.stateMachine:setState(self.stateMachine.states.waitEnd)
        return
      end

      if bits[4] == true then
        self.stateMachine:setState(self.stateMachine.states.waitEnd)
        return
      end

      if bits[1] == true then
        self:putInertGas(bits)
      end

      if bits[2] == true then
        self:putSuperConductor()
      end

      if bits[3] == true then
        self:putNeutronium()
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
    self.controllerProxy = componentDiscoverLib.discoverGtMachine("multimachine.purificationunitdegasifier")

    if self.controllerProxy == nil then
      error("[T7] Residual Decontaminant Degasser Purification Unit not found")
    end

    self.inertGasTransposerProxy = componentDiscoverLib.discoverProxy(
      inertGasTransposerAddress,
      "[T7] Inert Gas Transposer",
      "transposer")
    self.superConductorTransposerProxy = componentDiscoverLib.discoverProxy(
      superConductorTransposerAddress,
      "[T7] Super Conductor Transposer",
      "transposer")
    self.netroniumTransposerProxy = componentDiscoverLib.discoverProxy(
      netroniumTransposerAddress,
      "[T7] Netronium Transposer",
      "transposer")
    self.coolantTransposerProxy = componentDiscoverLib.discoverProxy(
      coolantTransposerAddress,
      "[T7] Coolant Transposer",
      "transposer")
    self.gtSensorParser = gtSensorParserLib:new(self.controllerProxy)
  end

  ---Find side of transposer with fluid
  ---@param proxy any
  ---@param fluidNames string[]
  function obj:findTransposerFluid(proxy, fluidNames)
    local result, skipped = componentDiscoverLib.discoverTransposerFluidStorage(proxy, fluidNames, {sides.up})

    if #skipped ~= 0 then
      error("[T7] Can't find liquid: "..table.concat(skipped, ", "))
    end

    for key, value in pairs(result) do
      self.transposerLiquids[key] = value
    end
  end

  ---Parse bit string to bits array
  ---@param bitString string|number
  ---@return boolean[]
  function obj:bitParser(bitString)

    bitString = string.rep("0", 4 - #bitString)..bitString

    local bits = {
      tonumber(bitString:sub(4, 4)) == 1,
      tonumber(bitString:sub(3, 3)) == 1,
      tonumber(bitString:sub(2, 2)) == 1,
      tonumber(bitString:sub(1, 1)) == 1,
    }

    return bits
  end

  ---Put inert gas in input hatch
  ---@param bits boolean[]
  function obj:putInertGas(bits)
    local inertGas = ""
    local count = 0

    if bits[2] == false and bits[3] == false then
      inertGas = "helium"
      count = 10000
    elseif bits[2] == true and bits[3] == false then
      inertGas = "neon"
      count = 7500
    elseif bits[2] == false and bits[3] == true then
      inertGas = "krypton"
      count = 5000
    elseif bits[2] == true and bits[3] == true then
      inertGas = "xenon"
      count = 2500
    end

    local result = self.inertGasTransposerProxy.transferFluid(
      self.transposerLiquids[inertGas].side,
      sides.up,
      count,
      self.transposerLiquids[inertGas].tank)

    if result == false then
      self.controllerProxy.setWorkAllowed(false)
      event.push("log_warning", "[T7] Not enough "..inertGas.." for craft")
    end
  end

  ---Put super conductor in input hatch
  function obj:putSuperConductor()
    local result = self.superConductorTransposerProxy.transferFluid(
      self.transposerLiquids["superconductor"].side,
      sides.up,
      1440,
      self.transposerLiquids["superconductor"].tank)

    if result == false then
      self.controllerProxy.setWorkAllowed(false)
      event.push("log_warning", "[T7] Not enough superconductor for craft")
    end
  end

  ---Put super conductor in input hatch
  function obj:putNeutronium()
    local result = self.netroniumTransposerProxy.transferFluid(
      self.transposerLiquids["neutronium"].side,
      sides.up,
      4608,
      self.transposerLiquids["neutronium"].tank)

    if result == false then
      self.controllerProxy.setWorkAllowed(false)
      event.push("log_warning", "[T7] Not enough neutronium for craft")
    end
  end

  ---Put coolant in input hatch
  function obj:putCoolant()
    local result = self.coolantTransposerProxy.transferFluid(
      self.transposerLiquids["supercoolant"].side,
      sides.up,
      10000,
      self.transposerLiquids["supercoolant"].tank)

    if result == false then
      self.controllerProxy.setWorkAllowed(false)
      event.push("log_warning", "[T7] Not enough coolant for craft")
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

return t7controller