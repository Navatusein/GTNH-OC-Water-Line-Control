local loggerLib = require("lib.logger-lib")
local discordLoggerHandler = require("lib.logger-handler.discord-logger-handler-lib")
local fileLoggerHandler = require("lib.logger-handler.file-logger-handler-lib")
local scrollListLoggerHandler = require("lib.logger-handler.scroll-list-logger-handler-lib")

local lineControllerLib = require("src.line-controller")

local t3controllerLib = require("src.t3-controller")
local t4controllerLib = require("src.t4-controller")
local t5controllerLib = require("src.t5-controller")
local t6controllerLib = require("src.t6-controller")
local t7controllerLib = require("src.t7-controller")
local t8controllerLib = require("src.t8-controller")

local config = {
  logger = loggerLib:newFormConfig({
    name = "Water Line Control",
    timeZone = 3, -- Your time zone
    handlers = {
      discordLoggerHandler:newFormConfig({
        logLevel = "warning",
        messageFormat = "{Time:%d.%m.%Y %H:%M:%S} [{LogLevel}]: {Message}",
        discordWebhookUrl = "" -- Discord Webhook URL
      }),
      fileLoggerHandler:newFormConfig({
        logLevel = "debug",
        messageFormat = "{Time:%d.%m.%Y %H:%M:%S} [{LogLevel}]: {Message}",
        filePath = "logs.log"
      }),
      scrollListLoggerHandler:newFormConfig({
        logLevel = "debug",
        logsListSize = 32
      }),
    }
  }),

  lineController = lineControllerLib:newFormConfig(),

  controllers = {
    t3 = { -- Controller for T3 Flocculated Water (Grade 3)
      enable = false, -- Enable module for T3 water
      controller = t3controllerLib:newFormConfig({
        transposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", -- Address of transposer which provide Polyaluminium Chloride
      }),
    },

    t4 = { -- Controller for T4 pH Neutralized Water (Grade 4)
      enable = false, -- Enable module for T4 water
      controller = t4controllerLib:newFormConfig({
        hydrochloricAcidTransposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", -- Address of transposer which provide Hydrochloric Acid
        sodiumHydroxideTransposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" -- Address of transposer which provide Sodium Hydroxide Dust
      }),
    },

    t5 = { -- Controller for T5 Extreme-Temperature Treated Water (Grade 5)
      enable = false, -- Enable module for T5 water
      controller = t5controllerLib:newFormConfig({
        plasmaTransposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", -- Address of transposer which provide Helium Plasma
        coolantTransposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" -- Address of transposer which provide Super Coolant
      }),
    },

    t6 = { -- Controller for T6 Ultraviolet Treated Electrically Neutral Water (Grade 6)
      enable = false, -- Enable module for T6 water
      controller = t6controllerLib:newFormConfig({
        transposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" -- Address of transposer which provide Lenses
      }),
    },

    t7 = { -- Controller for T7 Degassed Decontaminant-Free Water (Grade 7)
      enable = false, -- Enable module for T7 water
      controller = t7controllerLib:newFormConfig({
        inertGasTransposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", -- Address of transposer which provide Inert Gas
        superConductorTransposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", -- Address of transposer which provide Super Conductor
        netroniumTransposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", -- Address of transposer which provide Molten Neutronium
        coolantTransposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" -- Address of transposer which provide Super Coolant
      }),
    },

    t8 = { -- Controller for T8 Subatomically Perfect Water (Grade 8)
      enable = false, -- Enable module for T8 water
      controller = t8controllerLib:newFormConfig({
        maxQuarkCount = 4, -- Maximum number of each quark in the sub AE
        transposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", -- Address of transposer which provide Quarks
        subMeInterfaceAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" -- Address of me interface which connected to sub AE
      })
    }
  }
}

return config