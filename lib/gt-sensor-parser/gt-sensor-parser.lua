local classBuilder = require("lib.class-builder.index")
local stringUtilities = require("lib.string-utilities.index")

---Remove label part of line of gt sensor information
---@param data string
---@return string
local function removeLabel(data)
  return (string.gsub(data, "^.-\\+", ""))
end

---@class GtSensorParser
---@field gtMachineProxy gt_machine
---@field sensorData string[]
local gtSensorParser = {}

---Constructor
---@return GtSensorParser
function gtSensorParser:constructor(proxy)
  self.gtMachineProxy = proxy
  self.sensorData = {}

  return self
end

---Get information from sensor
function gtSensorParser:getInformation()
  self.sensorData = self.gtMachineProxy.getSensorInformation()
end

---Get number from line of gt sensor information
---@param line integer
---@param withLabel? boolean
---@param prefix? string
---@param postfix? string
---@return number|nil
function gtSensorParser:getNumber(line, withLabel, prefix, postfix)
  local data = self.sensorData[line]

  if data == nil then
    return nil
  end

  if withLabel ~= true then
    data = removeLabel(data)
  end

  if prefix ~= nil then
    data = string.gsub(data, stringUtilities.escapePattern(prefix), "")
  end

  if postfix ~= nil then
    data = string.gsub(data, stringUtilities.escapePattern(postfix), "")
  end

  data = string.gsub(data, "§.", "")
  data = string.gsub(data, ",", "")
  data = string.match(data, "([%d%.,]+)")

  return tonumber(data)
end

---Get string from line of gt sensor information
---@param line integer
---@param withLabel? boolean
---@param prefix? string
---@param postfix? string
---@return string|nil
function gtSensorParser:getString(line, withLabel, prefix, postfix)
  local data = self.sensorData[line]

  if data == nil then
    return nil
  end

  if withLabel ~= true then
    data = removeLabel(data)
  end

  if prefix ~= nil then
    data = string.gsub(data, stringUtilities.escapePattern(prefix), "")
  end

  if postfix ~= nil then
    data = string.gsub(data, stringUtilities.escapePattern(postfix), "")
  end

  data = string.gsub(data, "§.", "")

  return data
end

---Check if string contains value
---@param line integer
---@param withLabel? boolean
---@param value string
---@return boolean|nil
function gtSensorParser:stringHas(line, withLabel, value)
  local data = self.sensorData[line]

  if data == nil then
    return nil
  end

  if withLabel ~= true then
    data = removeLabel(data)
  end

  return string.match(data, value) ~= nil
end

return classBuilder.createClass(gtSensorParser, gtSensorParser.constructor, "GtSensorParser")