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


-- Draw all visual components on `love.draw`
function love.draw()
    ensureOrder()
    for _, instance in ipairs(order) do
        for dependent in pairs(instance.__dependents) do
            dependent:draw()
        end
    end
end
