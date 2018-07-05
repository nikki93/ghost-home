-- The editor code lives in a singleton component type (added to at most one entity) that listens
-- for all of the events the editor cares about. This singleton instance can be used to edit
-- settings of the editor itself.


local Editor = core.entity.newComponentType('Editor', {
    depends = { 'Update' },
})


-- The singleton instance, if exists
local editor

function Editor:add()
    if editor then
        error("'Editor' component must be added to at most one entity -- the editor!")
    end
    editor = self

    -- See bottom for descriptions of these
    self.componentOrder = {}
    self.hiddenProps = {}
end

function Editor:remove()
    editor = nil
end


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
    return ui.checkbox('', value)
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


-- TUI block (inside the window) for component with name `key` in entity `ent`
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

                -- Editor for property value -- select an editor based on type
                local propType = type(value)
                local propEditor = propEditors[propType]
                if propEditor then
                    tui.withItemWidth(-1, function()
                        local new, changed = propEditor(value)
                        if changed then comp[propName] = new end
                    end)
                else
                    tui.alignTextToFramePadding()
                    tui.text('<unsupported>')
                end
            end)
        end
    end
end

-- Draw TUIs for all entities editing is enabled for
function Editor:update(dt)
    for _, ent in pairs(core.entity.componentTypes.Default.getAll()) do
        -- Window title with last few characters of `Default.id`
        local shortId = ent.Default.id:sub(-5)
        tui.inWindow('ent-' .. shortId, function()
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
        end)
    end
end


-- Create singleton instance after defining component methods (especially `:add()`)
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
