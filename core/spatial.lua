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



----------------------------------------------------------------------------------------------------
-- `Editor` extensions


local function drawBBoxes(editor, ents)
    love.graphics.push('all')

    -- Scale line width so lines look 1 pixel wide always
    local px, py = love.graphics.transformPoint(0, 0)
    local qx, qy = love.graphics.transformPoint(1, 0)
    local scale = core.vec2.len(px - qx, py - qy)
    love.graphics.setLineWidth(1 / scale)

    for ent in pairs(ents) do
        if not ent.Default.hidden then
            local spatial = ent.Spatial
            love.graphics.push()

            if editor.Editor.selected[ent] then
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
    end
    love.graphics.pop()
end


-- Highlight

local EditorSpatialHighlightSelected = core.entity.newComponentType('EditorSpatialHighlightSelected', {
    depends = { 'Editor' },
})

function EditorSpatialHighlightSelected:add()
    self.mode = 'all'
end

function EditorSpatialHighlightSelected:drawOverlay()
    drawBBoxes(self, self.Editor.selected)
end


-- Select

local EditorSpatialSelect = core.entity.newComponentType('EditorSpatialSelect', {
    depends = { 'Editor' },
})

function EditorSpatialSelect:drawOverlay()
    drawBBoxes(self, core.entity.componentTypes.Spatial:getAll())
end

function EditorSpatialSelect:_getEntitiesIntersecting(x, y)
    x, y = self.Editor.view.View:toWorldSpace(x, y)

    local intersecting = {}
    for ent, spatial in pairs(core.entity.componentTypes.Spatial:getAll()) do
        if not ent.Default.hidden and spatial:intersectsPoint(x, y) then
            table.insert(intersecting, ent)
        end
    end

    -- Sort by distance to input, break ties by `.Default.id`
    table.sort(intersecting, function(a, b)
        local aDist = core.vec2.dist(x, y, a.Spatial.position.x, a.Spatial.position.y)
        local bDist = core.vec2.dist(x, y, b.Spatial.position.x, b.Spatial.position.y)
        if aDist ~= bDist then
            return aDist < bDist
        end
        return a.Default.id < b.Default.id
    end)

    return intersecting
end

function EditorSpatialSelect:selectSingle(x, y)
    local intersecting = self:_getEntitiesIntersecting(x, y)

    -- Empty?
    if not next(intersecting) then
        self.Editor.selected = {}
        return
    end

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

function EditorSpatialSelect:selectMultiple(x, y)
    local intersecting = self:_getEntitiesIntersecting(x, y)
    if not next(intersecting) then return end -- Empty?

    -- If one of them isn't selected, select it
    for _, ent in ipairs(intersecting) do
        if not self.Editor.selected[ent] then
            self.Editor.selected[ent] = true
            return
        end
    end

    -- Otherwise deselect the first
    self.Editor.selected[intersecting[1]] = nil
end


-- Move

local EditorSpatialMove = core.entity.newComponentType('EditorSpatialMove', {
    depends = { 'Editor' },
})

function EditorSpatialMove:move(x, y, dx, dy)
    local view = self.Editor.view
    local worldX, worldY = view.View:toWorldSpace(x, y)
    local prevWorldX, prevWorldY = view.View:toWorldSpace(x - dx, y - dy)
    local worldDX, worldDY = worldX - prevWorldX, worldY - prevWorldY
    for ent in pairs(self.Editor.selected) do
        local spatial = ent.Spatial
        if spatial then
            spatial.position = {
                x = spatial.position.x + worldDX,
                y = spatial.position.y + worldDY,
            }
        end
    end
end
