local term = require("term")
local keyboard = require("keyboard")

local configManager = require("lib.config-manager.index")
local programController = require("lib.program-controller.index")
local simpleGui = require("lib.simple-gui.index")

local configTemplate = require("src.config-template")
local lineControllerClass = require("src.line-controller")
local scrollList = require("src.gui-widgets.scroll-list")

package.loaded.config = nil
local config = require("config")
local version = require("version")

---@type Config
local config = configManager.manager:new(configTemplate):build(config)

local repository = "Navatusein/GTNH-OC-Water-Line-Control"
local archiveName = "WaterLineControl"

local program = programController.program:new(config.enableAutoUpdate, version, repository, archiveName)
local gui = simpleGui.gui:new(program)

local lineController = lineControllerClass:new()

local logo = {
  "__        __    _              _     _               ____            _             _ ",
  "\\ \\      / /_ _| |_ ___ _ __  | |   (_)_ __   ___   / ___|___  _ __ | |_ _ __ ___ | |",
  " \\ \\ /\\ / / _` | __/ _ \\ '__| | |   | | '_ \\ / _ \\ | |   / _ \\| '_ \\| __| '__/ _ \\| |",
  "  \\ V  V / (_| | ||  __/ |    | |___| | | | |  __/ | |__| (_) | | | | |_| | | (_) | |",
  "   \\_/\\_/ \\__,_|\\__\\___|_|    |_____|_|_| |_|\\___|  \\____\\___/|_| |_|\\__|_|  \\___/|_|"
}

local mainTemplate = {
  width = 60,
  background = gui.palette.black,
  foreground = gui.palette.white,
  widgets = {
    logsScrollList = scrollList:new("logs", keyboard.keys.up, keyboard.keys.down)
  },
  lines = {
    "Line State: $lineState$",
    "",
    "T3: $t3state$",
    "T4: $t4state$",
    "T5: $t5state$",
    "T6: $t6state$",
    "T7: $t7state$",
    "T8: $t8state$",
    "",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#"
  }
}

local controllersStates = {}

for i = 3, 8, 1 do
  local key = "t"..i

  if config.controllers[key] ~= nil then
    controllersStates[key] = "Loading"
  else
    controllersStates[key] = "Unused"
  end
end

local function init()
  gui:setTemplate(mainTemplate)

  term.clear()

  lineController:init()

  for i = 3, 8, 1 do
    local key = "t"..i

    if config.controllers[key] ~= nil then
      config.controllers[key]:init()
    end
  end
end

local function loop()
  while true do
    lineController:loop()

    for i = 3, 8, 1 do
      local key = "t"..i

      if config.controllers[key] ~= nil then
        config.controllers[key]:loop()
        controllersStates[key] = config.controllers[key]:getCurrentState()
      end

      os.sleep(0.1)
    end

    os.sleep(1)
  end
end

local function guiLoop()
  gui:render({
    lineState = lineController:getCurrentState(),
    t3state = controllersStates["t3"],
    t4state = controllersStates["t4"],
    t5state = controllersStates["t5"],
    t6state = controllersStates["t6"],
    t7state = controllersStates["t7"],
    t8state = controllersStates["t8"],
    logs = config.logger.handlers["scrollList"]:getLogs()
  })
end

local function onExit()
  lineController:disable()
end

program:registerLogo(logo)
program:registerOnInit(init)
program:registerOnExit(onExit)
program:registerThread(loop)
program:registerTimer(guiLoop, math.huge, 1)
program:start()