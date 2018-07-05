local Spatial = core.entity.newComponentType('Spatial')

function Spatial:add()
    self.position = core.vec2(0, 0)
    self.size = core.vec2(32, 32)
    self.rotation = 0
end
