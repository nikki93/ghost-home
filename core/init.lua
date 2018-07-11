core = {}


-- External libraries

core.uuid = require 'https://raw.githubusercontent.com/thibaultcha/lua-resty-jit-uuid/0.0.7/lib/resty/jit-uuid.lua'
core.types = (require 'https://raw.githubusercontent.com/leafo/tableshape/2187b5858a6441b83d895f3f4b65fb98575895e7/tableshape/init.lua').types
core.vec2 = require 'https://raw.githubusercontent.com/vrld/hump/0bf301f7109c5029c54090bcfe76ff035b2961c0/vector-light.lua'


-- Modules

require 'core.entity'

require 'core.editor'
require 'core.editor_tui'

require 'core.default'
require 'core.update'
require 'core.input'

require 'core.spatial'
require 'core.visual'

require 'core.profiler'

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
        hiddenProps = { -- Hide these props across all components
            ent = true,
        },
    },
    EditorSpatialBBoxes = {},
    EditorSpatialSelect = {},
}


return core