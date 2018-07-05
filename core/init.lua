core = {}

do
    jit.off() -- Use non-FFI versions of CPML

    core.vec2 = require 'https://raw.githubusercontent.com/excessive/cpml/130fe2aca042b39299d16bd63df3aa606fe630ad/modules/vec2.lua'
    core.color = require 'https://raw.githubusercontent.com/excessive/cpml/130fe2aca042b39299d16bd63df3aa606fe630ad/modules/color.lua'

    -- Skip 3d math stuff for now
    --core.vec3 = cpml.vec3
    --core.quat = cpml.quat
    --core.bound2 = cpml.bound2
    --core.bound3 = cpml.bound3

    pcall(function() jit.on() end) -- May be permanently disabled, protect the call
end

require 'core.entity'
require 'core.default'
require 'core.update'
require 'core.spatial'
require 'core.visual'
require 'core.editor'
require 'core.sprite'

return core