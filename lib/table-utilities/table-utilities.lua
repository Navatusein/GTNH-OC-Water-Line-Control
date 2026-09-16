local tableUtilities = {}

---Add item to front
---@param data table
---@param value any
---@param maxSize? number
function tableUtilities.pushFront(data, value, maxSize)
  table.insert(data, 1, value)

  if maxSize ~= nil and #data > maxSize then
    table.remove(data)
  end
end

---Add item to back
---@param data table
---@param value any
---@param maxSize? number
function tableUtilities.pushBack(data, value, maxSize)
  table.insert(data, value)

  if maxSize ~= nil and #data > maxSize then
    table.remove(data, 1)
  end
end

---Remove item form front
---@param data table
function tableUtilities.popFront(data)
  if #data == 0 then
    return
  end

  table.remove(data, 1)
end

---Remove item from back
---@param data table
function tableUtilities.popBack(data)
  if #data == 0 then
    return
  end

  table.remove(data)
end

---Clear list
---@param data table
function tableUtilities.clear(data)
  for _ = 1, #data, 1 do
    table.remove(data)
  end
end

---Calculate average
---@param data table
---@return number
function tableUtilities.average(data)
  if #data == 0 then
    return 0
  end

  local result = 0

  for _, value in ipairs(data) do
    if type(value) == "number" then
      result = result + value
    end
  end

  return result / #data
end

---Calculate median
---@param data table
---@return number
function tableUtilities.median(data)
  if #data == 0 then
    return 0
  end

  local temp = {}

  for _, value in ipairs(data) do
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

return tableUtilities