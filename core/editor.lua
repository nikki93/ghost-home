-- The editor code lives in a singleton component type (added to at most one entity) that listens
-- for all of the events the editor cares about. This singleton instance can be used to edit
-- settings of the editor itself.


----------------------------------------------------------------------------------------------------
--- Basic ------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

local Editor = core.entity.newComponentType('Editor', {
    depends = { 'Input', 'Update', 'Visual' },
})


-- The singleton instance, if exists
local editor

function Editor:add()
    if editor then
        error("'Editor' component must be added to at most one entity -- the editor itself!")
    end
    editor = self

    -- Dependency config
    self.Input.enabled = true -- Always listen for `Input` to allow edit-mode hotkey
    self.Visual:setDepth(1000) -- Draw editor overlays in front of everything else

    -- State
    self.enabled = false

    -- Our config -- see below for description
    self.componentOrder = {}
    self.hiddenProps = {}
end

function Editor:remove()
    editor = nil
end

-- Create singleton instance after defining `:add()` method
editor = core.entity.new {
    Editor = {
        -- Order to display components in
        componentOrder = {
            'Default',
            'Spatial',
            'Visual',
            'Update',
            'Sprite',
        },
        -- Commonly known hidden props
        hiddenProps = {
            ent = true,
        }
    },
}


----------------------------------------------------------------------------------------------------
--- UI ---------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

-- TUI text followed by a 'tab' for aligning tabular data
local tabWidth = 8
local function tabbedText(text)
    tui.text(text)
    tui.sameLine()
    tui.text((' '):rep(tabWidth * math.ceil(#text / tabWidth) - #text))
end

-- Table of types to functions for a TUI for that type of property
local propEditors = {}

-- Basic boolean: checkbox
function propEditors.boolean(value)
    return tui.checkbox('', value)
end

-- Basic number: direct input
function propEditors.number(value)
    return tui.inputFloat('', value, { extraFlags = { EnterReturnsTrue = true } })
end

-- Basic string: single or multiline text input
function propEditors.string(value)
    if value:find('\n') then -- Multi-line
        local cache = tui.cache()
        local changed
        tui.inChildResizable('string editor', function()
            local returnPressed
            local checkButtonPressed = tui.button(tui.icons.check)
            tui.sameLine()
            tui.withItemWidth(-1, function()
                cache.contents, returnPressed = tui.inputTextMultiline('',
                    cache.contents or value, {
                        sizeX = 0,
                        sizeY = -1,
                        flags = { EnterReturnsTrue = true, AllowTabInput = true },
                    })
            end)
            changed = returnPressed or checkButtonPressed
        end)
        return cache.contents, changed
    else -- Single-line
        return tui.inputText('', value, {
            flags = { EnterReturnsTrue = true, AllowTabInput = true },
        })
    end
end

-- `core.vec2` -- two-field input for 2d vector
propEditors[getmetatable(core.vec2(0, 0))] = function(value)
    local x, y, changed = tui.inputFloat2('', value.x, value.y,
        { extraFlags = { EnterReturnsTrue = true } })
    if not changed then return nil, false end
    return core.vec2(x, y), true
end

-- `core.color` -- color picker
propEditors[getmetatable(core.color(0, 0, 0, 0))] = function(value)
    local r, g, b, a, changed = tui.colorEdit4('',
        value.r, value.g, value.b, value.a, {
            AlphaBar = true,
            Float = true,
            PickerHueWheel = true,
        })
    if not changed then return nil, false end
    return core.color(r, g, b, a), true
end

-- Common property value editor entrypoint -- dispatches to one of the above based on type
local function propEditor(comp, propName, value)
    local propEditor = propEditors[getmetatable(value)] or propEditors[type(value)]
    if propEditor then
        tui.withItemWidth(-1, function()
            local new, changed = propEditor(value)
            if changed then comp[propName] = new end
        end)
    else
        tui.alignTextToFramePadding()
        tui.text('<unsupported>')
    end
end


-- TUI block for component with name `key` in entity `ent`
function Editor:editComponent(ent, key)
    local comp = ent[key]
    for propName, value in pairs(comp) do -- Iterate through properties in the component
        -- Check if hidden prop
        local hidden = self.hiddenProps[propName] -- Known common hidden props
                or core.entity.componentTypes[propName] -- Component dependency shortcut
                or propName:match('^_') -- Starts with '_'
        if not hidden then
            tui.withID(propName, function()
                -- Label for property name
                tui.alignTextToFramePadding()
                tabbedText(propName)
                tui.sameLine()

                -- Editor for property value
                propEditor(comp, propName, value)
            end)
        end
    end
end

-- TUI block for entity `ent`
function Editor:editEntity(ent)
    -- Compute order to show components in
    local order = {}
    local visited = {}
    for _, key in pairs(self.componentOrder) do -- First add from `componentOrder`
        if ent[key] then
            table.insert(order, key)
            visited[key] = true
        end
    end
    for key in pairs(ent) do -- Then add the rest
        if not visited[key] and core.entity.componentTypes[key] then
            table.insert(order, key)
        end
    end

    -- Show sections for each component
    for _, key in ipairs(order) do
        if tui.collapsingHeader(key, { DefaultOpen = true }) then
            tui.withID(key, function()
                self:editComponent(ent, key)
            end)
        end
    end
end


function Editor:update(dt)
    if not self.enabled then return end

    -- Draw TUIs for selected entities
    tui.inWindow('editor', function()
        -- TODO(nikki): Actually iterate over entities in a selection here
        local ent = next(core.entity.componentTypes.Default:getAll())

        tui.inChild('selected', function()
            self:editEntity(ent)
        end)
    end)
end


----------------------------------------------------------------------------------------------------
--- Draw -------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

function Editor:draw()
    if not self.enabled then return end

    -- Draw bounding boxes for all `Spatial` entities
    love.graphics.push('all')
    love.graphics.setColor(0, 1, 0)
    for ent, spatial in pairs(core.entity.componentTypes.Spatial:getAll()) do
        love.graphics.push()

        local position = spatial.position
        love.graphics.translate(position.x, position.y)

        love.graphics.rotate(spatial.rotation)

        local size = spatial.size
        local halfSize = spatial.size / 2
        love.graphics.rectangle('line', -halfSize.x, -halfSize.y, size.x, size.y)

        love.graphics.pop()
    end
    love.graphics.pop()
end


----------------------------------------------------------------------------------------------------
--- Input ------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

function Editor:keypressed(key)
    if key == 'e' and self.Input.enabled and
            (love.keyboard.isDown('lctrl') or love.keyboard.isDown('rctrl')) then
        self.enabled = not self.enabled
    end
end

function Editor:mousepressed(x, y, button)
    if not tui.wantMouse() then
        -- TODO(nikki): Select by click
    end
end

