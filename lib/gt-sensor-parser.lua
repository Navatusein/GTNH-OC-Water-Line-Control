-- GT Sensor Parser Lib
-- Author: Navatusein
-- License: MIT
-- Version: 1.0

local event = require("event")

local function escapePattern(text)
  local specialChars = "().%+-*?[^$"
  return text:gsub("([%" .. specialChars .. "])", "%%%1")
end

local gtSensorParser = {}

---Crate new GTSensorParser object
---@param gtMachineProxy gt_machine
---@return GTSensorParser
function gtSensorParser:new(gtMachineProxy) 
  ---@class GTSensorParser
  local obj = {}

  obj.gtMachineProxy = gtMachineProxy

  ---@type string[]
  obj.sensorData = {}

  function obj:getInformation()
    self.sensorData = self.gtMachineProxy.getSensorInformation()
  end

  ---Get number from line of gt sensor information
  ---@param line integer
  ---@param prefix? string
  ---@param postfix? string
  ---@return number|nil
  function obj:getNumber(line, prefix, postfix)
    local data = self.sensorData[line]

    if data == nil then
      return nil
    end

    if prefix ~= nil then
      data = string.gsub(data, escapePattern(prefix), "")
    end

    if postfix ~= nil then
      data = string.gsub(data, escapePattern(postfix), "")
    end

    data = string.gsub(data, "§.", "")
    data = string.gsub(data, ",", "")
    data = string.match(data, "([%d%.,]+)")

    return tonumber(data)
  end

  ---Get string from line of gt sensor information
  ---@param line integer
  ---@param prefix? string
  ---@param postfix? string
  ---@return string|nil
  function obj:getString(line, prefix, postfix)
    local data = self.sensorData[line]

    if data == nil then
      return nil
    end

    if prefix ~= nil then
      data = string.gsub(data, escapePattern(prefix), "")
    end

    if postfix ~= nil then
      data = string.gsub(data, escapePattern(postfix), "")
    end

    data = string.gsub(data, "§.", "")

    return data
  end

  ---comment
  ---@param line integer
  ---@param value string
  ---@return boolean|nil
  function obj:stringHas(line, value)
    local data = self.sensorData[line]

    if data == nil then
      return nil
    end

    return string.match(data, value) ~= nil
  end

  setmetatable(obj, self)
  self.__index = self
  return obj
end

return gtSensorParser