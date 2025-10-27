# GTNH-OC-Water-Line-Control

> [!CAUTION]
> In GTNH version 2.8, added tiers for transposers.
> For the program to work correctly, you need to use at least a LUV pump with a transposer.

## Content

- [Information](#information)
- [Installation](#installation)
- [Water Line Setup](#water-line-setup)
- [Configuration](#configuration)

<a id="information"></a>

## Information

Program is designed to automate the water line from T3 to T8 water. 
Program is modular, you can choose which water types you want to automate.
It is also possible to send messages to Discord about out of service situations.
And there is also the possibility of auto update at startup.

#### Controls

<kbd>Q</kbd> - Closing the program

<kbd>Arrow Up</kbd> - Scroll list up

<kbd>Arrow Down</kbd> - Scroll list down

#### Interface

![Interface](/docs/interface.png)

<a id="installation"></a>

## Installation

> [!CAUTION]
> If you are using 8 java, the installer will not work for you. 
> The only way to install the program is to manually transfer it to your computer.
> The problem is on the java side.

To install program, you need a server with:
- Graphics Card (Tier 3): 1
- Central Processing Unit (CPU) (Tier 3): 1
- Memory (Tier 3.5): 2
- Component Bus (Tier 3): 1
- Hard Disk Drive (Tier 3) (4MB): 1
- EEPROM (Lua BIOS): 1
- Internet Card: 1

![Computer setup](/docs/server.png)

Install the basic Open OS on your computer.
Then run the command to start the installer.

```shell
pastebin run ESUAMAGx
``` 

Or

```shell
wget -f https://raw.githubusercontent.com/Navatusein/GTNH-OC-Installer/main/installer.lua && installer
``` 

Then select the Water Line Control program in the installer.
If you wish you can add the program to auto download, for manual start write a command.

```shell
main
```

> [!NOTE]  
> For convenient configuration you can use the web configurator.
> [GTNH-OC-Web-Configurator](https://navatusein.github.io/GTNH-OC-Web-Configurator/#/configurator?url=https%3A%2F%2Fraw.githubusercontent.com%2FNavatusein%2FGTNH-OC-Water-Line-Control%2Frefs%2Fheads%2Fmain%2Fconfig-descriptor.yml)

#### Computer setup

The program interface is configured for a 3x2 monitor.

![Computer setup](/docs/computer-setup.png)

<a id="water-line-setup"></a>

## Water Line Setup

> [!NOTE]  
> For easy copying of addresses, use "Analyzer" from the OpenComputers mod. Right-click on the component, its address will be written in the chat. 
> If you click on it, it will be copied.
>
> <img src="docs/analyzer.png" alt="Analyzer" width="120"/>

<br/>

> [!NOTE]  
> There's a save of the world with a setup of water line. Game version 2.7.3
> [Save](https://github.com/Navatusein/GTNH-OC-Water-Line-Control/raw/main/water-line-world.zip)

### Water Purification Plant

#### Components

To build a setup, you will need:
- Adapter: 1
- MFU: 1

#### Description

The main multiblock of the line. The cycle of the entire line is read from it.

> [!CAUTION]
> Water Purification Plant must be connected.

The controller is connected via MFU to keep it accessible.

#### Example setup

![Water Purification Plant](/docs/water-purification-plant.png)

### [T3] Flocculated Water (Grade 3)

> [!CAUTION]
> In GTNH version 2.8, added tiers for transposers.
> For the program to work correctly, you need to use at least a LUV pump with a transposer.

#### Components

To build a setup, you will need:
- Adapter: 1
- Transposer: 1
- MFU: 1

#### Description

To use the module for t3 water in the `config.lua`
file you need to enable the module by changing `enable = false` to `enable = true`. 
You must also specify the address of the transposer in the `transposerAddress` field, which is located under the ZPM input hatch and to which the tank with the 
Polyaluminium chloride connected.

The controller is connected via MFU to keep it accessible.

#### T3 Config part

```Lua
t3 = { -- Controller for T3 Flocculated Water (Grade 3)
  enable = false, -- Enable module for T3 water
  controller = t3controllerLib:newFormConfig({
    transposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", -- Address of transposer which provide Polyaluminium Chloride
  }),
},
```

#### Example setup

![T3 Setup](/docs/t3-setup.png)

### [T4] pH Neutralized Water (Grade 4)

> [!CAUTION]
> In GTNH version 2.8, added tiers for transposers.
> For the program to work correctly, you need to use at least a LUV pump with a transposer.

#### Components

To build a setup, you will need:
- Adapter: 1
- Transposer: 2

#### Description

To use the module for t4 water in the `config.lua`
file you need to enable the module by changing `enable = false` to `enable = true`. 
It is also necessary to specify transposer addresses in 
the fields `hydrochloricAcidTransposerAddress` and `sodiumHydroxideTransposerAddress`, 
they are respectively located above the input hatch for Hydrochloric Acid next to the 
tank and above the input bus for Sodium Hydroxide next to the interface.

#### T4 Config part

```Lua
t4 = { -- Controller for T4 pH Neutralized Water (Grade 4)
  enable = false, -- Enable module for T4 water
  controller = t4controllerLib:newFormConfig({
    hydrochloricAcidTransposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", -- Address of transposer which provide Hydrochloric Acid
    sodiumHydroxideTransposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" -- Address of transposer which provide Sodium Hydroxide Dust
  }),
},
```

#### Example setup

![T3 Setup](/docs/t4-setup.png)

### [T5] Extreme-Temperature Treated Water (Grade 5)

> [!CAUTION]
> In GTNH version 2.8, added tiers for transposers.
> For the program to work correctly, you need to use at least a LUV pump with a transposer.

#### Components

To build a setup, you will need:
- Adapter: 1
- Transposer: 2

#### Description

To use the module for t5 water in the `config.lua`
file you need to enable the module by changing `enable = false` to `enable = true`. 
It is also necessary to specify transposer addresses in 
the fields `plasmaTransposerAddress` and `coolantTransposerAddress`, 
they are respectively located below the input hatch for Helium Plasma next to the 
tank and below the input hatch for Super Coolant next to the tank.

#### T5 Config part

```Lua
t5 = { -- Controller for T5 Extreme-Temperature Treated Water (Grade 5)
  enable = false, -- Enable module for T5 water
  controller = t5controllerLib:newFormConfig({
    plasmaTransposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", -- Address of transposer which provide Helium Plasma
    coolantTransposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" -- Address of transposer which provide Super Coolant
  }),
},
```

#### Example setup

![T5 Setup](/docs/t5-setup.png)

### [T6] Ultraviolet Treated Electrically Neutral Water (Grade 6)

#### Components

To build a setup, you will need:
- Adapter: 1
- Transposer: 1

#### Description

To use the module for t7 water in the `config.lua`
file you need to enable the module by changing `enable = false` to `enable = true`. 
You must also specify the address of the transposer in the `transposerAddress` field, which is located above the Lens Housing and to which the chest with lenses connected.

The chest should contain all 9 lenses: Orundum Lens, Amber Lens, Aer Lens, Emerald Lens, Mana Diamond Lens, Blue Topaz Lens, Amethyst Lens, Fluor-Buergerite Lens, Dilithium Lens.

> [!NOTE]  
> Dilithium Lens is optional.

![Chest With Lenses](/docs/chest-with-lenses.png)

#### T6 Config part

```Lua
t6 = { -- Controller for T6 Ultraviolet Treated Electrically Neutral Water (Grade 6)
  enable = false, -- Enable module for T6 water
  controller = t6controllerLib:newFormConfig({
    transposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" -- Address of transposer which provide Lenses
  }),
},
```

#### Example setup

![T6 Setup](/docs/t6-setup.png)

### [T7] Degassed Decontaminant-Free Water (Grade 7)

> [!CAUTION]
> In GTNH version 2.8, added tiers for transposers.
> For the program to work correctly, you need to use at least a LUV pump with a transposer.

#### Components

To build a setup, you will need:
- Adapter: 1
- Transposer: 4
- MFU: 1

#### Description

> [!NOTE]  
> If you play on version 2.7 do not forget to install `Degasser Control Hatch` in the structure, 
> although it is not necessary for the program, but without it the structure will not work

To use the module for t7 water in the `config.lua`
You must also specify the addresses of the transposers: 
`inertGasTransposerAddress` here is the address of the transposer that will supply Helium, Neon, Krypton, Xenon.
`superConductorTransposerAddress` here is the address of the transposer that will supply Superconductor Base.
`netroniumTransposerAddress` here is the address of the transposer that will supply Molten Neutronium.
`coolantTransposerAddress` here is the address of the transposer that will supply Super Coolant.

The controller is connected via MFU to keep it accessible.

#### T7 Config part

```Lua
t7 = { -- Controller for T7 Degassed Decontaminant-Free Water (Grade 7)
  enable = false, -- Enable module for T7 water
  controller = t7controllerLib:newFormConfig({
    inertGasTransposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", -- Address of transposer which provide Inert Gas
    superConductorTransposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", -- Address of transposer which provide Super Conductor
    netroniumTransposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", -- Address of transposer which provide Molten Neutronium
    coolantTransposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" -- Address of transposer which provide Super Coolant
  }),
},
```

#### Example setup

![T7 Setup](/docs/t7-setup.png)

### [T8] Subatomically Perfect Water (Grade 8)

#### Components

To build a setup, you will need:
- Adapter: 2
- Transposer: 1
- MFU: 1

#### Description

To use the module for t8 water in the `config.lua`
You must also specify the address of the transposer in the `transposerAddress` 
field, which is located under the hv input bus and to which the interface with the Quarks connected.
Also the address of the adapter connected to me interface in the `subMeInterfaceAddress` field.
Also in the configs you can change the number of quarks the computer must support in this field ` maxQuarkCount`.
There you need to specify the number of quarks that are in the subnet. So if you put 7 quarks of each type in the subnet. 
3 will go into the interface, then you need to specify 4. Because that's how many are left in the subnet.

The controller is connected via MFU to keep it accessible.

The idea is that a separate subnet is made for quarks. The Absolute Baryonic Perfection Purification Unit returns unused quarks and 2 
Unaligned Quark Releasing Catalysts after crafting is complete. The computer looks to see which quarks are less than the specified 
number (`maxQuarkCount` in the default configs is 4) and orders them. That is, the subnet must have at least 2 CPUs and a 
Hyper-Intensity Laser Engraver connected to order quarks. It is possible without a subnet, but the condition is that the computer can order quarks. 
Stabilized Baryonic Matter can be fed into the subsystem or directly into the Laser Engraver.

> [!NOTE]  
> Maximum 42 infinity ingots used per cycle. But usually less. Consumption can be 6, 18, 42 ingots per cycle. Depends on luck.

#### T8 Config part

```Lua
t8 = { -- Controller for T8 Subatomically Perfect Water (Grade 8)
  enable = false, -- Enable module for T8 water
  controller = t8controllerLib:newFormConfig({
    maxQuarkCount = 4, -- Maximum number of each quark in the sub AE
    transposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", -- Address of transposer which provide Quarks
    subMeInterfaceAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" -- Address of me interface which connected to sub AE
  })
}
```

#### Example setup

![T8 Setup 1](/docs/t8-setup-1.png)

![T8 Setup 2](/docs/t8-setup-2.png)

<a id="configuration"></a>

## Configuration

> [!NOTE]  
> For convenient configuration you can use the web configurator.
> [GTNH-OC-Web-Configurator](https://navatusein.github.io/GTNH-OC-Web-Configurator/#/configurator?url=https%3A%2F%2Fraw.githubusercontent.com%2FNavatusein%2FGTNH-OC-Water-Line-Control%2Frefs%2Fheads%2Fmain%2Fconfig-descriptor.yml)

General configuration in file `config.lua`
The configuration of water line modules is described in paragraph [Water Line Setup](#water-line-setup).

Enable auto update when starting the program.

```lua
enableAutoUpdate = true, -- Enable auto update on start
```

In the `timeZone` field you can specify your time zone.

In the `discordWebhookUrl` field, you can specify the Discord Webhook link so that the program sends messages to the discord about emergency situations.
[How to Create a Discord Webhook?](https://www.svix.com/resources/guides/how-to-make-webhook-discord/)

```lua
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
```
