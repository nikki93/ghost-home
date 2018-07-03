--local a = network.fetch('https://webhook.site/a5f9f71d-700d-4520-ae68-c49a0132662a')
--local b = network.fetch('https://webhook.site/2437f2c5-f875-4b82-af1e-7ad21f3d5d58')
--local c = network.fetch('https://webhook.site/3ba3be96-88c4-4278-b3c3-f12869b83166')

local N = 10

local results = {}
for i = 1, N do
    network.async(function()
        local response = network.fetch('https://raw.githubusercontent.com/ccheever/tetris-ghost/master/main.lua')
        table.insert(results, response)
    end)
end

function love.load()
end

function love.update(dt)
    if #results == N then
        local first = results[1]
        for i = 2, N do
            if results[i] ~= first then
                print('nope')
            end
        end
        print('yup')
        results = {}
    end
end

function love.draw()
end
