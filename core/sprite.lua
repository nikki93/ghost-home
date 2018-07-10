local Sprite = core.entity.newComponentType('Sprite', {
    depends = { 'Spatial', 'Visual' },
})

local defaultImage = love.graphics.newImage('assets/avatar2.png')

function Sprite:add()
    self.image = defaultImage
    self.color = core.color(1, 1, 1, 1)
end

function Sprite:draw()
    local prevR, prevG, prevB, prevA = love.graphics.getColor()
    love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.color.a)

    local spatial = self.Spatial

    local imgSize = core.vec2(self.image:getDimensions())
    local halfImgSize = imgSize / 2
    local scale = spatial.size / imgSize

    love.graphics.draw(self.image,
        spatial.position.x, spatial.position.y,
        spatial.rotation,
        scale.x, scale.y,
        halfImgSize.x, halfImgSize.y)

    love.graphics.setColor(prevR, prevG, prevB, prevA)
end
