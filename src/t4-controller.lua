local sides = require("sides")
local event = require("event")
local term = require("term")

local classBuilder = require("lib.class-builder.index")
local componentDiscover = require("lib.component-discover.index")
local stateMachineBuilder = require("lib.state-machine-builder.index")
local gtSensorParser = require("lib.gt-sensor-parser.index")

---@class T4Controller
---@field stateMachine StateMachine
---@field hydrochloricAcidTransposerAddress string
---@field sodiumHydroxideTransposerAddress string
---@field controllerProxy gt_machine
---@field hydrochloricAcidTransposerProxy transposer
---@field sodiumHydroxideTransposerProxy transposer
---@field gtSensorParser GtSensorParser
---@field transposerLiquids table<string, TransposerFluidStorageDescriptor>
---@field transposerItems table<string, TransposerItemStorageDescriptor>
local t4controller = {}

---Constructor
---@param hydrochloricAcidTransposerAddress string
---@param sodiumHydroxideTransposerAddress string
---@return T4Controller
function t4controller:constructor(hydrochloricAcidTransposerAddress, sodiumHydroxideTransposerAddress)
  self.hydrochloricAcidTransposerAddress = hydrochloricAcidTransposerAddress
  self.sodiumHydroxideTransposerAddress = sodiumHydroxideTransposerAddress

  self.transposerLiquids = {}
  self.transposerItems = {}

  self.stateMachine = stateMachineBuilder.stateMachine:new()

  return self
end

---Init
function t4controller:init()
  term.write("Init T4 components: ")
  self:initComponents()
  term.write("ok\n")

  term.write("Init T4 state machine: ")
  self:initStateMachine()
  term.write("ok\n")
end

---Loop
function t4controller:loop()
  self.gtSensorParser:getInformation()
  self.stateMachine:loop()
end

---Get current state
---@return string
function t4controller:getCurrentState()
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
function t4controller:initComponents()
  self.controllerProxy = componentDiscover.gtMachine("multimachine.purificationunitphadjustment")

  if self.controllerProxy == nil then
    error("[T4] pH Neutralization Purification Unit not found")
  end

  self.hydrochloricAcidTransposerProxy = componentDiscover.proxy(
    self.hydrochloricAcidTransposerAddress,
    "transposer",
    "[T4] Hydrochloric Acid Transposer"
  )

  self.sodiumHydroxideTransposerProxy = componentDiscover.proxy(
    self.sodiumHydroxideTransposerAddress,
    "transposer",
    "[T4] Sodium Hydroxide Transposer"
  )

  self.gtSensorParser = gtSensorParser.parser:new(self.controllerProxy)

  self:findTransposerFluid(self.hydrochloricAcidTransposerProxy, {"hydrochloricacid_gt5u"})
  self:findTransposerItem(self.sodiumHydroxideTransposerProxy, {"Sodium Hydroxide Dust"})

  self.gtSensorParser:getInformation()
end

---Init state machine
---@private
function t4controller:initStateMachine()
  self.stateMachine:createState("idle", "Idle", {
    onUpdate = function ()
      if self.controllerProxy.hasWork() == true then
        self.stateMachine:setState("work")
      end
    end
  })

  self.stateMachine:createState("work", "Work", {
    onUpdate = function ()
      local phValue = self.gtSensorParser:getNumber(4)

      if phValue == nil then
        return
      end

      local diffPh = 7 - phValue
      local count = math.floor(math.abs(diffPh / 0.01))

      if count == 0 then
        self.stateMachine:setState("waitEnd")
        return
      end

      if diffPh > 0 then
        self:putSodiumHydroxide(count)
      else
        self:putHydrochloricAcid(count)
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
function t4controller:findTransposerFluid(proxy, fluidNames)
  local result, skipped = componentDiscover.transposerFluidStoragesByNames(proxy, fluidNames, {sides.up})

  if #skipped ~= 0 then
    error("[T4] Can't find liquid: "..table.concat(skipped, ", "))
  end

  for key, value in pairs(result) do
    self.transposerLiquids[key] = value
  end
end

---Find side of transposer with item
---@param proxy transposer
---@param itemLabels string[]
---@private
function t4controller:findTransposerItem(proxy, itemLabels)
  local result, skipped = componentDiscover.transposerItemStoragesByLabels(proxy, itemLabels, {sides.up})

  if #skipped ~= 0 then
    error("[T4] Can't find items: "..table.concat(skipped, ", "))
  end

  for key, value in pairs(result) do
    self.transposerItems[key] = value
  end
end

---Put Sodium Hydroxide in input bus
---@param count integer
---@private
function t4controller:putSodiumHydroxide(count)
  for i = 1, math.ceil(count / 64), 1 do
    local sodiumHydroxideCount = 0

    if count - 64 * (i - 1) > 64 then
      sodiumHydroxideCount = 64
    else
      sodiumHydroxideCount = math.floor(count % 64)
    end

    local result = self.sodiumHydroxideTransposerProxy.transferItem(
      self.transposerItems["Sodium Hydroxide Dust"].side,
      sides.bottom,
      sodiumHydroxideCount
    )

    if result ~= sodiumHydroxideCount then
      self.controllerProxy.setWorkAllowed(false)
      event.push("log_warning", "[T4] Not enough Sodium Hydroxide for craft")
      break
    end
  end
end

---Put Hydrochloric Acid in input hatch
---@param count integer
---@private
function t4controller:putHydrochloricAcid(count)
  local hydrochloricAcidCount = count * 10

  local _, result = self.hydrochloricAcidTransposerProxy.transferFluid(
    self.transposerLiquids["hydrochloricacid_gt5u"].side,
    sides.bottom,
    hydrochloricAcidCount,
    self.transposerLiquids["hydrochloricacid_gt5u"].tank
  )

  if result ~= hydrochloricAcidCount then
    self.controllerProxy.setWorkAllowed(false)
    event.push("log_warning", "[T4] Not enough Hydrochloric Acid for craft")
  end

  self.gtSensorParser = gtSensorParser.parser:new(self.controllerProxy)
end

return classBuilder.createClass(t4controller, t4controller.constructor, "T4Controller")