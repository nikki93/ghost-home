local Sprite = core.entity.newComponentType('Sprite', {
    depends = { 'Spatial', 'Visual' },
})

local defaultImage = love.graphics.newImage('assets/avatar2.png')

function Sprite:add()
    self.image = defaultImage
    self.color = { r = 1, g = 1, b = 1, a = 1 }
end

function Sprite:draw()
    local prevR, prevG, prevB, prevA = love.graphics.getColor()
    love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.color.a)

    local spatial = self.Spatial
    local imgSizeX, imgSizeY = self.image:getDimensions()
    love.graphics.draw(self.image,
        spatial.position.x, spatial.position.y,
        spatial.rotation,
        spatial.size.x / imgSizeX, spatial.size.y / imgSizeY,
        imgSizeX / 2, imgSizeY / 2)

    love.graphics.setColor(prevR, prevG, prevB, prevA)
end
