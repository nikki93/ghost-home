local Update = core.entity.newComponentType('Update')


-- Update all updatable components on `love.update`
function love.update(dt)
    for _, instance in pairs(Update:getAll()) do
        for dependent in pairs(instance.__dependents) do
            dependent:update(dt)
        end
    end
end
