local Input = core.entity.newComponentType('Input')


-- Names of Love callbacks that are input-related
Input.callbackNames = {
    --    directorydropped = true,
    --    draw = true,
    --    errhand = true,
    --    errorhandler = true,
    --    filedropped = true,
    --    focus = true,
    keypressed = true,
    keyreleased = true,
    --    lowmemory = true,
    mousefocus = true,
    mousemoved = true,
    mousepressed = true,
    mousereleased = true,
    --    quit = true,
    --    resize = true,
    --    run = true,
    textedited = true,
    textinput = true,
    --    threaderror = true,
    touchmoved = true,
    touchpressed = true,
    touchreleased = true,
    --    update = true,
    --    visible = true,
    wheelmoved = true,
    gamepadaxis = true,
    gamepadpressed = true,
    gamepadreleased = true,
    joystickadded = true,
    joystickaxis = true,
    joystickhat = true,
    joystickpressed = true,
    joystickreleased = true,
    joystickremoved = true,
}

-- `listeners[cb][comp] == true` iff. component instance `comp` has a method for callback
-- `cb` and depends on `Input`
local listeners = {}
for cb in pairs(Input.callbackNames) do -- Initialize to empty for every callback
    listeners[cb] = {}
end


function Input:add()
    self.enabled = false
end


-- Keep track of listeners

function Input:addDependent(dependentType)
    local dependent = self.ent[dependentType]
    for cb in pairs(Input.callbackNames) do
        if dependent[cb] then
            listeners[cb][dependent] = true
        end
    end
end

function Input:removeDependent(dependentType)
    local dependent = self.ent[dependentType]
    for cb in pairs(Input.callbackNames) do
        -- We do this for all callbacks, not just the ones it has a method for, just to be sure
        -- (eg. maybe a method got unset for whatever reason)
        listeners[cb][dependent] = nil
    end
end


-- Makes 'static' methods `keypressedAll`, `mousepressedAll`, etc.
for cb in pairs(Input.callbackNames) do
    Input[cb .. 'All'] = function(self, ...)
        for listener in pairs(listeners[cb]) do
            if listener.Input.enabled then
                listener[cb](listener, ...)
            end
        end
    end
end
