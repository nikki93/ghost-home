local Spatial = core.entity.newComponentType('Spatial')

function Spatial:add()
    self.position = { x = 0, y = 0 }
    self.size = { x = 32, y = 32 }
    self.rotation = 0
end


-- Return local space coordinates of a point given in world space
function Spatial:toLocalSpace(x, y)
    local dx, dy = x - self.position.x, y - self.position.y
    return core.vec2.rotate(-self.rotation, dx, dy)
end

-- Return whether the bounding box intersects a point given in world space
function Spatial:intersectsPoint(x, y)
    local lx, ly = self:toLocalSpace(x, y)
    local hsx, hsy = self.size.x / 2, self.size.y / 2
    return math.abs(lx) < hsx and math.abs(ly) < hsy
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
        love.graphics.rectangle('line', -size.x / 2, -size.y / 2, size.x, size.y)

        love.graphics.pop()
    end
    love.graphics.pop()
end


-- `Editor` extension that allows selection of `Spatial` entities by clicking

local EditorSpatialSelect = core.entity.newComponentType('EditorSpatialSelect', {
    depends = { 'Editor' },
})

function EditorSpatialSelect:selectSingle(x, y)
    -- Find all intersecting `Spatial`s
    local intersecting = {}
    for ent, spatial in pairs(core.entity.componentTypes.Spatial:getAll()) do
        if spatial:intersectsPoint(x, y) then
            table.insert(intersecting, ent)
        end
    end

    -- Empty?
    if not next(intersecting) then
        self.Editor.selected = {}
        return
    end

    -- Sort by `.Spatial.position.x`, break ties by `.Default.id`
    table.sort(intersecting, function(a, b)
        if a.Spatial.position.x ~= b.Spatial.position.x then
            return a.Spatial.position.x < b.Spatial.position.x
        end
        return a.Default.id < b.Default.id
    end)

    -- If one of them was previously selected, select the next thing
    table.insert(intersecting, intersecting[1]) -- Duplicate first at end to wrap
    for i = 1, #intersecting - 1 do
        if self.Editor.selected[intersecting[i]] then -- Found a selected one? Select next.
            self.Editor.selected = { [intersecting[i + 1]] = true }
            return
        end
    end

    -- Else just select first
    self.Editor.selected = { [intersecting[1]] = true }
end
