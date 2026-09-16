local sides = require("sides")
local event = require("event")
local term = require("term")

local classBuilder = require("lib.class-builder.index")
local componentDiscover = require("lib.component-discover.index")
local stateMachineBuilder = require("lib.state-machine-builder.index")
local gtSensorParser = require("lib.gt-sensor-parser.index")

---@class T3Controller
---@field stateMachine StateMachine
---@field transposerAddress string
---@field requiredCount integer
---@field controllerProxy gt_machine
---@field transposerProxy transposer
---@field gtSensorParser GtSensorParser
---@field transposerLiquids table<string, TransposerFluidStorageDescriptor>
local t3controller = {}

---Constructor
---@param transposerAddress string
---@return T3Controller
function t3controller:constructor(transposerAddress)
  self.transposerAddress = transposerAddress

  self.requiredCount = 900000

  self.transposerLiquids = {}

  self.stateMachine = stateMachineBuilder.stateMachine:new()

  return self
end

---Init
function t3controller:init()
  term.write("Init T3 components: ")
  self:initComponents()
  term.write("ok\n")

  term.write("Init T3 state machine: ")
  self:initStateMachine()
  term.write("ok\n")
end

---Loop
function t3controller:loop()
  self.gtSensorParser:getInformation()
  self.stateMachine:loop()
end

---Get current state
---@return string
function t3controller:getCurrentState()
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
function t3controller:initComponents()
  self.controllerProxy = componentDiscover.gtMachine("multimachine.purificationunitflocculator")

  if self.controllerProxy == nil then
    error("[T3] Flocculation Purification Unit not found")
  end

  self.transposerProxy = componentDiscover.proxy(self.transposerAddress, "transposer", "[T3] Transposer")
  self.gtSensorParser = gtSensorParser.parser:new(self.controllerProxy)

  self:findTransposerFluid(self.transposerProxy, {"polyaluminiumchloride"})
end

---Init state machine
---@private
function t3controller:initStateMachine()
  self.stateMachine:createState("idle", "Idle", {
    onUpdate = function ()
      if self.controllerProxy.hasWork() == true then
        self.stateMachine:setState("work")
      end
    end
  })

  self.stateMachine:createState("work", "Work", {
    onInit = function ()
      local currentCount = self.gtSensorParser:getNumber(4)

      if currentCount ~= nil and currentCount >= self.requiredCount then
        self.stateMachine:setState("waitEnd")
        return
      end

      local fluidInTank = self.transposerProxy.getFluidInTank(
        self.transposerLiquids["polyaluminiumchloride"].side,
        self.transposerLiquids["polyaluminiumchloride"].tank
      )

      local countToAdd = self.requiredCount

      if fluidInTank.amount < self.requiredCount then
        self.controllerProxy.setWorkAllowed(false)
        event.push("log_warning", "[T3] Not enough Polyaluminium Chloride for craft")

        countToAdd = fluidInTank.amount - (fluidInTank.amount % 100000)
      end

      local _, result = self.transposerProxy.transferFluid(
        self.transposerLiquids["polyaluminiumchloride"].side,
        sides.up,
        countToAdd,
        self.transposerLiquids["polyaluminiumchloride"].tank
      )

      if result ~= countToAdd then
        event.push("log_warning", "[T3] Fluid transfer error")
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
function t3controller:findTransposerFluid(proxy, fluidNames)
  local result, skipped = componentDiscover.transposerFluidStoragesByNames(proxy, fluidNames, {sides.up})

  if #skipped ~= 0 then
    error("[T3] Can't find liquid: "..table.concat(skipped, ", "))
  end

  for key, value in pairs(result) do
    self.transposerLiquids[key] = value
  end
end

return classBuilder.createClass(t3controller, t3controller.constructor, "T3Controller")