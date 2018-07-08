-- Base component that all editing-related components depend on to add features to the editor.
-- Must be added to at most one entity--the editor itself. Makes sure that events the
-- editing-related components subscribe to are only fired when edit mode is enabled.

local Edit = core.entity.newComponentType('Edit', {
    depends = { 'Input', 'Update', 'Visual' },
})


-- The singleton instance, if exists
local singleton

function Edit:add()
    if singleton then
        error("'Edit' component must be added to at most one entity -- the editor itself!")
    end
    singleton = self

    -- Dependency config
    self.Input.enabled = true -- Always listen for `Input` to allow edit-mode hotkey
    self.Visual:setDepth(1000) -- Draw editor overlays in front of everything else

    -- State
    self.enabled = false -- Whether we are in edit-mode
    self.selection = {} -- Selected entities as keys
end

function Edit:remove()
    singleton = nil
end


function Edit:update(...)
    if not self.enabled then return end

    for dependent in pairs(self.__dependents) do
        if dependent.update then
            dependent:update(...)
        end
    end
end


function Edit:draw(...)
    if not self.enabled then return end

    for dependent in pairs(self.__dependents) do
        if dependent.drawOverlay then
            dependent:drawOverlay(...)
        end
    end
end


function Edit:keypressed(key)
    if key == 'e' and (love.keyboard.isDown('lctrl') or love.keyboard.isDown('rctrl')) then
        self.enabled = not self.enabled
    end
end

function Edit:mousepressed(x, y, button)
    if not tui.wantMouse() then
        -- TODO(nikki): Select by click
    end
end


