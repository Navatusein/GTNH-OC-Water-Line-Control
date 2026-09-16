local config = {
  enableAutoUpdate = true, -- Enable auto update on start

  logger = {
    name = "Water Line Control",
    timeZone = 3, -- Your time zone
    handlers = {
      ["discord"] = {
        type = "discord",
        logLevel = "warning",
        messageFormat = "{Time:%d.%m.%Y %H:%M:%S} [{LogLevel}]: {Message}",
        discordWebhookUrl = "" -- Discord Webhook URL
      },
      ["file"] = {
        type = "file",
        logLevel = "debug",
        messageFormat = "{Time:%d.%m.%Y %H:%M:%S} [{LogLevel}]: {Message}",
        filePath = "logs.log"
      },
      ["scrollList"] = {
        type = "scrollList",
        logLevel = "debug",
        logsListSize = 32
      },
    }
  },

  controllers = {
    t3 = { -- Controller for T3 Flocculated Water (Grade 3)
      enable = false, -- Enable module for T3 water
      transposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" -- Address of transposer which provide Polyaluminium Chloride
    },

    t4 = { -- Controller for T4 pH Neutralized Water (Grade 4)
      enable = false, -- Enable module for T4 water
      hydrochloricAcidTransposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", -- Address of transposer which provide Hydrochloric Acid
      sodiumHydroxideTransposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" -- Address of transposer which provide Sodium Hydroxide Dust
    },

    t5 = { -- Controller for T5 Extreme-Temperature Treated Water (Grade 5)
      enable = false, -- Enable module for T5 water
      plasmaTransposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", -- Address of transposer which provide Helium Plasma
      coolantTransposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" -- Address of transposer which provide Super Coolant
    },

    t6 = { -- Controller for T6 Ultraviolet Treated Electrically Neutral Water (Grade 6)
      enable = false, -- Enable module for T6 water
      transposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" -- Address of transposer which provide Lenses
    },

    t7 = { -- Controller for T7 Degassed Decontaminant-Free Water (Grade 7)
      enable = false, -- Enable module for T7 water
      inertGasTransposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", -- Address of transposer which provide Inert Gas
      superConductorTransposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", -- Address of transposer which provide Super Conductor
      netroniumTransposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", -- Address of transposer which provide Molten Neutronium
      coolantTransposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" -- Address of transposer which provide Super Coolant
    },

    t8 = { -- Controller for T8 Subatomically Perfect Water (Grade 8)
      enable = false, -- Enable module for T8 water
      maxQuarkCount = 4, -- Maximum number of each quark in the sub AE
      transposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", -- Address of transposer which provide Quarks
      subMeInterfaceAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" -- Address of me interface which connected to sub AE
    }
  }
}

return config