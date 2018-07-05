local core = require 'core'

local ent1 = core.entity.new {
    Sprite = {},
}

local ent2 = core.entity.new {
    Spatial = { position = core.vec2(64, 64) },
    Sprite = {},
}

function love.update(dt)
    ent2.Visual:setDepth(math.floor(love.timer.getTime()) % 2 == 0 and 2 or 0)
end

