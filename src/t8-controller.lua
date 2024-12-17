local sides = require("sides")
local event = require("event")

local stateMachineLib = require("lib.state-machine-lib")
local componentDiscoverLib = require("lib.component-discover-lib")
local gtSensorParserLib = require("lib.gt-sensor-parser")

---@class T8ControllerConfig
---@field maxQuarkCount integer
---@field transposerAddress string
---@field subMeInterfaceAddress string

local t8controller = {}

---Crate new T8Controller object from config
---@param config T8ControllerConfig
---@return T8Controller
function t8controller:newFormConfig(config)
  return self:new(config.maxQuarkCount, config.transposerAddress, config.subMeInterfaceAddress)
end

---Crate new T8Controller object
---@param maxQuarkCount integer
---@param transposerAddress string
---@param subMeInterfaceAddress string
function t8controller:new(maxQuarkCount, transposerAddress, subMeInterfaceAddress)

  ---@class T8Controller
  local obj = {}

  obj.maxQuarkCount = maxQuarkCount

  obj.transposerProxy = nil
  obj.subMeInterfaceProxy = nil
  obj.controllerProxy = nil

  obj.stateMachine = stateMachineLib:new()
  obj.gtSensorParser = nil

  ---@type TransposerItemStorageDescriptor[]
  obj.transposerItems = {}

  ---Init T8Controller
  function obj:init()
    self:findMachineProxy()
    self:findTransposerItem(self.transposerProxy, {
      "Up-Quark Releasing Catalyst",
      "Down-Quark Releasing Catalyst",
      "Strange-Quark Releasing Catalyst",
      "Charm-Quark Releasing Catalyst",
      "Bottom-Quark Releasing Catalyst",
      "Top-Quark Releasing Catalyst"
    })

    self.gtSensorParser:getInformation()

    self.stateMachine.states.idle = self.stateMachine:createState("Idle")
    self.stateMachine.states.idle.update = function()
      if self.controllerProxy.hasWork() then
        if self.gtSensorParser:stringHas(#self.gtSensorParser.sensorData, "Yes") == true then
          self.stateMachine:setState(self.stateMachine.states.waitEnd)
        else
          self.stateMachine:setState(self.stateMachine.states.putFirst)
        end
      end
    end

    self.stateMachine.states.putFirst = self.stateMachine:createState("Put First")
    self.stateMachine.states.putFirst.init = function()
      self:putQuarks(1)
      self.stateMachine:setState(self.stateMachine.states.resultPutFirst)
    end

    self.stateMachine.states.resultPutFirst = self.stateMachine:createState("Result Put First")
    self.stateMachine.states.resultPutFirst.update = function()
      if self.gtSensorParser:stringHas(#self.gtSensorParser.sensorData, "Yes") == true then
        self.stateMachine:setState(self.stateMachine.states.waitEnd)
      else
        self.stateMachine:setState(self.stateMachine.states.putSecond)
      end
    end

    self.stateMachine.states.putSecond = self.stateMachine:createState("Put Second")
    self.stateMachine.states.putSecond.init = function()
      self:putQuarks(2)
      self.stateMachine:setState(self.stateMachine.states.resultPutSecond)
    end

    self.stateMachine.states.resultPutSecond = self.stateMachine:createState("Result Put Second")
    self.stateMachine.states.resultPutSecond.update = function()
      if self.gtSensorParser:stringHas(#self.gtSensorParser.sensorData, "Yes") == true then
        self.stateMachine:setState(self.stateMachine.states.waitEnd)
      else
        self.stateMachine:setState(self.stateMachine.states.putThird)
      end
    end

    self.stateMachine.states.putThird = self.stateMachine:createState("Put Third")
    self.stateMachine.states.putThird.init = function()
      self:putQuarks(3)
      self.stateMachine:setState(self.stateMachine.states.waitEnd)
    end

    self.stateMachine.states.waitEnd = self.stateMachine:createState("Wait End")

    self.stateMachine.states.craftQuarks = self.stateMachine:createState("Craft Quarks")
    self.stateMachine.states.craftQuarks.init = function()
      os.sleep(1)

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

      self.stateMachine:setState(self.stateMachine.states.idle)
    end

    event.listen("cycle_end", function ()
      if self.stateMachine.currentState == self.stateMachine.states.waitEnd then
        self.stateMachine:setState(self.stateMachine.states.craftQuarks)
      end
    end)

    self.stateMachine:setState(self.stateMachine.states.idle)
  end

  ---Find controller proxy
  function obj:findMachineProxy()
    self.controllerProxy = componentDiscoverLib.discoverGtMachine("multimachine.purificationunitextractor")

    if self.controllerProxy == nil then
      error("[T8] Absolute Baryonic Perfection Purification Unit not found")
    end

    self.transposerProxy = componentDiscoverLib.discoverProxy(
      transposerAddress,
      "[T8] Transposer",
      "transposer")
    self.subMeInterfaceProxy = componentDiscoverLib.discoverProxy(
      subMeInterfaceAddress,
      "[T8] Sub Me Interface",
      "me_interface")
    self.gtSensorParser = gtSensorParserLib:new(self.controllerProxy)
  end

  ---Find Transposer Item
  ---@param proxy transposer
  ---@param itemLabels string[]
  function obj:findTransposerItem(proxy, itemLabels)
    local result, skipped = componentDiscoverLib.discoverTransposerItemStorage(proxy, itemLabels, {sides.up})

    if #skipped ~= 0 then
      error("[T8] Can't find items: "..table.concat(skipped, ", "))
    end

    for key, value in pairs(result) do
      self.transposerItems[key] = value
    end
  end

  ---Put quarks in input bus
  ---@param index 1|2|3
  function obj:putQuarks(index)
    local drops = {
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

    self.stateMachine.data.lastPut = index

    for i = 1, 6, 1 do
      local transfered = self.transposerProxy.transferItem(
        self.transposerItems[drops[index][i]].side,
        sides.up,
        1,
        self.transposerItems[drops[index][i]].slot)

      if transfered == 0 then
        self.controllerProxy.setWorkAllowed(false)
        event.push("log_warning", "[T8] Not enough quarks on slot: "..drops[index][i])
      end
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

return t8controller