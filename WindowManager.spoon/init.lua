local obj = {}
obj.__index = obj

-- Metadata
obj.name = "WindowManager"
obj.version = "0.1"
obj.author = "imilosk"
obj.homepage = "https://github.com/imilosk/"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.logger = hs.logger.new('WindowManager')

obj.defaultHotkeys = {
    left_half = { { "ctrl", "alt" }, "left" },
    right_half = { { "ctrl", "alt" }, "right" },
    top_half = { { "ctrl", "alt" }, "up" },
    bottom_half = { { "ctrl", "alt" }, "down" },
    maximize = { { "ctrl", "alt" }, "return" },
    center = { { "ctrl", "alt" }, "c" },
    top_left = { { "ctrl", "alt" }, "u" },
    top_right = { { "ctrl", "alt" }, "i" },
    bottom_left = { { "ctrl", "alt" }, "j" },
    bottom_right = { { "ctrl", "alt" }, "k" },
}

function obj:init()
    self.logger.i("Initializing WindowManager")
    return self
end

function obj:start()
    self.logger.i("Starting WindowManager")
    hs.window.animationDuration = 0
    return self
end

function obj:stop()
    self.logger.i("Stopping WindowManager")
    return self
end

function obj:leftHalf()
    local win = hs.window.focusedWindow()
    if win then
        local f = win:frame()
        local screen = win:screen()
        local max = screen:frame()

        f.x = max.x
        f.y = max.y
        f.w = max.w / 2
        f.h = max.h
        win:setFrame(f)
    end
    return self
end

function obj:rightHalf()
    local win = hs.window.focusedWindow()
    if win then
        local f = win:frame()
        local screen = win:screen()
        local max = screen:frame()

        f.x = max.x + (max.w / 2)
        f.y = max.y
        f.w = max.w / 2
        f.h = max.h
        win:setFrame(f)
    end
    return self
end

function obj:topHalf()
    local win = hs.window.focusedWindow()
    if win then
        local f = win:frame()
        local screen = win:screen()
        local max = screen:frame()

        f.x = max.x
        f.y = max.y
        f.w = max.w
        f.h = max.h / 2
        win:setFrame(f)
    end
    return self
end

function obj:bottomHalf()
    local win = hs.window.focusedWindow()
    if win then
        local f = win:frame()
        local screen = win:screen()
        local max = screen:frame()

        f.x = max.x
        f.y = max.y + (max.h / 2)
        f.w = max.w
        f.h = max.h / 2
        win:setFrame(f)
    end
    return self
end

function obj:maximize()
    local win = hs.window.focusedWindow()
    if win then
        local screen = win:screen()
        local screenFrame = screen:frame()
        local currentFrame = win:frame()

        local isMaximized = (
            math.abs(currentFrame.x - screenFrame.x) < 10 and
            math.abs(currentFrame.y - screenFrame.y) < 10 and
            math.abs(currentFrame.w - screenFrame.w) < 20 and
            math.abs(currentFrame.h - screenFrame.h) < 20
        )

        if isMaximized then
            local newFrame = win:frame()
            newFrame.w = screenFrame.w * 0.75
            newFrame.h = screenFrame.h * 0.75
            win:setFrame(newFrame)
            self:center()
        else
            win:maximize()
        end
    end
    return self
end

function obj:center()
    local win = hs.window.focusedWindow()
    if win then
        win:centerOnScreen()
    end
    return self
end

function obj:topLeft()
    local win = hs.window.focusedWindow()
    if win then
        local f = win:frame()
        local screen = win:screen()
        local max = screen:frame()

        f.x = max.x
        f.y = max.y
        f.w = max.w / 2
        f.h = max.h / 2
        win:setFrame(f)
    end
    return self
end

function obj:topRight()
    local win = hs.window.focusedWindow()
    if win then
        local f = win:frame()
        local screen = win:screen()
        local max = screen:frame()

        f.x = max.x + (max.w / 2)
        f.y = max.y
        f.w = max.w / 2
        f.h = max.h / 2
        win:setFrame(f)
    end
    return self
end

function obj:bottomLeft()
    local win = hs.window.focusedWindow()
    if win then
        local f = win:frame()
        local screen = win:screen()
        local max = screen:frame()

        f.x = max.x
        f.y = max.y + (max.h / 2)
        f.w = max.w / 2
        f.h = max.h / 2
        win:setFrame(f)
    end
    return self
end

function obj:bottomRight()
    local win = hs.window.focusedWindow()
    if win then
        local f = win:frame()
        local screen = win:screen()
        local max = screen:frame()

        f.x = max.x + (max.w / 2)
        f.y = max.y + (max.h / 2)
        f.w = max.w / 2
        f.h = max.h / 2
        win:setFrame(f)
    end
    return self
end

function obj:bindHotkeys(mapping)
    local def = {
        left_half = function() self:leftHalf() end,
        right_half = function() self:rightHalf() end,
        top_half = function() self:topHalf() end,
        bottom_half = function() self:bottomHalf() end,
        maximize = function() self:maximize() end,
        center = function() self:center() end,
        top_left = function() self:topLeft() end,
        top_right = function() self:topRight() end,
        bottom_left = function() self:bottomLeft() end,
        bottom_right = function() self:bottomRight() end,
    }
    hs.spoons.bindHotkeysToSpec(def, mapping)
    return self
end

return obj
