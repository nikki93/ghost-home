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

require 'core.view'
require 'core.sprite'


-- Default view

local defaultView = core.entity.new {
    View = {},
}

local editorView = core.entity.new {
    Default = { hidden = true },
    View = {},
}
editorView.Spatial.size.y = 1.2 * editorView.Spatial.size.y

-- Default editor

local editor = core.entity.new {
    Default = { hidden = true },
    Editor = {
        enabled = false, -- Whether editing is initially enabled
        view = editorView, -- `View` to render from while editing
        mode = 'none', -- Initial mode
        bindings = {
            mainToggle = 'ctrl_e', -- Toggles whether editing is enabled
            all = {
                escape = 'exit',
                ['1'] = 'EditorViewNav',
                ['2'] = 'EditorSpatialSelect',
                ['3'] = 'EditorSpatialMove',
            },
            EditorViewNav = {
                mouse1dragged = 'pan',
                wheelmoved = 'zoom',
            },
            EditorSpatialSelect = {
                mouse1 = 'selectSingle',
                shift_mouse1 = 'selectMultiple',
            },
            EditorSpatialMove = {
                mouse1dragged = 'move',
                s = 'toggleSnap',
            },
        },
    },
    EditorTUI = {
        modeButtons = {
            {
                mode = 'EditorViewNav',
                icon = 'nav',
            },
            {
                mode = 'EditorSpatialSelect',
                icon = 'select',
            },
            {
                mode = 'EditorSpatialMove',
                icon = 'move',
            },
        },
        componentOrder = {
            -- Show these components before other ones, in this order
            'Default',
            'Spatial',
            'Visual',
            'Update',
            'Sprite',
        },
        hiddenProps = {
            -- Hide these props across all components
            ent = true,
        },
    },
    EditorViewNav = {},
    EditorSpatialHighlightSelected = {},
    EditorSpatialSelect = {},
    EditorSpatialMove = {},
}


-- Default Love callbacks

function love.update(dt)
    core.entity.componentTypes.Update:updateAll(dt)
end

function love.draw()
    local view = editor.Editor.enabled and editorView or defaultView
    core.entity.componentTypes.Visual:drawAll({ view = view })
end

for cb in pairs(core.entity.componentTypes.Input.callbackNames) do
    love[cb] = function(...)
        core.entity.componentTypes.Input[cb .. 'All'](core.entity.componentTypes.Input, ...)
    end
end


return core