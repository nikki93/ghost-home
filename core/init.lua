core = {}

do
    jit.off() -- Use non-FFI versions of CPML

    core.vec2 = require 'core.vec2'
    core.color = require 'core.color'

    -- Skip 3d math stuff for now
    --core.vec3 = cpml.vec3
    --core.quat = cpml.quat
    --core.bound2 = cpml.bound2
    --core.bound3 = cpml.bound3

    pcall(function() jit.on() end) -- May be permanently disabled, protect the call
end

core.uuid = require 'https://raw.githubusercontent.com/thibaultcha/lua-resty-jit-uuid/0.0.7/lib/resty/jit-uuid.lua'

require 'core.entity'
require 'core.edit'
require 'core.edit_tui'

require 'core.default'
require 'core.update'
require 'core.input'

require 'core.spatial'
require 'core.visual'

require 'core.sprite'


-- Default editor

core.entity.new {
    Edit = {},
    EditTUI = {
        componentOrder = {
            'Default',
            'Spatial',
            'Visual',
            'Update',
            'Sprite',
        },
        hiddenProps = {
            ent = true,
        },
    },
    EditSpatialBBoxes = {},
}


return core