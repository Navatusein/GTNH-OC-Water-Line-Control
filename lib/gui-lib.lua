-- Gui Lib
-- Author: CAHCAHbl4
-- Edit: Navatusein
-- License: MIT
-- Version: 2.10

local component = require("component")
local term = require("term")
local serialization = require("serialization")

local gpu = component.gpu

---@class GUIConfig
---@field program Program

---@class Template
---@field width number
---@field background number
---@field foreground number
---@field widgets table<string, Widget>
---@field lines string[]

---@class Widget
---@field init fun(self, template: Template, name: string)
---@field render fun(self, values: table<string, string|number|table>, y: number, args: string[]): string
---@field registerKeyHandlers fun(): table<number, function>

---Split string by delimiter
---@param string string
---@param delimiter string
---@return table
---@private
local function split(string, delimiter)
  local splitted = {}
  local last_end = 1

  for match in string:gmatch("(.-)"..delimiter) do
    table.insert(splitted, match)
    last_end = #match + #delimiter + 1
  end

  local remaining = string:sub(last_end)

  if remaining ~= "" then
      table.insert(splitted, remaining)
  end

  return splitted
end

local formatters = {
  ---String formatter
  ---@param value string
  ---@param format string
  ---@return string
  s = function(value, format)
    if (value == nil) then
      return ""
    else
      format = (format and format or "%.2f")
      return string.format(format, value)
    end
  end,

  ---Number formatter
  ---@param value string
  ---@return string
  n = function(value, format)
    format = (format and format or "%.2f")

    local formatted = string.format(format, value)
    local k = 0

    while true do
      formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
      if (k == 0) then
        break
      end
    end
    return formatted
  end,

  ---Multiplier formatter
  ---@param value number
  ---@param unit string
  ---@param format string
  ---@return string
  mu = function(value, unit, format)
    format = (format and format or "%.2f")

    local prefix = ""
    local scaled = value

    if value ~= 0 then
      local degree = math.floor(math.log(math.abs(value), 10) / 3)
      scaled = value * 1000 ^ -degree
      if degree > 0 then
        prefix = "10^"..tostring(degree * 3)
      elseif degree < 0 then
        prefix = "10^-"..tostring(-degree * 3)
      end
    end

    if prefix == nil then
      return tostring(value)
    end

    return string.format(format, scaled) .. " " .. prefix .. (unit and unit or "")
  end,

  ---Si formatter
  ---@param value number
  ---@param unit string
  ---@param format string
  ---@return string
  si = function(value, unit, format)
    format = (format and format or "%.2f")
    local incPrefixes = {"k", "M", "G", "T", "P", "E", "Z", "Y"}
    local decPrefixes = {"m", "μ", "n", "p", "f", "a", "z", "y"}

    local prefix = ""
    local scaled = value

    if value ~= 0 then
      local degree = math.floor(math.log(math.abs(value), 10) / 3)
      scaled = value * 1000 ^ -degree
      if degree > 0 then
        prefix = incPrefixes[degree]
      elseif degree < 0 then
        prefix = decPrefixes[-degree]
      end
    end

    return string.format(format, scaled) .. " " .. prefix .. (unit and unit or "")
  end,

  ---Time formatter
  ---@param seconds number
  ---@param parts number
  ---@return string
  t = function(seconds, parts)
    parts = (parts and parts or 4)

    local units = {"y", "m", "d", "hr", "min", "sec"}
    local result = {}

    for i, v in ipairs({31104000, 2592000, 86400, 3600, 60}) do
      if seconds >= v then
        result[i] = math.floor(seconds / v)
        seconds = seconds % v
      end
    end

    result[4] = seconds

    local resultString = ""
    local i = 1
    while parts ~= 0 and i ~= 5 do
      if result[i] and result[i] > 0 then
        if i > 1 and resultString ~= "" then
          resultString = resultString .. " "
        end
        resultString = resultString .. result[i] .. " " .. units[i]
        parts = parts - 1
      end
      i = i + 1
    end
    return resultString
  end
}

