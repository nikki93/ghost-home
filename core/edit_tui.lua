-- `Edit` extension that shows a TUI window allowing launching editor functionality, and shows
-- TUIs for selected entities with their components and properties.

local EditTUI = core.entity.newComponentType('EditTUI', {
    depends = { 'Edit' },
})


-- TUI text followed by a 'tab' for aligning tabular data
local tabWidth = 8
local function tabbedText(text)
    tui.text(text)
    tui.sameLine()
    tui.text((' '):rep(tabWidth * math.ceil(#text / tabWidth) - #text))
end

-- Table of types to functions for a TUI for that type of property
local propEdits = {}

-- Basic boolean: checkbox
function propEdits.boolean(value)
    return tui.checkbox('', value)
end

-- Basic number: direct input
function propEdits.number(value)
    return tui.inputFloat('', value, { extraFlags = { EnterReturnsTrue = true } })
end

-- Basic string: single or multiline text input
function propEdits.string(value)
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
propEdits[getmetatable(core.vec2(0, 0))] = function(value)
    local x, y, changed = tui.inputFloat2('', value.x, value.y,
        { extraFlags = { EnterReturnsTrue = true } })
    if not changed then return nil, false end
    return core.vec2(x, y), true
end

-- `core.color` -- color picker
propEdits[getmetatable(core.color(0, 0, 0, 0))] = function(value)
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
local function propEdit(comp, propName, value)
    local propEdit = propEdits[getmetatable(value)] or propEdits[type(value)]
    if propEdit then
        tui.withItemWidth(-1, function()
            local new, changed = propEdit(value)
            if changed then comp[propName] = new end
        end)
    else
        tui.alignTextToFramePadding()
        tui.text('<unsupported>')
    end
end


-- TUI block for component with name `key` in entity `ent`
function EditTUI:editComponent(ent, key)
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

                -- Edit for property value
                propEdit(comp, propName, value)
            end)
        end
    end
end

-- TUI block for entity `ent`
function EditTUI:editEntity(ent)
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

function EditTUI:update(dt)
    tui.inWindow('editor', function()
        tui.inChild('selected', function()
            for ent in pairs(self.Edit.selection) do
                self:editEntity(ent)
            end
        end)
    end)
end
