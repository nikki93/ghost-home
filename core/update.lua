local Update = core.entity.newComponentType('Update')


function Update:updateAll(dt)
    for _, instance in pairs(Update:getAll()) do
        for dependent in pairs(instance.__dependents) do
            dependent:update(dt)
        end
    end
end
