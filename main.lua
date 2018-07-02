local http = require 'copas.http'

local basePath = portal.path:gsub('/main.lua$', '')

local x = portal.args.x
local y = portal.args.y

local children = {}

local imgPath = basePath ..
        '/assets/tf_animals/tf_animals/individual_frames/animals1/animals1_34.png'
local imgBytes = http.request(imgPath)
local imgFileData = love.filesystem.newFileData(imgBytes, 'animals1_34.png')
local imgCompData = love.image.newImageData(imgFileData)
local img = love.graphics.newImage(imgCompData)

function love.draw()
    love.graphics.push('all')
    love.graphics.draw(img, x, y)
    love.graphics.pop()

    for _, child in pairs(children) do
        child:draw()
    end
end

function love.mousepressed()
    if portal.args.spawnChildren then
        table.insert(children, portal:newChild('https://7859de82.ngrok.io/main.lua', {
            x = love.graphics.getWidth() * math.random(),
            y = love.graphics.getHeight() * math.random(),
        }))
    end
end
