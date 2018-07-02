--local imgPath = basePath ..
--        '/assets/tf_animals/tf_animals/individual_frames/animals1/animals1_34.png'
--local imgBytes = network.request(imgPath)
--local imgFileData = love.filesystem.newFileData(imgBytes, 'animals1_34.png')
--local imgData = love.image.newImageData(imgFileData)
--local img = love.graphics.newImage(imgData)

local wf = require 'https://raw.githubusercontent.com/SSYGEN/windfield/master/windfield/init.lua'

function love.load()
    world = wf.newWorld(0, 0, true)
    world:setGravity(0, 512)

    box = world:newRectangleCollider(400 - 50/2, 0, 50, 50)
    box:setRestitution(0.8)
    box:applyAngularImpulse(5000)

    ground = world:newRectangleCollider(0, 550, 800, 50)
    wall_left = world:newRectangleCollider(0, 0, 50, 600)
    wall_right = world:newRectangleCollider(750, 0, 50, 600)
    ground:setType('static') -- Types can be 'static', 'dynamic' or 'kinematic'. Defaults to 'dynamic'
    wall_left:setType('static')
    wall_right:setType('static')
end

function love.update(dt)
    if world then world:update(dt) end
end

function love.draw()
    if world then world:draw() end
end
