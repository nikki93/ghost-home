local Default = core.entity.newComponentType('Default')


-- Maintain all `Default` instances as keys, with their entities as values
local all = {}


function Default:add()
    self.id = core.uuid()

    all[self] = self.ent
end

function Default:remove()
    -- Make sure we're only being removed because the entity was destroyed
    if not self.ent.destroyed then
        error("attempted to remove 'Default' component from entity, which must always be present")
    end
    all[self] = nil
end


function Default.getAll()
    return all
end
