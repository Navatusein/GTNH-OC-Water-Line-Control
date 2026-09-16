local sides = require("sides")
local event = require("event")
local term = require("term")

local classBuilder = require("lib.class-builder.index")
local componentDiscover = require("lib.component-discover.index")
local stateMachineBuilder = require("lib.state-machine-builder.index")
local gtSensorParser = require("lib.gt-sensor-parser.index")

---Parse bit string to bits array
---@param bitString string
---@return boolean[]
local function bitParser(bitString)
  bitString = string.rep("0", 4 - #bitString)..bitString

  local bits = {
    tonumber(bitString:sub(4, 4)) == 1,
    tonumber(bitString:sub(3, 3)) == 1,
    tonumber(bitString:sub(2, 2)) == 1,
    tonumber(bitString:sub(1, 1)) == 1,
  }

  return bits
end

---@class T7Controller
---@field stateMachine StateMachine
---@field inertGasTransposerAddress string
---@field superConductorTransposerAddress string
---@field netroniumTransposerAddress string
---@field coolantTransposerAddress string
---@field superconductorCount integer
---@field neutroniumCount integer
---@field supercoolantCount integer
---@field controllerProxy gt_machine
---@field inertGasTransposerProxy transposer
---@field superConductorTransposerProxy transposer
---@field netroniumTransposerProxy transposer
---@field coolantTransposerProxy transposer
---@field gtSensorParser GtSensorParser
---@field transposerLiquids table<string, TransposerFluidStorageDescriptor>
local t7controller = {}

---Constructor
---@param inertGasTransposerAddress string
---@param superConductorTransposerAddress string
---@param netroniumTransposerAddress string
---@param coolantTransposerAddress string
---@return T7Controller
function t7controller:constructor(
  inertGasTransposerAddress,
  superConductorTransposerAddress,
  netroniumTransposerAddress,
  coolantTransposerAddress
)
  self.inertGasTransposerAddress = inertGasTransposerAddress
  self.superConductorTransposerAddress = superConductorTransposerAddress
  self.netroniumTransposerAddress = netroniumTransposerAddress
  self.coolantTransposerAddress = coolantTransposerAddress

  self.superconductorCount = 1440
  self.neutroniumCount = 4608
  self.supercoolantCount = 10000

  self.transposerLiquids = {}

  self.stateMachine = stateMachineBuilder.stateMachine:new()

  return self
end

---Init
function t7controller:init()
  term.write("Init T7 components: ")
  self:initComponents()
  term.write("ok\n")

  term.write("Init T7 state machine: ")
  self:initStateMachine()
  term.write("ok\n")
end

---Loop
function t7controller:loop()
  self.gtSensorParser:getInformation()
  self.stateMachine:loop()
end

---Get current state
---@return string
function t7controller:getCurrentState()
  if self.controllerProxy.isWorkAllowed() == false then
    return "Controller disabled"
  end

  if self.controllerProxy.hasWork() == false then
    return "Wait cycle"
  end

  local successChance = self.gtSensorParser:getNumber(2)

  if successChance == nil then
    successChance = 0
  end

  return "State: ["..self.stateMachine:getCurrentStateName().."] Success: ["..successChance.."%]"
end

---Init components
---@private
function t7controller:initComponents()
  self.controllerProxy = componentDiscover.gtMachine("multimachine.purificationunitdegasifier")

  if self.controllerProxy == nil then
    error("[T7] Residual Decontaminant Degasser Purification Unit not found")
  end

  self.inertGasTransposerProxy = componentDiscover.proxy(
    self.inertGasTransposerAddress,
    "transposer",
    "[T7] Inert Gas Transposer"
  )

  self.superConductorTransposerProxy = componentDiscover.proxy(
    self.superConductorTransposerAddress,
    "transposer",
    "[T7] Super Conductor Transposer"
  )

  self.netroniumTransposerProxy = componentDiscover.proxy(
    self.netroniumTransposerAddress,
    "transposer",
    "[T7] Netronium Transposer"
  )

  self.coolantTransposerProxy = componentDiscover.proxy(
    self.coolantTransposerAddress,
    "transposer",
    "[T7] Coolant Transposer"
  )

  self.gtSensorParser = gtSensorParser.parser:new(self.controllerProxy)

  self:findTransposerFluid(self.inertGasTransposerProxy, {"helium", "neon", "krypton", "xenon"})
  self:findTransposerFluid(self.superConductorTransposerProxy, {"superconductor"})
  self:findTransposerFluid(self.netroniumTransposerProxy, {"neutronium"})
  self:findTransposerFluid(self.coolantTransposerProxy, {"supercoolant"})

  self.gtSensorParser:getInformation()
end

---Init state machine
---@private
function t7controller:initStateMachine()
  self.stateMachine:createState("idle", "Idle", {
    onUpdate = function ()
      if self.gtSensorParser:getNumber(2) == 100 then
        self.stateMachine:setState("waitEnd")
      elseif self.controllerProxy.hasWork() == true then
        self.stateMachine:setState("work")
      end
    end
  })

  self.stateMachine:createState("work", "Work", {
    onInit = function ()
      local bitString = self.gtSensorParser:getString(4)

      if bitString == nil then
        bitString = "0000"
      end

      local bits = bitParser(bitString)

      if bits[1] == false and bits[2] == false and bits[3] == false and bits[4] == false then
        self:putCoolant()
        self.stateMachine:setState("waitEnd")
        return
      end

      if bits[4] == true then
        self.stateMachine:setState("waitEnd")
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

      self.stateMachine:setState("waitEnd")
    end
  })

  self.stateMachine:createState("waitEnd", "Wait End")

  event.listen("cycle_end", function ()
    if self.stateMachine:getCurrentStateKey() == "waitEnd" then
      self.stateMachine:setState("idle")
    end
  end)

  self.stateMachine:setState("idle")
end

---Find side of transposer with fluid
---@param proxy transposer
---@param fluidNames string[]
---@private
function t7controller:findTransposerFluid(proxy, fluidNames)
  local result, skipped = componentDiscover.transposerFluidStoragesByNames(proxy, fluidNames, {sides.up})

  if #skipped ~= 0 then
    error("[T7] Can't find liquid: "..table.concat(skipped, ", "))
  end

  for key, value in pairs(result) do
    self.transposerLiquids[key] = value
  end
end

---Put inert gas in input hatch
---@param bits boolean[]
---@private
function t7controller:putInertGas(bits)
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

  local _, result = self.inertGasTransposerProxy.transferFluid(
    self.transposerLiquids[inertGas].side,
    sides.up,
    count,
    self.transposerLiquids[inertGas].tank
  )

  if result ~= count then
    self.controllerProxy.setWorkAllowed(false)
    event.push("log_warning", "[T7] Not enough "..inertGas.." for craft")
  end
end

---Put super conductor in input hatch
---@private
function t7controller:putSuperConductor()
  local _, result = self.superConductorTransposerProxy.transferFluid(
    self.transposerLiquids["superconductor"].side,
    sides.up,
    self.superconductorCount,
    self.transposerLiquids["superconductor"].tank
  )

  if result ~= self.superconductorCount then
    self.controllerProxy.setWorkAllowed(false)
    event.push("log_warning", "[T7] Not enough superconductor for craft")
  end
end

---Put neutronium in input hatch
---@private
function t7controller:putNeutronium()
  local _, result = self.netroniumTransposerProxy.transferFluid(
    self.transposerLiquids["neutronium"].side,
    sides.up,
    self.neutroniumCount,
    self.transposerLiquids["neutronium"].tank
  )

  if result ~= self.neutroniumCount then
    self.controllerProxy.setWorkAllowed(false)
    event.push("log_warning", "[T7] Not enough neutronium for craft")
  end
end

---Put coolant in input hatch
---@private
function t7controller:putCoolant()
  local _, result = self.coolantTransposerProxy.transferFluid(
    self.transposerLiquids["supercoolant"].side,
    sides.up,
    self.supercoolantCount,
    self.transposerLiquids["supercoolant"].tank
  )

  if result ~= self.supercoolantCount then
    self.controllerProxy.setWorkAllowed(false)
    event.push("log_warning", "[T7] Not enough coolant for craft")
  end
end

return classBuilder.createClass(t7controller, t7controller.constructor, "T7Controller")