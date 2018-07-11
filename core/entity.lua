core.entity = {}


-- Common methods for all component instances, of any type
local baseComponentMethods = {}

-- Called when a key isn't found in the component
local function componentMetaIndex(t, k)
    -- Found a method?
    local method = t.__info.methods[k]
    if method then return method end

    -- Has a getter?
    local propMetas = t.__info.props
    if propMetas then
        local propMeta = propMetas[k]
        if propMeta then
            local getter = propMeta.get
            if getter then
                return t[getter](t)
            end
        end
    end
end

-- Called when setting a new key on a component
local function componentMetaNewindex(t, k, v)
    -- Has a setter?
    local propMetas = t.__info.props
    if propMetas then
        local propMeta = propMetas[k]
        if propMeta then
            local setter = propMeta.set
            if setter then
                return t[setter](t, v)
            end
        end
    end

    -- Default behavior
    return rawset(t, k, v)
end

-- The metatable for all component instances
local componentMeta = {
    __index = componentMetaIndex,
    __newindex = componentMetaNewindex,
}

-- Metadata abpout each component type, keyed by component type name. See `entity.newComponentType`
-- below for format.
local componentInfos = {}

-- Create a new component type with name `name`. `opts` is a table of the following options:
--    - `depends`: Array of names of other component types this componnet requires in the entity
-- Returns the method table of the component, so that new methods may be added.
function core.entity.newComponentType(name, opts)
    if componentInfos[name] then
        error("component type with name '" .. name .. "' already exists!")
    end
    opts = opts or {}

    local info = opts

    -- Normalize `depends` table into array of string names
    info.depends = opts.depends
    if info.depends == nil then
        info.depends = {}
    elseif type(info.depends) ~= 'table' then
        info.depends = { info.depends }
    end

    -- Initialize `methods` table
    info.methods = setmetatable({
        __typeName = name,
        __info = info, -- Allow 'static' methods to access `info` easily
    }, { __index = baseComponentMethods })

    -- Initialize `entities` index
    info.entities = {}

    componentInfos[name] = info
    return info.methods
end

-- Get all entities that contain this component type. Keys are entities, values are the
-- component instances for those entities.
function baseComponentMethods:getAll()
    return self.__info.entities
end

-- Find the method table for a component type by using its name as an index. Can be used to eg.
-- access 'static' methods on no particular entity.
core.entity.componentTypes = setmetatable({}, {
    __index = function(_, k)
        local info = componentInfos[k]
        return info and info.methods or nil
    end
})


-- Methods for entity instances
local entityMethods = {}

local entityMeta = {
    __index = entityMethods,

    -- Disable adding keys directly in the entity. This makes it so fields can only be directly
    -- set on entities using `rawset`, which raises eyebrows.
    __newindex = function(t, k, v)
        error("attempted to directly set key '" .. k .. "' in entity -- please store data in " ..
                "a component inside the entity instead")
    end
}

function core.entity.new(init)
    local ent = {}
    setmetatable(ent, entityMeta)

    ent:addComponent('Default')

    -- Add components from initializer and set props
    for componentType, props in pairs(init) do
        local component = ent:addComponent(componentType)
        for k, v in pairs(props) do
            component[k] = v
        end
    end

    return ent
end

function entityMethods:destroy()
    assert(not rawget(self, 'destroyed'), "entity already destroyed!")
    rawset(self, 'destroyed', true)

    -- Remove all components
    for key in pairs(self) do
        if componentInfos[key] then
            self:removeComponent(key, true)
        end
    end
end

function entityMethods:addComponent(componentType)
    local info = assert(componentInfos[componentType],
        "no component type with name '" .. componentType .. "'")

    -- Already added?
    local key = componentType
    if self[key] then return self[key] end

    -- Add dependencies
    for _, dep in ipairs(info.depends) do
        self:addComponent(dep)
    end

    -- Create and add to entity
    local component = setmetatable({
        __info = info, -- `componentMeta` refers to `t.__info` in `__index`, so set it here
        __dependents = {},
    }, componentMeta)
    rawset(self, key, component)

    -- Add to `entities` index
    info.entities[self] = component

    -- Link dependencies
    for _, dep in ipairs(info.depends) do
        component[dep] = self[dep]
    end

    -- Initialize and call `add` method
    component.ent = self
    if component.add then
        component:add()
    end

    -- Notify dependencies
    for _, dep in ipairs(info.depends) do
        local dependency = assert(self[dep],
            "'" .. componentType .. "' depends on '" .. dep .. "' but it's not present!")
        dependency.__dependents[component] = true
        if dependency.addDependent then
            dependency:addDependent(componentType)
        end
    end

    return component
end

function entityMethods:removeComponent(componentType, removeDependents)
    local info = assert(componentInfos[componentType],
        "no component type with name '" .. componentType .. "'")

    -- Get component instance
    local key = componentType
    local component = assert(self[key],
        "entity doesn't have component type with name '" .. componentType .. "'")

    -- Remove dependents?
    if removeDependents then
        for dependent in pairs(component.__dependents) do
            self:removeComponent(dependent.__typeName, true)
        end
    elseif next(component.__dependents) then
        error("attempted to remove component '" .. componentType .. "', a dependency for other " ..
                "components such as '" .. next(component.__dependents).__typeName .. "'")
    end

    -- Notify dependencies
    for _, dep in ipairs(info.depends) do
        local dependency = assert(self[dep],
            "'" .. componentType .. "' depends on '" .. dep .. "' but it's not present!")
        if dependency.removeDependent then
            dependency:removeDependent(componentType)
        end
        dependency.__dependents[component] = nil
    end

    -- Call `remove` method
    if component.remove then
        component:remove()
    end

    -- Remove from `entities` index
    info.entities[self] = nil

    -- Remove from entity
    rawset(self, componentType, nil)
end

