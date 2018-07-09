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
    depends = { 'Spatial', 'Update', 'Input' },
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

function Rotating:keypressed(key)
    if key == 'up' then
        if self.Spatial.position.y > 0.5 * love.graphics.getHeight() then
            self.ent:removeComponent('Input', true)
        end
    end
    if key == 'right' then
        if self.Spatial.position.y > 0.5 * love.graphics.getHeight() then
            self.ent:destroy()
        end
    end
end


for i = 1, 10 do
    core.entity.new {
        Sprite = {},
        RandomPosition = {},
        Rotating = {},
        Input = { enabled = true },
    }
end

