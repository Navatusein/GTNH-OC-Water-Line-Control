local formatters = {}

---String formatter
---@param value string
---@param format string
---@return string
function formatters.s (value, format)
  if (value == nil) then
    return ""
  else
    format = (format and format or "%.2f")
    return string.format(format, value)
  end
end

---Number formatter
---@param value string
---@param unit string
---@return string
function formatters.n(value, unit, format)
  format = (format and format or "%.2f")

  local formatted = string.format(format, value)
  local k = 0

  while true do
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
    if (k == 0) then
      break
    end
  end

  return formatted..(unit and unit or "")
end

---Scientific notation formatter
---@param value number
---@param unit string
---@param format string
---@return string
function formatters.e(value, unit, format)
  format = (format and format or "%.1e")
  return string.format(format, value):gsub("e%+", "e")..(unit and unit or "")
end

---Multiplier formatter
---@param value number
---@param unit string
---@param format string
---@return string
function formatters.mu(value, unit, format)
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

  return string.format(format, scaled).." "..prefix..(unit and unit or "")
end

---Si formatter
---@param value number
---@param unit string
---@param format string
---@return string
function formatters.si(value, unit, format)
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

  return string.format(format, scaled).." "..prefix..(unit and unit or "")
end

---Time formatter
---@param seconds number
---@param parts number
---@return string
function formatters.t(seconds, parts)
  parts = (parts and tonumber(parts) or 4)

  local time_units = {
    {name = "y", value = 31536000},
    {name = "m", value = 2592000},
    {name = "d", value = 86400},
    {name = "hr", value = 3600},
    {name = "min", value = 60},
    {name = "sec", value = 1}
  }

  if seconds < 1 then
    return "0 sec"
  end

  local result = {}

  for _, unit in ipairs(time_units) do
    local unit_value = math.floor(seconds / unit.value)

    if unit_value > 0 then
      table.insert(result, unit_value.." "..unit.name)
      seconds = seconds % unit.value
    end

    if #result >= parts then
      break
    end
  end

  if #result == 0 then
    return seconds.." sec"
  end

  return table.concat(result, " ")
end

return formatters