local justifyContent = {
  ---Justify Content End
  ---@param line string
  ---@param width number
  ---@return string
  e = function (line, width)
    local rawLine = line:gsub("&([^;]+);", "")
    local spaces = string.rep(" ", width - #rawLine)
    return spaces..line
  end,

  ---Justify Content Center
  ---@param line string
  ---@return string
  c = function (line, width)
    local rawLine = line:gsub("&([^;]+);", "")
    local spaces = string.rep(" ", math.floor((width - #rawLine) / 2))
    return spaces..line
  end,

  ---Justify Content Space Between
  ---@param line string
  ---@return string
  sb = function (line, width)
    local rawLine = line:gsub("&([^;]+);", ""):gsub("@|@", "")
    local parts = split(line, "@|@")

    if parts == 1 then
      return line
    end

    local totalSpaces = width - #rawLine
    local spacesBetween = string.rep(" ", totalSpaces // (#parts - 1))
    local extraSpacesCount = totalSpaces % (#parts - 1)

    local result = ""

    for i = 1, #parts do
        result = result .. parts[i]
        if i < #parts then
            result = result .. spacesBetween
            if extraSpacesCount > 0 then
                result = result .. " "
                extraSpacesCount = extraSpacesCount - 1
            end
        end
    end

    return result
  end,

  ---Justify Content Space Evenly
  ---@param line string
  ---@return string
  se = function (line, width)
    local rawLine = line:gsub("&([^;]+);", ""):gsub("@|@", "")
    local parts = split(line, "@|@")

    if parts == 1 then
      local spaces = string.rep(" ", math.floor((width - #rawLine) / 2))
      return spaces..line
    end

    local totalSpaces = width - #rawLine
    local spacesBetween = string.rep(" ", totalSpaces // (#parts + 1))
    local extraSpacesCount = totalSpaces % (#parts + 1)

    local result = spacesBetween

    if extraSpacesCount > 0 then
        result = result .. " "
        extraSpacesCount = extraSpacesCount - 1
    end

    for i = 1, #parts do
      result = result .. parts[i]
      if i < #parts then
          result = result .. spacesBetween
          if extraSpacesCount > 0 then
              result = result .. " "
              extraSpacesCount = extraSpacesCount - 1
          end
      end
    end

    return result
  end
}

local gui = {}

---Crate new GUI object from config
---@param config GUIConfig
---@return GUI
function gui:newFormConfig(config)
  return self:new(config.program)
end

---Crate new GUI object
---@param program Program
---@return GUI
function gui:new(program)
  ---@class GUI
  local obj = {}

  obj.program = program

  obj.width = 32
  obj.height = 1

  obj.template = nil

  obj.allowRender = true

  obj.registeredKeys = {}

  obj.palette = {
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

  ---Set template
  ---@param template Template
  function obj:setTemplate(template)
    self.template = template
    self.width = template.width
    self.height = #template.lines

    if template.widgets then
      for _, key in pairs(self.registeredKeys) do 
        program:removeKeyHandler(key);
      end

      for name, widget in pairs(template.widgets) do
        widget:init(template, name)

        local keyHandlers = widget:registerKeyHandlers()

        for key, callback in pairs(keyHandlers) do
          program:registerKeyHandler(key, callback)
          table.insert(self.registeredKeys, key)
        end
      end
    end

    gpu.setResolution(self.width, self.height)
  end

  ---Render Conditions
  ---@param line string
  ---@param values table<string, any>
  ---@return string, number
  ---@private
  function obj:renderConditions(line, values)
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
  function obj:renderValues(line, values)
    return string.gsub(line, "%$(.-)%$", function (pattern)
      local formatter
      local variable, args = pattern:match("^(.+):(.+)$")

      if not variable then
        variable = pattern
        formatter = "s"
        args = {"%s"}
      else
        args = split(args, ",")
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
  function obj:renderWidgets(line, values, y)
    return string.gsub(line, "#(.-)#", function (pattern)
      local name, args = pattern:match("^(.+):(.+)$")

      if not name then
        name = pattern
        args = {}
      else
        args = split(args, ",")
      end

      if self.template.widgets[name] then
        return self.template.widgets[name]:render(values, y, table.unpack(args))
      end
    end)
  end

  ---Render Line Content Justify
  ---@param line string
  ---@return string
  function obj:renderLineContentJustify(line)
    local justify = line:match("@([^;]+);")

    if not justify then
      return line
    end

    return justifyContent[justify](line:gsub("@([^;]+);", ""), self.template.width)
  end

  ---Render
  ---@param values table<string, string|number|table|boolean>
  function obj:render(values)
    if not self.allowRender then
      return
    end

    local buffer = gpu.allocateBuffer(self.width, self.height)
    gpu.setActiveBuffer(buffer)

    local y = 1

    for _, line in pairs(self.template.lines) do
      gpu.setBackground(self.template.background)
      gpu.setForeground(self.template.foreground)

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
              gpu.setBackground(color)
            else
              gpu.setForeground(color)
            end
          end

          i = i + 1
        else
          gpu.set(x, y, symbol)
          x = x + 1
          i = i + 1
        end
      end

      y = y + 1
    end

    gpu.bitblt(0, 1, 1, self.width, self.height, buffer, 1, 1)
    gpu.freeAllBuffers()
  end

  ---Reset Screen
  function obj:resetScreen()
    local width, height = gpu.maxResolution()
    gpu.freeAllBuffers()
    gpu.setResolution(width, height)
    gpu.fill(1, 1, width, height, " ")
    term.setCursor(0, 0)
  end

  ---Reset To Template
  function obj:resetToTemplate()
    gpu.freeAllBuffers()
    gpu.setResolution(self.width, self.height)
    gpu.fill(1, 1, self.width, self.height, " ")
    term.setCursor(0, 0)
  end

  setmetatable(obj, self)
  self.__index = self
  return obj
end

return gui