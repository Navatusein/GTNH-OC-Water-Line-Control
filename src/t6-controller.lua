local sides = require("sides")
local event = require("event")
local term = require("term")

local classBuilder = require("lib.class-builder.index")
local componentDiscover = require("lib.component-discover.index")
local stateMachineBuilder = require("lib.state-machine-builder.index")
local gtSensorParser = require("lib.gt-sensor-parser.index")

---@class T6ControllerData
---@field currentLens? string

---@class T6Controller
---@field stateMachine StateMachine<T6ControllerData>
---@field transposerAddress string
---@field controllerProxy gt_machine
---@field transposerProxy transposer
---@field gtSensorParser GtSensorParser
---@field transposerItems table<string, TransposerItemStorageDescriptor>
local t6controller = {}

---Constructor
---@param transposerAddress string
---@return T6Controller
function t6controller:constructor(transposerAddress)
  self.transposerAddress = transposerAddress

  self.transposerItems = {}

  self.stateMachine = stateMachineBuilder.stateMachine:new()

  return self
end

---Init
function t6controller:init()
  term.write("Init T6 components: ")
  self:initComponents()
  term.write("ok\n")

  term.write("Init T6 state machine: ")
  self:initStateMachine()
  term.write("ok\n")
end

---Loop
function t6controller:loop()
  self.gtSensorParser:getInformation()
  self.stateMachine:loop()
end

---Get current state
---@return string
function t6controller:getCurrentState()
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
function t6controller:initComponents()
  self.controllerProxy = componentDiscover.gtMachine("multimachine.purificationunituvtreatment")

  if self.controllerProxy == nil then
    error("[T6] High Energy Laser Purification Unit not found")
  end

  self.transposerProxy = componentDiscover.proxy(self.transposerAddress, "transposer", "[T6] Transposer")
  self.gtSensorParser = gtSensorParser.parser:new(self.controllerProxy)

  self:resetLenses()
  self:findTransposerItem(self.transposerProxy, {
    "Orundum Lens",
    "Amber Lens",
    "Aer Lens",
    "Emerald Lens",
    "Mana Diamond Lens",
    "Blue Topaz Lens",
    "Amethyst Lens",
    "Fluor-Buergerite Lens",
    "Dilithium Lens"
  })

  self.gtSensorParser:getInformation()
end

---Init state machine
---@private
function t6controller:initStateMachine()
  self.stateMachine:createState("idle", "Idle", {
    onInit = function ()
      self:takeLens()
    end,
    onUpdate = function ()
      if self.controllerProxy.hasWork() == true then
        self.stateMachine:setState("changeLens")
      end
    end
  })

  self.stateMachine:createState("changeLens", "Change Lens", {
    onInit = function ()
      local lens = self.gtSensorParser:getString(5)
      local recipeError = self.gtSensorParser:getString(6)

      if lens == nil or recipeError == "Removed lens too early. Failing this recipe." then
        self.stateMachine:setState("waitEnd")
        return
      end

      self:putLens(lens)
    end
  })

  self.stateMachine:createState("waitLens", "Wait Lens", {
    onUpdate = function ()
      local lens = self.gtSensorParser:getString(5)

      if self.controllerProxy.hasWork() == false then
        self.stateMachine:setState("idle")
        return
      end

      if self.stateMachine.data.currentLens ~= lens then
        self.stateMachine:setState("changeLens")
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

---Find side of transposer with item
---@param proxy transposer
---@param itemLabels string[]
---@private
function t6controller:findTransposerItem(proxy, itemLabels)
  local result, skipped = componentDiscover.transposerItemStoragesByLabels(proxy, itemLabels)

  if #skipped ~= 0 then
    if #skipped ~= 1 or skipped[1] ~= "Dilithium Lens" then
      error("[T6] Can't find items: "..table.concat(skipped, ", "))
    end
  end

  for key, value in pairs(result) do
    self.transposerItems[key] = value
  end
end

---Reset lens from bus before init
---@private
function t6controller:resetLenses()
  local transposerSides = componentDiscover.transposerItemStorages(self.transposerProxy, {sides.bottom})

  if transposerSides[1] ~= nil then
    self.transposerProxy.transferItem(sides.bottom, transposerSides[1], 1)
  end
end

---Take current lens from input bus
---@private
function t6controller:takeLens()
  if self.stateMachine.data.currentLens == nil then
    return
  end

  self.transposerProxy.transferItem(
    sides.bottom,
    self.transposerItems[self.stateMachine.data.currentLens].side,
    1,
    1,
    self.transposerItems[self.stateMachine.data.currentLens].slot
  )
end

---Put required lens to input bus
---@param lens string
---@private
function t6controller:putLens(lens)
  self:takeLens()

  if lens == "Dilithium Lens" and self.transposerItems[lens] == nil then
    self.stateMachine.data.currentLens = nil
    self.stateMachine:setState("waitEnd")
    return
  end

  local result = self.transposerProxy.transferItem(
    self.transposerItems[lens].side,
    sides.bottom,
    1,
    self.transposerItems[lens].slot
  )

  if result ~= 1 then
    self.controllerProxy.setWorkAllowed(false)
    self.stateMachine.data.currentLens = nil
    self.stateMachine:setState("waitEnd")
    event.push("log_warning", "[T6] Invalid slot: "..self.transposerItems[lens].slot.." for: "..lens)
    return
  end

  self.stateMachine.data.currentLens = lens

  if lens == "Dilithium Lens" then
    self.stateMachine:setState("waitEnd")
  else
    self.stateMachine:setState("waitLens")
  end
end

return classBuilder.createClass(t6controller, t6controller.constructor, "T6Controller")