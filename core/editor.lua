-- Base component that all editing-related components depend on to add features to the editor.
-- Must be added to at most one entity--the editor itself. Makes sure that events the
-- editing-related components subscribe to are only fired when edit mode is enabled.

local Editor = core.entity.newComponentType('Editor', {
    depends = { 'Input', 'Update', 'Visual' },
})


-- The singleton instance, if exists
local singleton

function Editor:add()
    if singleton then
        error("'Editor' component must be added to at most one entity -- the editor itself!")
    end
    singleton = self

    -- Dependency config
    self.Input.enabled = true -- Always listen for `Input` to allow edit-mode hotkey
    self.Visual:setDepth(1000) -- Draw editor overlays in front of everything else

    -- State
    self.enabled = false -- Whether we are in edit-mode
    self.mode = 'default' -- Current mode
    self.bindings = {} -- Table of mode -> binding -> mapping
    self.selected = {} -- Currently selected entities as keys
end

function Editor:remove()
    singleton = nil
end


-- Call a function on all dependents in current mode
function Editor:forwardEvent(evtName, ...)
    if not self.enabled then return end

    -- For now, go through all dependents to handle `dependent.mode == 'all'` cases
    for dependent in pairs(self.__dependents) do
        if (dependent.mode == 'all' or dependent.mode == self.mode or
                dependent.__typeName == self.mode) and dependent[evtName] then
            dependent[evtName](dependent, ...)
        end
    end
end


function Editor:update(...)
    -- Remove destroyed entities from `self.selected`
    for ent in pairs(self.selected) do
        if ent.destroyed then
            self.selected[ent] = nil
        end
    end

    self:forwardEvent('update', ...)
end


function Editor:draw(...)
    self:forwardEvent('drawOverlay', ...)
end


local modifiers = {
    'numlock',
    'capslock',
    'scrolllock',
    'rgui',
    'lgui',
    'rctrl',
    'lctrl',
    'rshift',
    'lshift',
    'ralt',
    'lalt',
    'mode',
}

-- Generate the binding given the final suffix (key or mouse button name) by prepending modifier
-- key names
local function genBinding(suffix)
    local prefix = ''
    for _, mod in pairs(modifiers) do
        if love.keyboard.isDown(mod) then
            if #prefix > 0 then
                prefix = prefix .. '_'
            end
            prefix = prefix .. mod:gsub('^l', ''):gsub('^r', '') -- Remove 'l' or 'r' prefix
        end
    end
    if #prefix > 0 then
        prefix = prefix .. '_'
    end
    return prefix .. suffix
end

-- Execute the mapping for `binding`, passing it the extra parameters given
function Editor:executeBinding(binding, ...)
    -- Special case: Is this the main toggle binding? If so, toggle and abort.
    if binding == self.bindings.mainToggle then
        self.enabled = not self.enabled
        return
    end

    -- Editor disabled?
    if not self.enabled then return end

    -- Find the mapping
    local modeMappings = self.bindings[self.mode]
    if not modeMappings then return end
    local mapping = modeMappings[binding]

    -- Split the '<component>.<member>' format
    if not mapping then return end
    local componentName = mapping:match('^[^.]*')
    local memberName = mapping:match('[^.]*$')

    -- If just '<member>' format, component name is mode name
    if componentName == memberName then
        componentName = self.mode
    end

    -- Find the component instance and the member, then execute it
    local component = self.ent[componentName]
    if not component then
        error("component '" .. componentName .. "' not found for editor binding '" ..
                binding .. "'")
    end
    local member = component[memberName]
    if not member then
        if memberName == 'enter' or memberName == 'exit' then
            -- Default to no-op for 'enter' and 'exit' events
            member = function() end
        else
            error("'" .. componentName "' doesn't have a member '" .. member .. "' for editor " ..
                    "binding '" .. binding .. "'")
        end
    end

    -- 'enter' and 'exit' events should set / unset `mode`
    if memberName == 'enter' then
        self.mode = componentName
    end
    local succeeded, err = pcall(member, component, ...)
    if memberName == 'exit' then
        self.mode = 'default'
    end
    if not succeeded then error(err, 0) end
end

function Editor:keypressed(key, scancode, isrepeat, ...)
    if tui.wantKeyboard() then return end
    if isrepeat then return end -- Repeat keypress? (while key is held down)
    self:executeBinding(genBinding(key) .. '_pressed', key, scancode, isrepeat, ...)
    self:executeBinding(genBinding(key), key, scancode, isrepeat, ...)
end

function Editor:keyreleased(key, ...)
    if tui.wantKeyboard() then return end
    self:executeBinding(genBinding(key) .. '_released', key, ...)
end

function Editor:mousepressed(x, y, button, ...)
    if tui.wantMouse() then return end
    self:executeBinding(genBinding('mouse' .. tostring(button)) .. '_pressed', x, y, button, ...)
    self:executeBinding(genBinding('mouse' .. tostring(button)), x, y, button, ...)
end

function Editor:mousereleased(x, y, button, ...)
    if tui.wantMouse() then return end
    self:executeBinding(genBinding('mouse' .. tostring(button)) .. '_released', x, y, button, ...)
end

function Editor:mousemoved(...)
    if tui.wantMouse() then return end
    for button = 1, 3 do
        if love.mouse.isDown(button) then
            self:executeBinding(genBinding('mouse' .. tostring(button) .. 'dragged'), ...)
        end
    end
    self:executeBinding(genBinding('mousemoved'), ...)
end

function Editor:wheelmoved(...)
    if tui.wantMouse() then return end
    self:executeBinding(genBinding('wheelmoved'), ...)
end

