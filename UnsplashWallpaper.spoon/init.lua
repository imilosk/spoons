--- === UnsplashWallpaper ===
---
--- Daily Unsplash wallpaper
---
--- Download: clone https://github.com/imilosk/UnsplashWallpaper.spoon/

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "UnsplashWallpaper"
obj.version = "1.0"
obj.author = "imilosk"
obj.homepage = "https://github.com/imilosk/UnsplashWallpaper.spoon"
obj.license = "MIT - https://opensource.org/licenses/MIT"

--- UnsplashWallpaper.access_key
--- Variable
--- Your Unsplash API access key. Required for the spoon to work.
obj.access_key = nil

--- UnsplashWallpaper.wallpaper_dir
--- Variable
--- Directory to store wallpaper files. Defaults to ~/.hammerspoon/wallpapers
obj.wallpaper_dir = nil

--- UnsplashWallpaper.collections
--- Variable
--- Comma-separated Unsplash collection IDs to fetch wallpapers from. Defaults to "880012"
obj.collections = "880012"

--- UnsplashWallpaper.update_interval
--- Variable
--- Interval in seconds to check for new wallpapers. Defaults to 1 hour (3600 seconds)
obj.update_interval = 3600

--- UnsplashWallpaper.cleanup_days
--- Variable
--- Number of days to keep wallpapers before cleanup. Defaults to 30
obj.cleanup_days = 30

--- UnsplashWallpaper.timer
--- Variable
--- Internal timer object for periodic wallpaper updates
obj.timer = nil

--- UnsplashWallpaper.logger
--- Variable
--- Logger instance for this spoon
obj.logger = hs.logger.new('UnsplashWallpaper')

--- UnsplashWallpaper:init()
--- Method
--- Initializes the spoon
---
--- Returns:
---  * The UnsplashWallpaper object
function obj:init()
    -- Set default wallpaper directory
    if not self.wallpaper_dir then
        self.wallpaper_dir = os.getenv("HOME") .. "/.hammerspoon/wallpapers"
    end
    
    -- Ensure directory exists
    hs.fs.mkdir(self.wallpaper_dir)
    
    return self
end

--- UnsplashWallpaper:start()
--- Method
--- Starts the wallpaper updater
---
--- Returns:
---  * The UnsplashWallpaper object
function obj:start()
    if not self.access_key then
        self.logger.e("Access key is required. Set UnsplashWallpaper.access_key before calling start()")
        return self
    end
    
    self.logger.i("Starting UnsplashWallpaper")
    
    -- Start timer for periodic updates
    if self.timer == nil then
        self.timer = hs.timer.doEvery(self.update_interval, function()
            self:setOrDownloadTodaysWallpaper()
        end)
        -- Set wallpaper after 5 seconds, then continue with regular interval
        self.timer:setNextTrigger(5)
    else
        self.timer:start()
    end
    
    return self
end

--- UnsplashWallpaper:stop()
--- Method
--- Stops the wallpaper updater
---
--- Returns:
---  * The UnsplashWallpaper object
function obj:stop()
    self.logger.i("Stopping UnsplashWallpaper")
    
    if self.timer then
        self.timer:stop()
        self.timer = nil
    end
    
    return self
end

--- UnsplashWallpaper:setWallpaperNow()
--- Method
--- Manually trigger wallpaper update
---
--- Returns:
---  * The UnsplashWallpaper object
function obj:setWallpaperNow()
    self:setOrDownloadTodaysWallpaper()
    return self
end

--- UnsplashWallpaper:cleanupOldWallpapers()
--- Method
--- Manually clean up old wallpaper files
---
--- Returns:
---  * The UnsplashWallpaper object
function obj:cleanupOldWallpapers()
    self:_cleanupOldWallpapers(self.cleanup_days)
    return self
end

-- Private methods

function obj:_findTodaysExistingImagePath()
    local today = os.date("%Y-%m-%d")
    local todayPattern = "^" .. today:gsub("%-", "%%-") .. ".*%.jpg$"
    for file in hs.fs.dir(self.wallpaper_dir) do
        if type(file) == "string" and file:match(todayPattern) then
            return self.wallpaper_dir .. "/" .. file
        end
    end
    return nil
end

function obj:_newTodaysImagePath(uniqueHash)
    local basename = os.date("%Y-%m-%d") .. "-" .. tostring(uniqueHash) .. ".jpg"
    return self.wallpaper_dir .. "/" .. basename
end

function obj:_setWallpaperAllSpaces(filePath)
    local esc = filePath:gsub("\\", "\\\\"):gsub('"', '\\"')
    local osa = ([[tell application "System Events"
        repeat with d in desktops
            set picture of d to "%s"
        end repeat
    end tell]]):format(esc)
    local ok, _, err = hs.osascript.applescript(osa)
    if not ok then
        self.logger.e("Failed to set wallpaper: " .. tostring(err))
        hs.notify.new({title="Wallpaper Error", informativeText=tostring(err)}):send()
    end
end

