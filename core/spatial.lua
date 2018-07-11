local Spatial = core.entity.newComponentType('Spatial')

function Spatial:add()
    self.position = core.vec2(0, 0)
    self.size = core.vec2(32, 32)
    self.rotation = 0
end


-- Transform `point` from world space to local space
function Spatial:toLocalSpace(point)
    return (point - self.position):rotate(-self.rotation)
end

-- Return whether the bounding box intersects `point` given in world space
function Spatial:intersectsPoint(point)
    local localPoint = self:toLocalSpace(point)
    return math.abs(localPoint.x) < self.size.x / 2
            and math.abs(localPoint.y) < self.size.y / 2
end


-- `Editor` extension that draws bounding boxes of all `Spatial` entities

local EditorSpatialBBoxes = core.entity.newComponentType('EditorSpatialBBoxes', {
    depends = { 'Editor' },
})

function EditorSpatialBBoxes:drawOverlay()
    love.graphics.push('all')
    for ent, spatial in pairs(core.entity.componentTypes.Spatial:getAll()) do
        love.graphics.push()

        if self.Editor.selected[ent] then
            love.graphics.setColor(1, 0, 0)
        else
            love.graphics.setColor(0, 1, 0)
        end

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


-- `Editor` extension that allows selection of `Spatial` entities by clicking

local EditorSpatialSelect = core.entity.newComponentType('EditorSpatialSelect', {
    depends = { 'Editor' },
})

function EditorSpatialSelect:selectSingle(x, y)
    local point = core.vec2(x, y)
    local selected
    for ent, spatial in pairs(core.entity.componentTypes.Spatial:getAll()) do
        if spatial:intersectsPoint(point) then
            selected = ent
        end
    end
    if selected ~= nil then
        self.Editor.selected[selected] = true
    else
        self.Editor.selected = {}
    end
end
