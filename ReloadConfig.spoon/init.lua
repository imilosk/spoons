local obj = {}
obj.__index = obj

-- Metadata
obj.name = "ReloadConfig"
obj.version = "1.0"
obj.author = "imilosk"
obj.homepage = "https://github.com/imilosk/spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.logger = hs.logger.new('ReloadConfig')

-- Default hotkey configuration
obj.defaultHotkeys = {
    reload = { { "ctrl", "alt", "cmd" }, "r" }
}

function obj:init()
    self.logger.i("Initializing ReloadConfig spoon")
    return self
end

function obj:start()
    self.logger.i("Starting ReloadConfig spoon")
    return self
end

function obj:stop()
    self.logger.i("Stopping ReloadConfig spoon")
    return self
end

function obj:reload()
    self.logger.i("Reloading Hammerspoon configuration")
    hs.reload()
    return self
end

function obj:bindHotkeys(mapping)
    local def = {
        reload = function() self:reload() end
    }
    hs.spoons.bindHotkeysToSpec(def, mapping)
    return self
end

return obj
