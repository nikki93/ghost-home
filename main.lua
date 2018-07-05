local Spatial = entity.newComponentType('Spatial')

local defaultX, defaultY = 0.5 * love.graphics.getWidth(), 0.5 * love.graphics.getHeight()

function Spatial:add()
    self.x, self.y = defaultX, defaultY
    self.width, self.height = 32, 32
    self.rotation = 0
end


local Visual = entity.newComponentType('Visual')

-- Maintain references to all `Visual` instances as keys
local all = {}

-- Order to draw `Visual` instances in as an array -- `orderDirty` is whether it needs an update
local order = {}
local orderDirty = true

function Visual:add()
    self._depth = 1

    -- Names of visual component types attached to this entity
    self.dependentTypes = {}

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
    self.dependentTypes[dependentType] = true
end

function Visual:removeDependent(dependentType)
    self.dependentTypes[dependentType] = false
end

function love.draw()
    -- Update `order` if it's dirty
    if orderDirty then
        order = {}
        for instance in pairs(all) do
            table.insert(order, instance)
        end
        table.sort(order, function(i1, i2)
            return i1._depth < i2._depth
        end)
    end

    -- Render all visual component types for every visual entity
    for _, instance in ipairs(order) do
        for dependentType in pairs(instance.dependentTypes) do
            local dependentInstance = instance.ent[dependentType]
            if dependentInstance.draw then
                dependentInstance:draw()
            end
        end
    end
end


local Sprite = entity.newComponentType('Sprite', {
    depends = { 'Spatial', 'Visual' },
})

local defaultImage = love.graphics.newImage('assets/avatar2.png')

function Sprite:add()
    self.image = defaultImage
    self.scale = 1
end

function Sprite:draw()
    local spatial = self.Spatial
    love.graphics.draw(self.image,
        spatial.x, spatial.y, spatial.rotation,
        self.scale, self.scale,
        spatial.width / 2, spatial.height / 2)
end


local ent1 = entity.newEntity()
ent1:addComponent('Sprite')

local ent2 = entity.newEntity()
ent2:addComponent('Sprite')
ent2.Spatial.x, ent2.Spatial.y = defaultX + 64, defaultY + 64

function love.update(dt)
    ent2.Visual:setDepth(math.floor(love.timer.getTime()) % 2 == 0 and 2 or 0)
end

