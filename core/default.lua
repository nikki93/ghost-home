local Default = core.entity.newComponentType('Default')


function Default:add()
    self.id = core.uuid()
end

function Default:remove()
    -- Make sure we're only being removed because the entity was destroyed
    if not self.ent.destroyed then
        error("attempted to remove 'Default' component from entity, which must always be present")
    end
end

