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
    -- Disable window animations for instant movement
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
        win:maximize()
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
        left_half = self.leftHalf,
        right_half = self.rightHalf,
        top_half = self.topHalf,
        bottom_half = self.bottomHalf,
        maximize = self.maximize,
        center = self.center,
        top_left = self.topLeft,
        top_right = self.topRight,
        bottom_left = self.bottomLeft,
        bottom_right = self.bottomRight,
    }
    hs.spoons.bindHotkeysToSpec(def, mapping)
    return self
end

return obj
