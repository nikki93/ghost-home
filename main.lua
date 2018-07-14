require 'core'


local RandomPosition = core.entity.newComponentType('RandomPosition', {
    depends = { 'Spatial' },
})

function RandomPosition:add()
    self.Spatial.position = {
        x = (math.random() - 0.5) * love.graphics.getWidth(),
        y = (math.random() - 0.5) * love.graphics.getHeight(),
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
end

function Rotating:keypressed(key)
    if key == 'left' then
        self.ent:removeComponent('Input')
    end
    if key == 'right' then
        self.ent:removeComponent('Rotating')
    end
end

for i = 1, 1000 do
    core.entity.new {
        Sprite = {},
        RandomPosition = {},
        Rotating = {},
        Input = { enabled = true },
    }
end

--core.entity.new {
--    Profiler = {},
--}
