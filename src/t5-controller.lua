local sides = require("sides")
local event = require("event")
local term = require("term")

local classBuilder = require("lib.class-builder.index")
local componentDiscover = require("lib.component-discover.index")
local stateMachineBuilder = require("lib.state-machine-builder.index")
local gtSensorParser = require("lib.gt-sensor-parser.index")

---@class T5ControllerData
---@field iterations integer

---@class T5Controller
---@field stateMachine StateMachine<T5ControllerData>
---@field plasmaTransposerAddress string
---@field coolantTransposerAddress string
---@field coolantCount integer
---@field plasmaCount integer
---@field controllerProxy gt_machine
---@field plasmaTransposerProxy transposer
---@field coolantTransposerProxy transposer
---@field gtSensorParser GtSensorParser
---@field transposerLiquids table<string, TransposerFluidStorageDescriptor>
local t5controller = {}

---Constructor
---@param plasmaTransposerAddress string
---@param coolantTransposerAddress string
---@return T5Controller
function t5controller:constructor(plasmaTransposerAddress, coolantTransposerAddress)
  self.plasmaTransposerAddress = plasmaTransposerAddress
  self.coolantTransposerAddress = coolantTransposerAddress

  self.coolantCount = 2000
  self.plasmaCount = 100

  self.transposerLiquids = {}

  self.stateMachine = stateMachineBuilder.stateMachine:new()

  return self
end

---Init
function t5controller:init()
  term.write("Init T5 components: ")
  self:initComponents()
  term.write("ok\n")

  term.write("Init T5 state machine: ")
  self:initStateMachine()
  term.write("ok\n")
end

---Loop
function t5controller:loop()
  self.gtSensorParser:getInformation()
  self.stateMachine:loop()
end

---Get current state
---@return string
function t5controller:getCurrentState()
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
function t5controller:initComponents()
  self.controllerProxy = componentDiscover.gtMachine("multimachine.purificationunitplasmaheater")

  if self.controllerProxy == nil then
    error("[T5] Extreme Temperature Fluctuation Purification Unit not found")
  end

  self.plasmaTransposerProxy = componentDiscover.proxy(self.plasmaTransposerAddress, "transposer", "[T5] Plasma Transposer")
  self.coolantTransposerProxy = componentDiscover.proxy(self.coolantTransposerAddress, "transposer", "[T5] Coolant Transposer")

  self.gtSensorParser = gtSensorParser.parser:new(self.controllerProxy)

  self:findTransposerFluid(self.plasmaTransposerProxy, {"plasma.helium"})
  self:findTransposerFluid(self.coolantTransposerProxy, {"supercoolant"})

  self.gtSensorParser:getInformation()
end

---Init state machine
---@private
function t5controller:initStateMachine()
  self.stateMachine.data.iterations = 0

  self.stateMachine:createState("idle", "Idle", {
    onInit = function ()
      local temperature = self.gtSensorParser:getNumber(4)

      if self.controllerProxy.hasWork() == true and temperature ~= nil and temperature ~= 0 then
        self.stateMachine:setState("waitEnd")
      end
    end,
    onUpdate = function ()
      if self.controllerProxy.getWorkProgress() > 900 then
        self.stateMachine:setState("waitEnd")
        return
      end

      if self.controllerProxy.hasWork() == true then
        self.stateMachine.data.iterations = 0
        self.stateMachine:setState("heating")
      end
    end
  })

  self.stateMachine:createState("heating", "Heating", {
    onInit = function ()
      if self.stateMachine.data.iterations >= 2 then
        self.stateMachine:setState("waitEnd")
        return
      end

      self:putPlasma()
    end,
    onUpdate = function ()
      if self.controllerProxy.hasWork() == false then
        self.stateMachine:setState("idle")
        return
      end

      local temperature = self.gtSensorParser:getNumber(4)

      if temperature == nil then
        return
      end

      if temperature >= 10000 then
        self.stateMachine:setState("cooling")
      end
    end
  })

  self.stateMachine:createState("cooling", "Cooling", {
    onInit = function ()
      self:putCoolant()
    end,
    onUpdate = function ()
      if self.controllerProxy.hasWork() == false then
        self.stateMachine:setState("idle")
        return
      end

      local temperature = self.gtSensorParser:getNumber(4)

      if temperature == nil then
        return
      end

      if temperature <= 0 then
        self.stateMachine:setState("heating")
        self.stateMachine.data.iterations = self.stateMachine.data.iterations + 1
      end
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
function t5controller:findTransposerFluid(proxy, fluidNames)
  local result, skipped = componentDiscover.transposerFluidStoragesByNames(proxy, fluidNames, {sides.up})

  if #skipped ~= 0 then
    error("[T5] Can't find liquid: "..table.concat(skipped, ", "))
  end

  for key, value in pairs(result) do
    self.transposerLiquids[key] = value
  end
end

---Put Helium Plasma in input hatch
---@private
function t5controller:putPlasma()
  local _, result = self.plasmaTransposerProxy.transferFluid(
    self.transposerLiquids["plasma.helium"].side,
    sides.up,
    self.plasmaCount,
    self.transposerLiquids["plasma.helium"].tank
  )

  if result ~= self.plasmaCount then
    self.controllerProxy.setWorkAllowed(false)
    event.push("log_warning", "[T5] Not enough Helium Plasma for craft")
  end
end

---Put Super Coolant in input hatch
---@private
function t5controller:putCoolant()
  local _, result = self.coolantTransposerProxy.transferFluid(
    self.transposerLiquids["supercoolant"].side,
    sides.up,
    self.coolantCount,
    self.transposerLiquids["supercoolant"].tank
  )

  if result ~= self.coolantCount then
    self.controllerProxy.setWorkAllowed(false)
    event.push("log_warning", "[T5] Not enough Super Coolant for craft")
  end
end

return classBuilder.createClass(t5controller, t5controller.constructor, "T5Controller")