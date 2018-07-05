require 'core'


local RandomPosition = core.entity.newComponentType('RandomPosition', {
    depends = { 'Spatial' },
})

function RandomPosition:add()
    self.Spatial.position = core.vec2 {
        x = math.random() * love.graphics.getWidth(),
        y = math.random() * love.graphics.getHeight(),
    }
end


local Rotating = core.entity.newComponentType('Rotating', {
    depends = { 'Spatial', 'Update' },
})

function Rotating:add()
    self.rotationSpeed = math.pi
end

function Rotating:update(dt)
    self.Spatial.rotation = self.Spatial.rotation + self.rotationSpeed * dt

    if love.keyboard.isDown('a') then
        if self.Spatial.position.y > 0.5 * love.graphics.getHeight() then
            self.ent:destroy()
        end
    end
end


for i = 1, 5 do
    core.entity.new {
        Sprite = {},
        RandomPosition = {},
        Rotating = {},
    }
end


