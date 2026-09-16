local sides = require("sides")
local event = require("event")
local term = require("term")

local classBuilder = require("lib.class-builder.index")
local componentDiscover = require("lib.component-discover.index")
local stateMachineBuilder = require("lib.state-machine-builder.index")
local gtSensorParser = require("lib.gt-sensor-parser.index")

---@class T8ControllerData
---@field lastPut? integer

---@class T8Controller
---@field stateMachine StateMachine<T8ControllerData>
---@field maxQuarkCount integer
---@field transposerAddress string
---@field subMeInterfaceAddress string
---@field drops string[][]
---@field controllerProxy gt_machine
---@field transposerProxy transposer
---@field subMeInterfaceProxy me_interface
---@field gtSensorParser GtSensorParser
---@field transposerItems table<string, TransposerItemStorageDescriptor>
local t8controller = {}

---Constructor
---@param maxQuarkCount integer
---@param transposerAddress string
---@param subMeInterfaceAddress string
---@return T8Controller
function t8controller:constructor(maxQuarkCount, transposerAddress, subMeInterfaceAddress)
  self.maxQuarkCount = maxQuarkCount
  self.transposerAddress = transposerAddress
  self.subMeInterfaceAddress = subMeInterfaceAddress

  self.drops = {
    {
      "Up-Quark Releasing Catalyst",
      "Down-Quark Releasing Catalyst",
      "Strange-Quark Releasing Catalyst",
      "Charm-Quark Releasing Catalyst",
      "Bottom-Quark Releasing Catalyst",
      "Top-Quark Releasing Catalyst"
    },
    {
      "Up-Quark Releasing Catalyst",
      "Strange-Quark Releasing Catalyst",
      "Bottom-Quark Releasing Catalyst",
      "Down-Quark Releasing Catalyst",
      "Top-Quark Releasing Catalyst",
      "Charm-Quark Releasing Catalyst"
    },
    {
      "Up-Quark Releasing Catalyst",
      "Bottom-Quark Releasing Catalyst",
      "Down-Quark Releasing Catalyst",
      "Charm-Quark Releasing Catalyst",
      "Strange-Quark Releasing Catalyst",
      "Top-Quark Releasing Catalyst"
    }
  }

  self.transposerItems = {}

  self.stateMachine = stateMachineBuilder.stateMachine:new()

  return self
end

---Init
function t8controller:init()
  term.write("Init T8 components: ")
  self:initComponents()
  term.write("ok\n")

  term.write("Init T8 state machine: ")
  self:initStateMachine()
  term.write("ok\n")
end

---Loop
function t8controller:loop()
  self.gtSensorParser:getInformation()
  self.stateMachine:loop()
end

---Get current state
---@return string
function t8controller:getCurrentState()
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
function t8controller:initComponents()
  self.controllerProxy = componentDiscover.gtMachine("multimachine.purificationunitextractor")

  if self.controllerProxy == nil then
    error("[T8] Absolute Baryonic Perfection Purification Unit not found")
  end

  self.transposerProxy = componentDiscover.proxy(self.transposerAddress, "transposer", "[T8] Transposer")
  self.subMeInterfaceProxy = componentDiscover.proxy(self.subMeInterfaceAddress, "me_interface", "[T8] Sub Me Interface")

  self.gtSensorParser = gtSensorParser.parser:new(self.controllerProxy)

  self:findTransposerItem(self.transposerProxy, {
    "Up-Quark Releasing Catalyst",
    "Down-Quark Releasing Catalyst",
    "Strange-Quark Releasing Catalyst",
    "Charm-Quark Releasing Catalyst",
    "Bottom-Quark Releasing Catalyst",
    "Top-Quark Releasing Catalyst"
  })

  self.gtSensorParser:getInformation()
end

