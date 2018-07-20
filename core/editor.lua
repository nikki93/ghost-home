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


function Editor:update(...)
    if not self.enabled then return end

    -- Remove destroyed entities from `self.selected`
    for ent in pairs(self.selected) do
        if ent.destroyed then
            self.selected[ent] = nil
        end
    end

    -- Forward to dependents
    for dependent in pairs(self.__dependents) do
        if dependent.update then
            dependent:update(...)
        end
    end
end


function Editor:draw(...)
    if not self.enabled then return end

    -- Forward to dependents
    for dependent in pairs(self.__dependents) do
        if dependent.drawOverlay then
            dependent:drawOverlay(...)
        end
    end
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

-- Execute the mapping for `binding`, passing it the extra parameters given.
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

    -- Find the component instance and the member, then execute it
    local component = self.ent[componentName]
    if not component then
        error("component '" .. componentName .. "' not found for editor binding '" ..
                binding .. "'")
    end
    local member = component[memberName]
    if not component then
        error("'" .. componentName "' doesn't have a member '" .. member .. "' for editor " ..
                "binding '" .. binding .. "'")
    end
    member(component, ...)
end

-- Execute a key binding with the given suffix for Love callback parameters -- skipping if the
-- editor doesn't have keyboard focus
function Editor:executeKeyBinding(suffix, key, scancode, isrepeat)
    if tui.wantKeyboard() then return end -- TUI has hold of keyboard?
    if isrepeat then return end -- Repeat keypress? (while key is held down)
    self:executeBinding(genBinding(key) .. suffix, key, scancode, isrepeat)
end

-- Execute a mouse binding with the given suffix for Love callback parameters -- skipping if the
-- editor doesn't have mouse focus
function Editor:executeMouseBinding(suffix, x, y, button, istouch)
    if tui.wantMouse() then return end -- TUI has hold of mouse?
    self:executeBinding(genBinding('mouse' .. tostring(button)) .. suffix, x, y, button, istouch)
end

function Editor:keypressed(...)
    self:executeKeyBinding('_pressed', ...)
    self:executeKeyBinding('', ...)
end

function Editor:keyreleased(...)
    self:executeKeyBinding('_released', ...)
end

function Editor:mousepressed(...)
    self:executeMouseBinding('_pressed', ...)
    self:executeMouseBinding('', ...)
end

function Editor:mousereleased(...)
    self:executeMouseBinding('_released', ...)
end

function Editor:mousemoved(...)
    if not self.enabled then return end

    -- Forward to dependents
    for dependent in pairs(self.__dependents) do
        if dependent.mousemoved then
            dependent:mousemoved(...)
        end
    end
end

