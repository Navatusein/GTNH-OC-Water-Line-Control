local keyboard = require("keyboard")

local programLib = require("lib.program-lib")
local guiLib = require("lib.gui-lib")

local scrollList = require("lib.gui-widgets.scroll-list")

package.loaded.config = nil
local config = require("config")

local version = require("version")

local repository = "Navatusein/GTNH-OC-Water-Line-Control"
local archiveName = "WaterLineControl"

local program = programLib:new(config.logger, config.enableAutoUpdate, version, repository, archiveName)
local gui = guiLib:new(program)

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
    logsScrollList = scrollList:new("logsScrollList", "logs", keyboard.keys.up, keyboard.keys.down)
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

local controllersStates = {
  ["t3"] = config.controllers.t3.enable and "Loading" or "Unused",
  ["t4"] = config.controllers.t4.enable and "Loading" or "Unused",
  ["t5"] = config.controllers.t5.enable and "Loading" or "Unused",
  ["t6"] = config.controllers.t6.enable and "Loading" or "Unused",
  ["t7"] = config.controllers.t7.enable and "Loading" or "Unused",
  ["t8"] = config.controllers.t8.enable and "Loading" or "Unused",
}

local function init()
  gui:setTemplate(mainTemplate)
end

local function initControllers()
  os.sleep(0.5)
  config.lineController:init()

  for i = 3, 8, 1 do
    local key = "t"..i

    if config.controllers[key].enable then
      config.controllers[key].controller:init()
    end
  end
end

local function loop()
  initControllers()

  while true do
    config.lineController:loop()

    for i = 3, 8, 1 do
      local key = "t"..i

      if config.controllers[key].enable then
        config.controllers[key].controller:loop()
        controllersStates[key] = config.controllers[key].controller:getState()
      end

      os.sleep(0.1)
    end

    os.sleep(1)
  end
end

local function guiLoop()
  gui:render({
    lineState = config.lineController:getState(),
    t3state = controllersStates["t3"],
    t4state = controllersStates["t4"],
    t5state = controllersStates["t5"],
    t6state = controllersStates["t6"],
    t7state = controllersStates["t7"],
    t8state = controllersStates["t8"],
    logs = config.logger.handlers[3]["logs"].list
  })
end

program:registerLogo(logo)
program:registerInit(init)
program:registerThread(loop)
program:registerTimer(guiLoop, math.huge)
program:start()