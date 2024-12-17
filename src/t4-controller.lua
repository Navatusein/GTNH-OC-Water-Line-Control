local sides = require("sides")
local event = require("event")

local stateMachineLib = require("lib.state-machine-lib")
local componentDiscoverLib = require("lib.component-discover-lib")
local gtSensorParserLib = require("lib.gt-sensor-parser")

---@class T4ControllerConfig
---@field hydrochloricAcidTransposerAddress string
---@field sodiumHydroxideTransposerAddress string

local t4controller = {}

---Crate new T4Controller object from config
---@param config T4ControllerConfig
---@return T4Controller
function t4controller:newFormConfig(config)
  return self:new(config.hydrochloricAcidTransposerAddress, config.sodiumHydroxideTransposerAddress)
end

---Crate new T4Controller object
---@param hydrochloricAcidTransposerAddress string
---@param sodiumHydroxideTransposerAddress string
function t4controller:new(hydrochloricAcidTransposerAddress, sodiumHydroxideTransposerAddress)

  ---@class T4Controller
  local obj = {}

  obj.hydrochloricAcidTransposerProxy = componentDiscoverLib.discoverProxy(
    hydrochloricAcidTransposerAddress,
    "[T4] Hydrochloric Acid Transposer",
    "transposer")
  obj.sodiumHydroxideTransposerProxy = componentDiscoverLib.discoverProxy(
    sodiumHydroxideTransposerAddress,
    "[T4] Sodium Hydroxide Transposer",
    "transposer")
  obj.controllerProxy = nil

  obj.stateMachine = stateMachineLib:new()
  obj.gtSensorParser = nil

  obj.transposerLiquids = {}
  obj.transposerItems = {}

  ---Init T4Controller
  function obj:init()
    self:findMachineProxy()
    self:findTransposerFluid(self.hydrochloricAcidTransposerProxy, "hydrochloricacid_gt5u")
    self:findTransposerItem(self.sodiumHydroxideTransposerProxy, "Sodium Hydroxide Dust")

    self.gtSensorParser:getInformation()

    self.stateMachine.states.idle = self.stateMachine:createState("Idle")
    self.stateMachine.states.idle.update = function()
      if self.controllerProxy.hasWork() then
        self.stateMachine:setState(self.stateMachine.states.work)
      end
    end

    self.stateMachine.states.work = self.stateMachine:createState("Work")
    self.stateMachine.states.work.init = function()
      local phValue = self.gtSensorParser:getNumber(4, "Current pH Value:")
      local diffPh = 7 - tonumber(string.format("%.3f", phValue))
      local count = math.floor(math.abs(diffPh / 0.01))

      if count == 0 then
        self.stateMachine:setState(self.stateMachine.states.waitEnd)
        return
      end

      if diffPh > 0 then
        self:putSodiumHydroxide(count)
      else
        self:putHydrochloricAcid(count)
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
    self.controllerProxy = componentDiscoverLib.discoverGtMachine("multimachine.purificationunitphadjustment")

    if self.controllerProxy == nil then
      error("[T4] pH Neutralization Purification Unit not found")
    end

    self.gtSensorParser = gtSensorParserLib:new(self.controllerProxy)
  end

  ---Find Transposer Item
  ---@param proxy transposer
  ---@param itemLabels string
  function obj:findTransposerItem(proxy, itemLabels)
    local result, skipped = componentDiscoverLib.discoverTransposerItemStorage(proxy, {itemLabels}, {sides.up})

    if #skipped ~= 0 then
      error("[T4] Can't find items: "..table.concat(skipped, ", "))
    end

    for key, value in pairs(result) do
      self.transposerItems[key] = value
    end
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

  ---Put Sodium Hydroxide in input bus
  ---@param count integer
  function obj:putSodiumHydroxide(count) 
    for i = 1, math.ceil(count / 64), 1 do
      local sodiumHydroxideCount = 0

      if (count - 64 * (i - 1) > 64) then
        sodiumHydroxideCount = 64
      else
        sodiumHydroxideCount = math.floor(count % 64)
      end

      local result = self.sodiumHydroxideTransposerProxy.transferItem(
        self.transposerItems["Sodium Hydroxide Dust"].side,
        sides.bottom,
        sodiumHydroxideCount)

      if result ~= sodiumHydroxideCount then
        self.controllerProxy.setWorkAllowed(false)
        event.push("log_warning", "[T4] Not enough Sodium Hydroxide for craft")
        break
      end
    end
  end

  ---Put Hydrochloric Acid in input hatch
  ---@param count integer
  function obj:putHydrochloricAcid(count)
    local hydrochloricAcidCount = count * 10
    local result = self.hydrochloricAcidTransposerProxy.transferFluid(
      self.transposerLiquids["hydrochloricacid_gt5u"].side,
      sides.bottom,
      hydrochloricAcidCount,
      self.transposerLiquids["hydrochloricacid_gt5u"].tank)

    if result == false then
      self.controllerProxy.setWorkAllowed(false)
      event.push("log_warning", "[T4] Not enough Hydrochloric Acid for craft")
    end

    self.gtSensorParser = gtSensorParserLib:new(self.controllerProxy)
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

return t4controller