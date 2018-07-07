local Update = core.entity.newComponentType('Update')


-- Maintain references to all `Update` instances as keys
local all = {}


function Update:add()
    all[self] = true
end

function Update:remove()
    all[self] = nil
end


-- Update all updatable components on `love.update`
function love.update(dt)
    for instance in pairs(all) do
        for dependent in pairs(instance.__dependents) do
            dependent:update(dt)
        end
    end
end
