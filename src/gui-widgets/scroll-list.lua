local classBuilder = require("lib.class-builder.index")

---@class ScrollList: GuiWidget
---@field name string
---@field valueName string
---@field scrollUpKeyCode number
---@field scrollDownKeyCode number
---@field startLine number
---@field size number
---@field offset number
---@field maxOffset number
local scrollList = {}

---Constructor
---@param valueName string
---@param scrollUpKeyCode number
---@param scrollDownKeyCode number
---@return ScrollList
function scrollList:constructor(valueName, scrollUpKeyCode, scrollDownKeyCode)
  self.valueName = valueName
  self.scrollUpKeyCode = scrollUpKeyCode
  self.scrollDownKeyCode = scrollDownKeyCode

  self.startLine = 0
  self.size = 0

  self.offset = 0
  self.maxOffset = 0

  return self
end

---Init
---@param template GuiTemplate
function scrollList:init(template, name)
  self.template = template
  self.name = name

  for index, line in pairs(self.template.lines) do
    if string.find(line, self.name) then
      if self.startLine == 0 then
        self.startLine = index
      end

      self.size = self.size + 1
    end
  end
end

---Render
---@param values table<string, string|number|table>
---@param y number
---@param args string[]
---@return string
function scrollList:render(values, y, args)
  local list = values[self.valueName]

  self.maxOffset = #list - self.size

  if self.maxOffset < 0 then
    self.maxOffset = 0
  end

  if self.offset > self.maxOffset then
    self.offset = self.maxOffset
  end

  local index = y - self.startLine + 1 + self.offset
  local string = tostring(list[index] or "")
  local itemPerOffset = self.maxOffset / (self.size - 1)

  if self.maxOffset > 0 and math.floor(self.offset / itemPerOffset) == (y - self.startLine) then
    return "&red;|&white;"..string
  end

  return "|"..string
end

---Register key handlers
---@return table
function scrollList:registerKeyHandlers()
  return {
    [self.scrollUpKeyCode] = function()
      if self.offset > 0 then
        self.offset = self.offset - 1
      end
    end,
    [self.scrollDownKeyCode] = function()
      if self.offset <= self.maxOffset then
        self.offset = self.offset + 1
      end
    end
  };
end

return classBuilder.createClass(scrollList, scrollList.constructor, "ScrollList")
