local stringUtilities = {}

---Truncates a string if it exceeds the specified length.
---@param string string
---@param maxLength number
---@param suffix? string
---@return string
function stringUtilities.truncateString(string, maxLength, suffix)
  suffix = suffix or "..."

  if #string <= maxLength then
    return string
  else
    return string:sub(1, maxLength - #suffix) .. suffix
  end
end

---Converts a value to a formatted string.
---@param value any
---@param indent? number
---@return string
function stringUtilities.objectToString(value, indent)
  indent = indent or 0
  local formatting = string.rep(" ", indent)
  local result

  if type(value) == "table" or type(value) == "userdata" then
    result = "{\n"

    for k, v in pairs(value) do
      local key = type(k) == "string" and ('"'..k..'"') or k
      result = result..formatting.."  ["..key.."] = "..stringUtilities.objectToString(v, indent + 2)..",\n"
    end

    result = result..formatting.."}"
  elseif type(value) == "string" then
    result = '"'..value..'"'
  elseif type(value) == "number" or type(value) == "boolean" then
    result = tostring(value)
  elseif type(value) == "function" then
    result = "<function>"
  elseif type(value) == "thread" then
    result = "<thread>"
  elseif type(value) == "nil" then
    result = "nil"
  else
    result = "<unknown>: "..type(value)
  end

  return result
end

---Split string by delimiter
---@param string string
---@param delimiter string
---@return table
function stringUtilities.split(string, delimiter)
  local splitted = {}
  local last_end = 1

  for match, position in string:gmatch("(.-)"..delimiter.."()") do
    table.insert(splitted, match)
    last_end = position
  end

  local remaining = string:sub(last_end)

  if remaining ~= "" then
      table.insert(splitted, remaining)
  end

  return splitted
end

---Prepare string to regex
---@param text string
---@return string
---@return number
function stringUtilities.escapePattern(text)
  local specialChars = "().%+-*?[^$"
  return text:gsub("([%"..specialChars.."])", "%%%1")
end

return stringUtilities