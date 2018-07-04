-- Load libs directly from their GitHub URIs!

local sti = require 'https://raw.githubusercontent.com/karai17/Simple-Tiled-Implementation/master/sti/init.lua'
local moonshine = require 'https://raw.githubusercontent.com/nikki93/moonshine/master/init.lua'

local map
local TILE_SIZE = 16

local effect

function love.load()
    map = sti('assets/maps/map1.lua')
    effect = moonshine(moonshine.effects.vignette)
end

function love.draw()
    effect(function()
        love.graphics.push('all')
        map:draw(-49 * TILE_SIZE, -54 * TILE_SIZE, 2, 2)
        love.graphics.pop()
    end)
end

function love.update(dt)
    map:update(dt)
end
