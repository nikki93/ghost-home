local Visual = core.entity.newComponentType('Visual', {
    props = {
        depth = {
            set = 'setDepth',
            get = 'getDepth',
        },
    },
})


-- Order to draw `Visual` instances in as an array -- `orderDirty` is whether it needs an update
local order = {}
local orderDirty = true
local function ensureOrder()
    if orderDirty then
        order = {}
        for _, instance in pairs(Visual:getAll()) do
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

    orderDirty = true
end

function Visual:remove()
    orderDirty = true
end


function Visual:setDepth(newDepth)
    self._depth = newDepth
    orderDirty = true
end

function Visual:getDepth()
    return self._depth
end


function Visual:drawAll(opts)
    opts = opts or {}

    ensureOrder()

    love.graphics.push('all')

    if opts.view then
        opts.view.View:apply()
    end

    for _, instance in ipairs(order) do
        for dependent in pairs(instance.__dependents) do
            dependent:draw()
        end
    end

    love.graphics.pop()
end
