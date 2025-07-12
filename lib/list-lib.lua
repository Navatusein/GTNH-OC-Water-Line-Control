-- List Lib
-- Author: Navatusein
-- License: MIT
-- Version: 1.4

---@class ListConfig
---@field maxSize number|nil

local list = {}

---Crate new List object from config
---@param config ListConfig
---@return List
function list:newFormConfig(config)
  return self:new(config.maxSize)
end

---Crate new List object
---@param maxSize? number
---@return List
function list:new(maxSize)

  ---@class List
  local obj = {}

  obj.list = {}
  obj.maxSize = maxSize

  ---Add item to front
  ---@param value any
  function obj:pushFront(value)
    table.insert(self.list, 1, value)

    if self.maxSize and #self.list > self.maxSize then
        table.remove(self.list)
    end
  end

  ---Add item to back
  ---@param value any
  function obj:pushBack(value)
    table.insert(self.list, value)

    if self.maxSize and #self.list > self.maxSize then
      table.remove(self.list, 1)
    end
  end

  ---Remove item form front
  function obj:popFront()
    table.remove(self.list, 1)
  end

  ---Remove item from back
  function obj:popBack()
    table.remove(self.list)
  end

  ---Clear list
  function obj:clear()
    for _ = 1, #self.list, 1 do
      table.remove(self.list)
    end
  end

  ---Calculate average
  ---@return integer
  function obj:average()
    if #self.list == 0 then
      return 0
    end

    local result = 0

    for _, value in ipairs(self.list) do
      if type(value) == "number" then
        result = result + value
      end
    end

    return result / #self.list
  end

  ---Calculate median
  ---@return integer
  function obj:median()
    if #self.list == 0 then
      return 0
    end

    local temp = {}

    for _, value in ipairs(self.list) do
      if type(value) == "number" then
        table.insert(temp, value)
      end
    end

    table.sort(temp)

    if math.fmod(#temp, 2) == 0 then
      return (temp[#temp / 2] + temp[(#temp / 2) + 1]) / 2
    else
      return temp[math.ceil(#temp / 2)]
    end
  end

  setmetatable(obj, self)
  self.__index = self
  return obj
end

return list