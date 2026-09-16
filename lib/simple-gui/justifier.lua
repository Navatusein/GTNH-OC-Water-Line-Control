local stringUtilities = require("lib.string-utilities.index")

local justifier = {}

---Justify Content End
---@param line string
---@param width number
---@return string
function justifier.e(line, width)
  local rawLine = line:gsub("&([^;]+);", "")
  local spaces = string.rep(" ", width - #rawLine)
  return spaces..line
end

---Justify Content Center
---@param line string
---@return string
function justifier.c(line, width)
  local rawLine = line:gsub("&([^;]+);", "")
  local spaces = string.rep(" ", math.floor((width - #rawLine) / 2))
  return spaces..line
end

---Justify Content Space Between
---@param line string
---@return string
function justifier.sb(line, width)
  local rawLine = line:gsub("&([^;]+);", ""):gsub("@|@", "")
  local parts = stringUtilities.split(line, "@|@")

  if parts == 1 then
    return line
  end

  local totalSpaces = width - #rawLine
  local spacesBetween = string.rep(" ", totalSpaces // (#parts - 1))
  local extraSpacesCount = totalSpaces % (#parts - 1)

  local result = ""

  for i = 1, #parts do
      result = result..parts[i]
      if i < #parts then
          result = result..spacesBetween
          if extraSpacesCount > 0 then
              result = result.." "
              extraSpacesCount = extraSpacesCount - 1
          end
      end
  end

  return result
end

---Justify Content Space Evenly
---@param line string
---@return string
function justifier.se(line, width)
  local rawLine = line:gsub("&([^;]+);", ""):gsub("@|@", "")
  local parts = stringUtilities.split(line, "@|@")

  if parts == 1 then
    local spaces = string.rep(" ", math.floor((width - #rawLine) / 2))
    return spaces..line
  end

  local totalSpaces = width - #rawLine
  local spacesBetween = string.rep(" ", totalSpaces // (#parts + 1))
  local extraSpacesCount = totalSpaces % (#parts + 1)

  local result = spacesBetween

  if extraSpacesCount > 0 then
      result = result.." "
      extraSpacesCount = extraSpacesCount - 1
  end

  for i = 1, #parts do
    result = result..parts[i]
    if i < #parts then
        result = result..spacesBetween
        if extraSpacesCount > 0 then
            result = result.." "
            extraSpacesCount = extraSpacesCount - 1
        end
    end
  end

  return result
end

return justifier