function obj:_bestImageURL(data)
    local function maxScreenWidth()
        local maxW = 3840
        for _, s in ipairs(hs.screen.allScreens()) do
            local f = s:frame()
            if f.w > maxW then maxW = math.floor(f.w) end
        end
        return maxW
    end
    local w = maxScreenWidth()

    if data.urls and data.urls.raw then
        local sep = data.urls.raw:find("?", 1, true) and "&" or "?"
        return string.format("%s%sw=%d&q=90&fm=jpg&fit=max", data.urls.raw, sep, w)
    elseif data.urls and data.urls.full then
        local sep = data.urls.full:find("?", 1, true) and "&" or "?"
        return string.format("%s%sw=%d", data.urls.full, sep, w)
    elseif data.urls and data.urls.regular then
        return data.urls.regular
    end
    return nil
end

function obj:_politelyRegisterDownload(data)
    if data and data.links and data.links.download_location then
        hs.http.asyncGet(
            data.links.download_location .. "&client_id=" .. self.access_key,
            { ["Accept-Version"] = "v1" },
            function() end
        )
    end
end

function obj:_cleanupOldWallpapers(keepDays)
    keepDays = keepDays or 30
    local cutoffTime = os.time() - (keepDays * 24 * 60 * 60)
    local cleaned = 0
    
    for file in hs.fs.dir(self.wallpaper_dir) do
        if type(file) == "string" and file:match("%.jpg$") then
            local filePath = self.wallpaper_dir .. "/" .. file
            local attrs = hs.fs.attributes(filePath)
            if attrs and attrs.modification < cutoffTime then
                local success = os.remove(filePath)
                if success then
                    cleaned = cleaned + 1
                    self.logger.d("Removed old wallpaper: " .. file)
                end
            end
        end
    end
    
    if cleaned > 0 then
        self.logger.i(string.format("Cleaned up %d old wallpaper(s)", cleaned))
        hs.notify.new({title="Wallpaper Cleanup", informativeText=string.format("Removed %d old wallpaper(s)", cleaned)}):send()
    end
end

function obj:setOrDownloadTodaysWallpaper()
    -- Clean up old wallpapers
    self:_cleanupOldWallpapers(self.cleanup_days)
    
    -- 1) Reuse today's image if it exists
    local existing = self:_findTodaysExistingImagePath()
    if existing and hs.fs.attributes(existing) then
        self.logger.i("Using existing wallpaper: " .. existing)
        self:_setWallpaperAllSpaces(existing)
        return
    end

    -- 2) Otherwise fetch a new one from Unsplash
    local api_url = string.format("https://api.unsplash.com/photos/random?collections=%s&orientation=landscape&client_id=%s", 
                                  self.collections, self.access_key)
    
    hs.http.asyncGet(api_url, { ["Accept-Version"] = "v1" }, function(status, body)
        if status ~= 200 then
            self.logger.e("Unsplash API error: " .. tostring(status))
            hs.notify.new({title="Unsplash API Error", informativeText="Status: " .. tostring(status)}):send()
            return
        end

        local ok, data = pcall(hs.json.decode, body)
        if not ok or type(data) ~= "table" then
            self.logger.e("JSON parse error")
            hs.notify.new({title="JSON Parse Error", informativeText="Unexpected API response"}):send()
            return
        end

        local imageURL = self:_bestImageURL(data)
        if not imageURL then
            self.logger.e("No image URL found in response")
            hs.notify.new({title="No Image URL", informativeText="Missing urls in response"}):send()
            return
        end

        self:_politelyRegisterDownload(data)

        hs.http.asyncGet(imageURL, nil, function(imgStatus, imgBody)
            if imgStatus ~= 200 then
                self.logger.e("Image download failed: " .. tostring(imgStatus))
                hs.notify.new({title="Download Failed", informativeText="Status: " .. tostring(imgStatus)}):send()
                return
            end

            -- Generate unique hash for filename
            local rawHash = (data.id and tostring(data.id)) or (hs.host.uuid and hs.host.uuid()) or tostring(os.time())
            local uniqueHash = rawHash:gsub("[^%w]", ""):sub(1, 8)
            if uniqueHash == "" then uniqueHash = tostring(os.time() % 100000000) end

            local path = self:_newTodaysImagePath(uniqueHash)

            local f = io.open(path, "wb")
            if not f then
                self.logger.e("Cannot write wallpaper file: " .. path)
                hs.notify.new({title="File Error", informativeText="Cannot write wallpaper file"}):send()
                return
            end
            f:write(imgBody); f:close()

            self:_setWallpaperAllSpaces(path)

            local by = (data.user and (data.user.name or data.user.username)) or "Unknown"
            local filename = path:match("([^/]+)$") or path
            self.logger.i("Wallpaper updated: " .. filename .. " by " .. by)
            hs.notify.new({
                title = "Wallpaper Updated",
                informativeText = string.format("Saved as %s\nPhoto by %s on Unsplash", filename, by)
            }):send()
        end)
    end)
end

return obj