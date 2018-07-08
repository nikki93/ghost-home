local Spatial = core.entity.newComponentType('Spatial')

function Spatial:add()
    self.position = core.vec2(0, 0)
    self.size = core.vec2(32, 32)
    self.rotation = 0
end


-- `Edit` extension that draws bounding boxes of all `Spatial` entities

local EditSpatialBBoxes = core.entity.newComponentType('EditSpatialBBoxes', {
    depends = { 'Edit' },
})

function EditSpatialBBoxes:drawOverlay()
    love.graphics.push('all')
    love.graphics.setColor(0, 1, 0)
    for ent, spatial in pairs(core.entity.componentTypes.Spatial:getAll()) do
        love.graphics.push()

        local position = spatial.position
        love.graphics.translate(position.x, position.y)

        love.graphics.rotate(spatial.rotation)

        local size = spatial.size
        local halfSize = spatial.size / 2
        love.graphics.rectangle('line', -halfSize.x, -halfSize.y, size.x, size.y)

        love.graphics.pop()
    end
    love.graphics.pop()
end

