local Visual = core.entity.newComponentType('Visual')

-- Maintain references to all `Visual` instances as keys
local all = {}

-- Order to draw `Visual` instances in as an array -- `orderDirty` is whether it needs an update
local order = {}
local orderDirty = true
local function ensureOrder()
    if orderDirty then
        order = {}
        for instance in pairs(all) do
            table.insert(order, instance)
        end
        table.sort(order, function(i1, i2)
            return i1._depth < i2._depth
        end)
        orderDirty = false
    end
end

function Visual:add()
    self._depth = 1

    -- Visual component instances attached to this entity as keys
    self.visuals = {}

    all[self] = true
    orderDirty = true
end

function Visual:remove()
    all[self] = nil
    orderDirty = true
end

function Visual:setDepth(newDepth)
    self._depth = newDepth
    orderDirty = true
end

function Visual:getDepth()
    return self._depth
end

function Visual:addDependent(dependentType)
    local dependentInstance = self.ent[dependentType]
    if dependentInstance.draw then
        self.visuals[dependentInstance] = true
    end
end

function Visual:removeDependent(dependentType)
    local dependentInstance = self.ent[dependentType]
    self.visuals[dependentInstance] = false
end

function love.draw()
    ensureOrder()

    -- Render all visual component types for every visual entity
    for _, instance in ipairs(order) do
        for visual in pairs(instance.visuals) do
            visual:draw()
        end
    end
end
