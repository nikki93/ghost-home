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


for i = 1, 4000 do
    core.entity.new {
        Sprite = {},
        RandomPosition = {},
    }
end

