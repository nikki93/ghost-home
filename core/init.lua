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
require 'core.editor'
require 'core.editor_tui'

require 'core.default'
require 'core.update'
require 'core.input'

require 'core.spatial'
require 'core.visual'

require 'core.sprite'


-- Default editor

core.entity.new {
    Editor = {
        enabled = false, -- Whether editing is initially enabled
        mode = 'default', -- Initial mode
        bindings = {
            mainToggle = 'ctrl_e', -- Toggles whether editing is enabled
            default = {
                mouse1 = 'EditorSpatialSelect.selectSingle',
            },
        },
    },
    EditorTUI = {
        componentOrder = { -- Show these components before other ones, in this order
            'Default',
            'Spatial',
            'Visual',
            'Update',
            'Sprite',
        },
        hiddenProps = { -- Hide these properties across all components
            ent = true,
        },
    },
    EditorSpatialBBoxes = {},
    EditorSpatialSelect = {},
}


return core