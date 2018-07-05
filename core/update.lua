local Update = core.entity.newComponentType('Update')


-- Maintain references to all `Update` instances as keys
local all = {}


function Update:add()
    self.updatableComponents = {}
    all[self] = true
end

function Update:remove()
    all[self] = nil
end


-- Keep track of components that depend on us

function Update:addDependent(dependentType)
    local dependent = self.ent[dependentType]
    if dependent.update then
        self.updatableComponents[dependent] = true
    end
end

function Update:removeDependent(dependentType)
    local dependent = self.ent[dependentType]
    self.updatableComponents[dependent] = false
end

-- Update all updatable components on `love.update`
function love.update(dt)
    for instance in pairs(all) do
        for comp in pairs(instance.updatableComponents) do
            comp:update(dt)
        end
    end
end
