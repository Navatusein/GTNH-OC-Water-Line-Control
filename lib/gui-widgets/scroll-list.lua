-- Scroll List Widget
-- Author: Navatusein
-- License: MIT
-- Version: 1.2

local scrollList = {}

---Crate new ScrollListWidget object
---@param name string
---@param valueName string
---@param scrollUpKeyCode number
---@param scrollDownKeyCode number
---@return ScrollListWidget
function scrollList:new(name, valueName, scrollUpKeyCode, scrollDownKeyCode)
  ---@class ScrollListWidget: Widget
  local obj = {}

  obj.name = name
  obj.valueName = valueName
  obj.scrollUpKeyCode = scrollUpKeyCode
  obj.scrollDownKeyCode = scrollDownKeyCode

  obj.template = nil

  obj.startLine = 0
  obj.size = 0

  obj.offset = 0
  obj.maxOffset = 0

  ---Init
  ---@param template Template
  function obj:init(template)
    self.template = template

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
  function obj:render(values, y, args)
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
    -- local spaces = string.rep(" ", self.template.width - 2 - #string.gsub(string, "&([^;]+);", ""))
    local itemPerOffset = self.maxOffset / (self.size - 1)

    if self.maxOffset > 0 and math.floor(self.offset / itemPerOffset) == (y - self.startLine) then
      return "&red;|&white;"..string
    end

    return "|"..string
  end

  ---Register key handlers
  ---@return table
  function obj:registerKeyHandlers()
    return {
      [self.scrollUpKeyCode] = function() self:scrollUp() end,
      [self.scrollDownKeyCode] = function() self:scrollDown() end
    };
  end

  ---Scroll up
  ---@private
  function obj:scrollUp()
    if self.offset > 0 then
      self.offset = self.offset - 1
    end
  end

  ---Scroll down
  ---@private
  function obj:scrollDown()
    if self.offset <= self.maxOffset then
      self.offset = self.offset + 1
    end
  end

  setmetatable(obj, self)
  self.__index = self
  return obj
end

return scrollList;