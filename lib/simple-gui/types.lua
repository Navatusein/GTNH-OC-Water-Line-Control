---@meta

---@class GuiTemplate
---@field width number
---@field background number
---@field foreground number
---@field widgets table<string, GuiWidget>
---@field lines string[]

---@class GuiWidget
---@field template GuiTemplate
---@field name string
---@field init fun(self, template: GuiTemplate, name: string)
---@field render fun(self, values: table<string, string|number|table>, y: number, args: string[]): string
---@field registerKeyHandlers fun(): table<number, function>