-- `Editor` extension that shows a TUI window allowing launching editor functionality, and shows
-- TUIs for selected entities with their components and props.

local EditorTUI = core.entity.newComponentType('EditorTUI', {
    depends = { 'Editor' },
})

function EditorTUI:add()
    self.mode = 'all'
    self.componentOrder = {}
    self.hiddenProps = {}
    self.modeButtons = {}
end


-- TUI text followed by a 'tab' for aligning tabular data
local tabWidth = 8
local function tabbedText(text)
    tui.text(text)
    tui.sameLine()
    tui.text((' '):rep(tabWidth * math.ceil(#text / tabWidth) - #text))
end

-- Table of types to functions for a TUI for that type of prop. See the `propEditor` function below
-- to get an idea of what they take and return.
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

-- Table of shape and TUI functions for that shape -- is an array because it picks the first one
-- that matches in the order, in case multiple match
local tableEditors = {}

-- Editor for 'xy' tables
table.insert(tableEditors, {
    match = core.types.shape({
        x = core.types.number,
        y = core.types.number,
    }),
    editor = function(value)
        local changed
        value.x, value.y, changed = tui.inputFloat2('', value.x, value.y,
            { extraFlags = { EnterReturnsTrue = true } })
        return value, changed
    end,
})

-- Editor for 'rgb[a]' tables
table.insert(tableEditors, {
    match = core.types.shape({
        r = core.types.number,
        g = core.types.number,
        b = core.types.number,
        a = core.types.number:is_optional(),
    }),
    editor = function(value)
        local changed
        if value.a then -- Has alpha?
            value.r, value.g, value.b, value.a, changed = tui.colorEdit4('',
                value.r, value.g, value.b, value.a, {
                    AlphaBar = true,
                    Float = true,
                    PickerHueWheel = true,
                })
        else
            value.r, value.g, value.b, changed = tui.colorEdit3('',
                value.r, value.g, value.b, {
                    Float = true,
                    PickerHueWheel = true,
                })
        end
        return value, changed
    end,
})

-- Table: choose from `tableEditors`
function propEditors.table(value)
    for _, entry in ipairs(tableEditors) do
        if entry.match(value) then
            return entry.editor(value)
        end
    end

    -- Nothing matched
    tui.alignTextToFramePadding()
    tui.text('<unsupported>')
    return nil, false
end

-- Common prop value editor entrypoint dispatches to one of the above based on type. Takes the
-- current value. Returns `new`, `changed`. If the value was edited, `new` is the `new` value and
-- `changed` is `true`. If the value was unchanged, `changed` is `false`.
local function propEditor(value)
    local propEditor = propEditors[getmetatable(value)] or propEditors[type(value)]
    if propEditor then
        local new, changed
        tui.withItemWidth(-1, function()
            new, changed = propEditor(value)
        end)
        return new, changed
    else
        tui.alignTextToFramePadding()
        tui.text('<unsupported>')
        return value, false
    end
end


-- Editor for component with name `key` in entity `ent`
function EditorTUI:editComponent(ent, key)
    local comp = ent[key]

    -- Collect prop names
    local propNames = {}
    for propName in pairs(comp) do propNames[propName] = true end
    if comp.__info.props then
        for propName in pairs(comp.__info.props) do propNames[propName] = true end
    end

    for propName in pairs(propNames) do
        -- Check if hidden prop
        local hidden = self.hiddenProps[propName] -- Known common hidden props
                or core.entity.componentTypes[propName] -- Component dependency shortcut
                or propName:match('^_') -- Starts with '_'
        if not hidden then
            tui.withID(propName, function()
                -- Label for prop name
                tui.alignTextToFramePadding()
                tabbedText(propName)
                tui.sameLine()

                -- Editor for prop value
                local new, changed = propEditor(comp[propName])
                if changed then comp[propName] = new end
            end)
        end
    end
end

-- Editor for a single entity
function EditorTUI:editEntity(ent)
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

-- Editors for selected entities
function EditorTUI:editSelectedEntities()
    local first = next(self.Editor.selected)
    if first then
        if not next(self.Editor.selected, first) then
            -- Single entity selected, just show an editor for that
            self:editEntity(first)
        else
            -- Multiple entities selected, show multiple sections
            for ent in pairs(self.Editor.selected) do
                if tui.collapsingHeader(ent.Default.id) then
                    tui.inChildResizable(ent.Default.id, function()
                        self:editEntity(ent)
                    end)
                end
            end
        end
    end
end


-- Selectable list of all entities
function EditorTUI:listAllEntities()
    local selected = self.Editor.selected
    for ent, default in pairs(core.entity.componentTypes.Default:getAll()) do
        if not ent.Default.hidden then
            -- Highlight if already selected
            if tui.selectable(default.id, selected[ent]) then
                -- Toggle on click
                if selected[ent] then
                    selected[ent] = nil
                else
                    selected[ent] = true
                end
            end
        end
    end
end


-- Selectable list of modes as buttons
function EditorTUI:showModeButtons()
    -- Collect map of mode -> binding, or mode -> `false` if no binding
    local bindings = {}
    for _, button in pairs(self.modeButtons) do
        bindings[button.mode] = false
    end
    for binding, mapping in pairs(self.Editor.bindings.all or {}) do
        local maybeMode = mapping:gsub('%.enter', '') -- Mapping would be '<mode>' or '<mode>.enter'
        if bindings[maybeMode] ~= nil then
            bindings[maybeMode] = binding
        end
    end

    local nModeButtons = #self.modeButtons
    for i = 1, nModeButtons do
        local button = self.modeButtons[i]

        -- Use active button color if already in mode
        local r, g, b, a = tui.getStyleColorVec4(self.Editor.mode == button.mode and
                'ButtonHovered' or 'Button')
        tui.withStyleColor('Button', r, g, b, a, function()
            local buttonText = button.icon
            if bindings[button.mode] then
                buttonText = buttonText .. ' (' .. bindings[button.mode] .. ')'
            end
            if tui.button(buttonText) then
                -- Toggle mode on click
                self.Editor:enterMode(self.Editor.mode == button.mode and 'none' or button.mode)
            end
        end)

        -- All buttons on same line
        if i < nModeButtons then
            tui.sameLine()
        end
    end
end


function EditorTUI:update(dt)
    tui.inWindow('editor', function()
        -- Main editor window layout

        self:showModeButtons()

        tui.separator()

        tui.inChildResizable('entities', function()
            self:listAllEntities()
        end)

        tui.inChild('selected', function()
            self:editSelectedEntities()
        end)
    end)
end
