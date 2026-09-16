local helper = {}

---Validate config
---@param template ConfigTemplate
---@param value any
---@param config table<string, any>
---@return boolean isValid
---@return string? message
function helper.validate(template, value, config)
  for key, _ in pairs(template) do
    if template[key].validate == nil or template[key].factory == nil then
      return false, "invalid template: "..template[key]
    end

    local isValid, message = template[key]:validate(value[key], config)

    if isValid == false then
      return false, "("..key..") "..(message or "nil")
    end
  end

  return true, nil
end

---Build config
---@param template ConfigTemplate
---@param value table
---@return table
function helper.build(template, value)
  local buildedConfig = {}

  for key, _ in pairs(template) do
    buildedConfig[key] = template[key]:factory(value[key])
  end

  return buildedConfig
end

return helper