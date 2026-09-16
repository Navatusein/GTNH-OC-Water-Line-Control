---@meta

---@alias ConfigTemplate BaseConfigValidator[]

---@class BaseConfigValidatorOption<ValueType>: {value: ValueType, message?: string}

---@class BaseConfigValidator
---@field validate fun(self, value: any, config: table<string, any>): boolean, string?
---@field factory fun(self, value: any): any
---@field skipper? fun(value: any, config: table<string, any>): boolean
---@field isNullable BaseConfigValidatorOption<boolean>
---@field checker? BaseConfigValidatorOption<fun(value: any, config: table<string, any>): boolean>

---@class BaseConfigValidatorOptions
---@field skipper? fun(value: any, config: table<string, any>): boolean
---@field isNullable? BaseConfigValidatorOption<boolean>
---@field checker? BaseConfigValidatorOption<fun(value: any, config: table<string, any>): boolean>