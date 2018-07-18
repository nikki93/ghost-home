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
