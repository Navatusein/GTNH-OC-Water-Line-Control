local component = require("component")
local term = require("term")
local serialization = require("serialization")

local classBuilder = require("lib.class-builder.index")
local stringUtilities = require("lib.string-utilities.index")

local formatters = require("lib.simple-gui.formatters")
local justifier = require("lib.simple-gui.justifier")

---@class SimpleGui
---@field program Program
---@field width number
---@field height number
---@field template GuiTemplate
---@field allowRender boolean
---@field registeredKeys table
---@field palette table<string, number>
local simpleGui = {}

---Constructor
---@return SimpleGui
function simpleGui:constructor(program)
  self.program = program

  self.width = 32
  self.height = 1

  self.template = nil

  self.allowRender = true

  self.registeredKeys = {}

  self.palette = {
    white = 0xFFFFFF,
    black = 0x000000,
    red = 0xCC0000,
    green = 0x009200,
    blue = 0x0000C0,
    lightBlue = 0xADDFFF,
    yellow = 0xFFDB00,
    pink = 0xFF007F,
    lime = 0x00FF00,
    magenta = 0xFF00FF,
    cyan = 0x00FFFF,
    greenYellow = 0xADFF2F,
    darkOliveGreen = 0x556B2F,
    indigo = 0x4B0082,
    purple = 0x800080,
    electricBlue = 0x00A6FF,
    dodgerBlue = 0x1E90FF,
    steelBlue = 0x4682B4,
    darkSlateBlue = 0x483D8B,
    midnightBlue = 0x191970,
    darkBlue = 0x000080,
    darkOrange = 0xFFA500,
    rosyBrown = 0xBC8F8F,
    golden = 0xDAA520,
    maroon = 0x800000,
    gray = 0x3C5B72,
    lightGray = 0xA9A9A9,
    darkGray = 0x181828,
    darkSlateGrey = 0x2F4F4F
  }

  return self
end

---Set template
---@param template GuiTemplate
function simpleGui:setTemplate(template)
  self.template = template
  self.width = template.width
  self.height = #template.lines

  if template.widgets then
    for _, key in pairs(self.registeredKeys) do 
      self.program:removeKeyHandler(key);
    end

    for name, widget in pairs(template.widgets) do
      widget:init(template, name)

      local keyHandlers = widget:registerKeyHandlers()

      for key, callback in pairs(keyHandlers) do
        self.program:registerKeyHandler(key, callback)
        table.insert(self.registeredKeys, key)
      end
    end
  end

  component.gpu.setResolution(self.width, self.height)
end

---Reset Screen
function simpleGui:resetScreen()
  local width, height = component.gpu.maxResolution()
  component.gpu.freeAllBuffers()
  component.gpu.setResolution(width, height)
  component.gpu.fill(1, 1, width, height, " ")
  term.setCursor(0, 0)
end

---Reset To Template
function simpleGui:resetToTemplate()
  component.gpu.freeAllBuffers()
  component.gpu.setResolution(self.width, self.height)
  component.gpu.fill(1, 1, self.width, self.height, " ")
  term.setCursor(0, 0)
end

---Render
---@param values table<string, string|number|table|boolean>
function simpleGui:render(values)
  if not self.allowRender then
    return
  end

  local buffer = component.gpu.allocateBuffer(self.width, self.height)
  component.gpu.setActiveBuffer(buffer)

  local y = 1

  for _, line in pairs(self.template.lines) do
    component.gpu.setBackground(self.template.background)
    component.gpu.setForeground(self.template.foreground)

    local renderedString = line
    renderedString = self:renderConditions(renderedString, values)
    renderedString = self:renderValues(renderedString, values)
    renderedString = self:renderWidgets(renderedString, values, y)
    renderedString = self:renderLineContentJustify(renderedString)

    local x = 1
    local i = 1

    while i <= #renderedString do
      local symbol = renderedString:sub(i, i)
      if symbol == "&" then
        local colorString = ""
        local isBackgroundColor = false

        if renderedString:sub(i + 1, i + 1) == "&" then
          isBackgroundColor = true
          i = i + 1
        end

        repeat
          i = i + 1
          local next = renderedString:sub(i, i)
          if next ~= ";" then
            colorString = colorString .. next
          end
        until next == ";"

        local color
        if self.palette[colorString] then
          color = self.palette[colorString]
        else
          local hex = tonumber(colorString)
          if hex then
              color = hex
          end
        end

        if color then
          if isBackgroundColor then
            component.gpu.setBackground(color)
          else
            component.gpu.setForeground(color)
          end
        end

        i = i + 1
      else
        component.gpu.set(x, y, symbol)
        x = x + 1
        i = i + 1
      end
    end

    y = y + 1
  end

  component.gpu.bitblt(0, 1, 1, self.width, self.height, buffer, 1, 1)
  component.gpu.freeAllBuffers()
end

---Render Line Content Justify
---@param line string
---@return string
---@private
function simpleGui:renderLineContentJustify(line)
  local justify = line:match("@([^;]+);")

  if not justify then
    return line
  end

  return justifier[justify](line:gsub("@([^;]+);", ""), self.template.width)
end

---Render Conditions
---@param line string
---@param values table<string, any>
---@return string, number
---@private
function simpleGui:renderConditions(line, values)
  return string.gsub(line, "?(.-)?", function (pattern)
    local condition, left, right = pattern:match("^(.*)|(.*)|(.*)$")
    local lambda = ""

    for key, value in pairs(values) do
      lambda = lambda..key.."="

      if type(value) == "string" then
        lambda = lambda.."\""..value.."\"\n"
      elseif type(value) == "table" then
        lambda = lambda..serialization.serialize(value).."\n"
      elseif type(value) == "boolean" then
        lambda = lambda..(value == true and "true" or "false").."\n"
      else
        lambda = lambda..value.."\n"
      end
    end

    lambda = lambda.."return "..condition

    local result = load(lambda)()

    return result and left or right
  end)
end

---Render Values
---@param line string
---@param values table<string, any>
---@return string, number
---@private
function simpleGui:renderValues(line, values)
  return string.gsub(line, "%$(.-)%$", function (pattern)
    local formatter
    local variable, args = pattern:match("^(.+):(.+)$")

    if not variable then
      variable = pattern
      formatter = "s"
      args = {"%s"}
    else
      args = stringUtilities.split(args, ",")
      formatter = args[1]
      table.remove(args, 1)
    end

    if formatter then
      return formatters[formatter](values[variable], table.unpack(args))
    end

    return values[variable]
  end)
end

---Render Widgets
---@param line string
---@param values table<string, any>
---@param y number
---@return string, number
---@private
function simpleGui:renderWidgets(line, values, y)
  return string.gsub(line, "#(.-)#", function (pattern)
    local name, args = pattern:match("^(.+):(.+)$")

    if not name then
      name = pattern
      args = {}
    else
      args = stringUtilities.split(args, ",")
    end

    if self.template.widgets[name] then
      return self.template.widgets[name]:render(values, y, table.unpack(args))
    end
  end)
end

return classBuilder.createClass(simpleGui, simpleGui.constructor, "SimpleGui")