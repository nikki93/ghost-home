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
    self._visualComponents = {}

    all[self] = true
    orderDirty = true
end

function Visual:remove()
    all[self] = nil
    orderDirty = true
end


-- Keep track of components that depend on us

function Visual:addDependent(dependentType)
    local dependent = self.ent[dependentType]
    if dependent.draw then
        self._visualComponents[dependent] = true
    end
end

function Visual:removeDependent(dependentType)
    local dependent = self.ent[dependentType]
    self._visualComponents[dependent] = nil
end


function Visual:setDepth(newDepth)
    self._depth = newDepth
    orderDirty = true
end

function Visual:getDepth()
    return self._depth
end


-- Draw all visual components on `love.draw`
function love.draw()
    ensureOrder()
    for _, instance in ipairs(order) do
        for comp in pairs(instance._visualComponents) do
            comp:draw()
        end
    end
end
