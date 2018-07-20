local View = core.entity.newComponentType('View', {
    depends = { 'Spatial', 'Update' },
})

function View:add()
    self.Spatial.size.y = love.graphics.getHeight()
    self.autoAspect = true

    -- Store a single `._transform` object so we don't keep allocating and GC'ing new ones
    self._transform = love.math.newTransform()
end

function View:_setSizeFromAspect(aspect)
    aspect = aspect or love.graphics.getWidth() / love.graphics.getHeight()
    local size = self.Spatial.size
    size.x = aspect * size.y
end

function View:update()
    if self.autoAspect then
        self:_setSizeFromAspect()
    end
end

function View:_updateTransform()
    local spatial = self.Spatial
    local scaleX = spatial.size.x / love.graphics.getWidth()
    local scaleY = spatial.size.y / love.graphics.getHeight()
    self._transform:setTransformation(
        spatial.position.x, spatial.position.y,
        spatial.rotation,
        scaleX, scaleY,
        (spatial.size.x / 2) / scaleX, (spatial.size.y / 2) / scaleY)
end

function View:apply()
    if self.autoAspect then
        self:_setSizeFromAspect()
    end

    self:_updateTransform()
    love.graphics.replaceTransform(self._transform:inverse())
end

function View:toWorldSpace(x, y)
    self:_updateTransform()
    return self._transform:transformPoint(x, y)
end


-- `Editor` extension for panning / zooming the editor `View`

local EditorViewPan = core.entity.newComponentType('EditorViewPan', {
    depends = { 'Editor' },
})

function EditorViewPan:add()
    self.panning = false
    self.zoomLevel = 0
    self.zoomBase = 0
end

function EditorViewPan:mousemoved(x, y, dx, dy)
    if self.panning then
        -- Compute the delta in the world position pointed at by the mouse
        local view = self.Editor.view
        local worldX, worldY = view.View:toWorldSpace(x, y)
        local prevWorldX, prevWorldY = view.View:toWorldSpace(x - dx, y - dy)
        view.Spatial.position = {
            x = view.Spatial.position.x - (worldX - prevWorldX),
            y = view.Spatial.position.y - (worldY - prevWorldY),
        }
    end
end

function EditorViewPan:panStart(x, y)
    self.panning = true
end

function EditorViewPan:panEnd()
    self.panning = false
end

function EditorViewPan:zoom(x, y)
    local view = self.Editor.view

    -- No base height yet? Initialize
    if self.zoomBase == nil or self.zoomBase == 0 then
        self.zoomBase = view.Spatial.size.y
        self.zoomLevel = 0
    end

    self.zoomLevel = self.zoomLevel + (y > 0 and 1 or -1)
    view.Spatial.size.y = math.pow(0.85, self.zoomLevel) * self.zoomBase
end
