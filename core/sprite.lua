local Sprite = core.entity.newComponentType('Sprite', {
    depends = { 'Spatial', 'Visual' },
})

local defaultImage = love.graphics.newImage('assets/avatar2.png')

function Sprite:add()
    self.image = defaultImage
    self.scale = 1
    self.color = core.color(1, 1, 1, 1)

    local spatial = self.Spatial
    spatial.size = core.vec2(self.image:getDimensions())
end

function Sprite:draw()
    local spatial = self.Spatial
    local halfSize = spatial.size / 2
    local prevR, prevG, prevB, prevA = love.graphics.getColor()
    love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.color.a)
    love.graphics.draw(self.image,
        spatial.position.x, spatial.position.y,
        spatial.rotation,
        self.scale, self.scale,
        halfSize.x, halfSize.y)
    love.graphics.setColor(prevR, prevG, prevB, prevA)
end
