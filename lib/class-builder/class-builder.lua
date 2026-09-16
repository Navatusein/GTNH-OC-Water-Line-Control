local classBuilder = {}

---@class ClassBuilder<ClassType, ConstructorType>: {new: ConstructorType}

--- Creates a new class with optional inheritance and metamethods support
---@generic ClassType
---@generic ConstructorType
---@param class ClassType
---@param constructorType ConstructorType
---@param className? string
---@param baseClass? table
---@return ClassBuilder<ClassType, ConstructorType>
function classBuilder.createClass(class, constructorType, className, baseClass)
  local builder = {}

  if baseClass then
    setmetatable(class, { __index = baseClass })
  end

  function builder:new(...)
    local instance = setmetatable({}, {
      __index = class,

      __tostring = function(obj)
        return obj.toString and obj:toString() or "<object>"
      end,

      __len = function(obj)
        return obj.len and obj:len() or -1
      end,

      __concat = function(a, b)
        return tostring(a)..tostring(b)
      end,
    })

    instance:constructor(...)

    instance.__className = className or "class"

    return instance
  end

  return builder
end

return classBuilder
