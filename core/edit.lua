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
    self.selection = {} -- Selected entities as keys
end

function Editor:remove()
    singleton = nil
end


function Editor:update(...)
    if not self.enabled then return end

    for dependent in pairs(self.__dependents) do
        if dependent.update then
            dependent:update(...)
        end
    end
end


function Editor:draw(...)
    if not self.enabled then return end

    for dependent in pairs(self.__dependents) do
        if dependent.drawOverlay then
            dependent:drawOverlay(...)
        end
    end
end


function Editor:keypressed(key)
    if key == 'e' and (love.keyboard.isDown('lctrl') or love.keyboard.isDown('rctrl')) then
        self.enabled = not self.enabled
    end
end

function Editor:mousepressed(x, y, button)
    if not tui.wantMouse() then
        -- TODO(nikki): Select by click
    end
end


