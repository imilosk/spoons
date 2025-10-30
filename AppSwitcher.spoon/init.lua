local obj = {}
obj.__index = obj

-- Metadata
obj.name = "AppSwitcher"
obj.version = "1.0"
obj.author = "imilosk"
obj.homepage = "https://github.com/imilosk/spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.logger = hs.logger.new('AppSwitcher')

obj._appWatcher = nil
obj._lastActivatedApp = nil

function obj:init()
    self.logger.i("Initializing AppSwitcher spoon")
    return self
end

function obj:start()
    self.logger.i("Starting AppSwitcher spoon - enhancing native Cmd+Tab")

    -- Watch for application activation events
    self._appWatcher = hs.application.watcher.new(function(appName, eventType, appObject)
        if eventType == hs.application.watcher.activated then
            self:_handleAppActivation(appObject)
        end
    end)

    self._appWatcher:start()
    self.logger.i("Application watcher started")

    return self
end

function obj:stop()
    self.logger.i("Stopping AppSwitcher spoon")

    if self._appWatcher then
        self._appWatcher:stop()
        self._appWatcher = nil
        self.logger.i("Application watcher stopped")
    end

    return self
end

function obj:_handleAppActivation(app)
    if not app or not app:bundleID() then
        return
    end

    -- Skip if this is the same app as before (avoid loops)
    if self._lastActivatedApp == app:bundleID() then
        return
    end

    self._lastActivatedApp = app:bundleID()

    self.logger.d("App activated: " .. (app:title() or "Unknown"))

    -- Small delay to ensure the activation is complete
    hs.timer.doAfter(0.05, function()
        self:_ensureAppVisibility(app)
    end)
end

function obj:_ensureAppVisibility(app)
    if not app then
        return
    end

    local wasHidden = app:isHidden()
    local hadMinimizedWindows = false

    local windows = app:allWindows()
    for _, window in ipairs(windows) do
        if window:isMinimized() then
            hadMinimizedWindows = true
            break
        end
    end

    if not wasHidden and not hadMinimizedWindows then
        return
    end

    self.logger.i("Ensuring visibility for: " .. (app:title() or "Unknown"))

    if wasHidden then
        self.logger.d("Unhiding application: " .. (app:title() or "Unknown"))
        app:unhide()
    end

    if hadMinimizedWindows then
        for _, window in ipairs(windows) do
            if window:isMinimized() then
                self.logger.d("Unminimizing window: " .. (window:title() or "Unknown"))
                window:unminimize()
            end
        end
    end

    hs.timer.doAfter(0.1, function()
        app:activate(true) -- Force activation

        local mainWindow = app:mainWindow()
        if mainWindow then
            mainWindow:focus()
            mainWindow:raise()
        end
    end)
end

return obj