---Init state machine
---@private
function t8controller:initStateMachine()
  self.stateMachine:createState("idle", "Idle", {
    onUpdate = function ()
      if self.controllerProxy.hasWork() == true then
        if self.gtSensorParser:stringHas(#self.gtSensorParser.sensorData, false, "Yes") == true then
          self.stateMachine:setState("waitEnd")
        else
          self.stateMachine:setState("putFirst")
        end
      end
    end
  })

  self.stateMachine:createState("putFirst", "Put First", {
    onInit = function ()
      self:putQuarks(1)
      self.stateMachine:setState("resultPutFirst")
    end
  })

  self.stateMachine:createState("resultPutFirst", "Result Put First", {
    onUpdate = function ()
      if self.gtSensorParser:stringHas(#self.gtSensorParser.sensorData, false, "Yes") == true then
        self.stateMachine:setState("waitEnd")
      else
        self.stateMachine:setState("putSecond")
      end
    end
  })

  self.stateMachine:createState("putSecond", "Put Second", {
    onInit = function ()
      self:putQuarks(2)
      self.stateMachine:setState("resultPutSecond")
    end
  })

  self.stateMachine:createState("resultPutSecond", "Result Put Second", {
    onUpdate = function ()
      if self.gtSensorParser:stringHas(#self.gtSensorParser.sensorData, false, "Yes") == true then
        self.stateMachine:setState("waitEnd")
      else
        self.stateMachine:setState("putThird")
      end
    end
  })

  self.stateMachine:createState("putThird", "Put Third", {
    onInit = function ()
      self:putQuarks(3)
      self.stateMachine:setState("waitEnd")
    end
  })

  self.stateMachine:createState("waitEnd", "Wait End")

  self.stateMachine:createState("craftQuarks", "Craft Quarks", {
    onInit = function ()
      os.sleep(3)

      self:craftQuarks()

      self.stateMachine:setState("idle")
    end
  })

  event.listen("cycle_end", function ()
    if self.stateMachine:getCurrentStateKey() == "waitEnd" then
      self.stateMachine:setState("craftQuarks")
    end
  end)

  self.stateMachine:setState("idle")
end

---Find side of transposer with item
---@param proxy transposer
---@param itemLabels string[]
---@private
function t8controller:findTransposerItem(proxy, itemLabels)
  local result, skipped = componentDiscover.transposerItemStoragesByLabels(proxy, itemLabels, {sides.up})

  if #skipped ~= 0 then
    error("[T8] Can't find items: "..table.concat(skipped, ", "))
  end

  for key, value in pairs(result) do
    self.transposerItems[key] = value
  end
end

---Put quarks in input bus
---@param index 1|2|3
---@private
function t8controller:putQuarks(index)
  self.stateMachine.data.lastPut = index

  for i = 1, 6, 1 do
    local transfered = self.transposerProxy.transferItem(
      self.transposerItems[self.drops[index][i]].side,
      sides.up,
      1,
      self.transposerItems[self.drops[index][i]].slot
    )

    if transfered == 0 then
      self.controllerProxy.setWorkAllowed(false)
      event.push("log_warning", "[T8] Not enough quarks on slot: "..self.drops[index][i])
    end
  end
end

---Request craft of missing quarks
---@private
function t8controller:craftQuarks()
  local quarks = self.subMeInterfaceProxy.getItemsInNetwork({name = "gregtech:gt.metaitem.03"})

  for _, quark in pairs(quarks) do
    if quark.label ~= "Unaligned Quark Releasing Catalyst" and quark.size < self.maxQuarkCount then
      local crafts = self.subMeInterfaceProxy.getCraftables({label = quark.label})

      if crafts[1] == nil then
        event.push("log_warning", "[T8] No craft for: "..quark.label)
        self.controllerProxy.setWorkAllowed(false)
        break
      end

      crafts[1].request(self.maxQuarkCount - quark.size)
    end
  end
end

return classBuilder.createClass(t8controller, t8controller.constructor, "T8Controller")