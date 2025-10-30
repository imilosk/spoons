local obj = {}
obj.__index = obj

-- Metadata
obj.name = "DailyWallpaper"
obj.version = "0.1"
obj.author = "imilosk"
obj.homepage = "https://github.com/imilosk/spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.logger = hs.logger.new('DailyWallpaper')
obj.wallpaperDir = os.getenv("HOME") .. "/.hammerspoon/wallpapers/daily/"
obj.apiUrl = "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=en-US"

-- Timer configuration
obj.updateInterval = 900 -- 15 minutes in seconds
obj._timer = nil

function obj:init()
    self.logger.i("Initializing DailyWallpaper spoon")
    return self
end

function obj:start()
    self.logger.i("Starting DailyWallpaper spoon")

    self:_setTodaysWallpaper()

    -- Start timer to set wallpaper every 15 minutes
    self._timer = hs.timer.doEvery(self.updateInterval, function()
        self:_setTodaysWallpaper()
    end)
    self.logger.i("Wallpaper timer started - setting wallpaper every " .. (self.updateInterval / 60) .. " minutes")

    return self
end

function obj:stop()
    self.logger.i("Stopping DailyWallpaper spoon")

    -- Stop the timer
    if self._timer then
        self._timer:stop()
        self._timer = nil
        self.logger.i("Wallpaper timer stopped")
    end

    return self
end

function obj:_setTodaysWallpaper()
    self:_ensureWallpaperDirectory()
    self:downloadWallpaper()
end

function obj:_ensureWallpaperDirectory()
    if not hs.fs.attributes(self.wallpaperDir) then
        self:_createDirectoryRecursive(self.wallpaperDir)
        self.logger.i("Created wallpaper directory: " .. self.wallpaperDir)
    else
        self.logger.d("Wallpaper directory already exists: " .. self.wallpaperDir)
    end
end

function obj:_createDirectoryRecursive(path)
    path = path:gsub("/$", "")

    local command = "mkdir -p '" .. path .. "'"
    local output, status = hs.execute(command)

    if status then
        self.logger.i("Successfully created directory path: " .. path)
        return true
    else
        self.logger.e("Failed to create directory path: " .. path .. " - " .. (output or "unknown error"))
        return false
    end
end

function obj:downloadWallpaper()
    self.logger.i("Fetching wallpaper metadata from Bing API")

    hs.http.asyncGet(self.apiUrl, nil, function(status, body, headers)
        if status == 200 then
            self:_processApiResponse(body)
        else
            self.logger.e("Failed to fetch wallpaper metadata. HTTP status: " .. status)
        end
    end)
end

function obj:_processApiResponse(body)
    local success, data = pcall(hs.json.decode, body)

    if not success or not data or not data.images or #data.images == 0 then
        self.logger.e("Failed to parse API response or no images found")
        return
    end

    local imageData = data.images[1]
    local urlbase = imageData.urlbase
    local title = imageData.title or "Unknown"
    local hash = imageData.hsh

    if not hash then
        self.logger.e("No hash found in API response")
        return
    end

    self.logger.i("Found wallpaper: " .. title .. " (hash: " .. hash .. ")")

    local imageUrl = "https://www.bing.com" .. urlbase .. "_UHD.jpg"
    local fallbackUrl = "https://www.bing.com" .. urlbase .. "_1920x1080.jpg"

    self:_downloadWallpaperImage(imageUrl, fallbackUrl, title, hash)
end

function obj:_downloadWallpaperImage(imageUrl, fallbackUrl, title, hash)
    local filename = hash .. ".jpg"
    local dir = self.wallpaperDir:gsub("/$", "") .. "/"
    local filepath = dir .. filename

    -- Check if file with this hash already exists
    if hs.fs.attributes(filepath) then
        self.logger.i("Wallpaper with hash " .. hash .. " already exists: " .. filepath)
        self:_setWallpaper(filepath)
        return
    end

    self.logger.i("Downloading new wallpaper: " .. filename)

    hs.http.asyncGet(imageUrl, nil, function(status, body, headers)
        if status == 200 then
            self:_saveWallpaper(body, filepath, title, false)
        else
            self.logger.w("UHD download failed (status: " .. status .. "), trying fallback resolution")
            hs.http.asyncGet(fallbackUrl, nil, function(status2, body2, headers2)
                if status2 == 200 then
                    self:_saveWallpaper(body2, filepath, title, false)
                else
                    self.logger.e("Both UHD and fallback downloads failed")
                end
            end)
        end
    end)
end

function obj:_saveWallpaper(imageData, filepath, title, wasOverwrite)
    local file = io.open(filepath, "wb")
    if file then
        file:write(imageData)
        file:close()
        self.logger.i("Wallpaper saved: " .. filepath)

        -- Set as wallpaper for all screens
        self:_setWallpaper(filepath)

        hs.notify.new({
            title = "Daily Wallpaper",
            informativeText = "Set wallpaper: " .. title,
            withdrawAfter = 3
        }):send()
    else
        self.logger.e("Failed to save wallpaper to: " .. filepath)
    end
end

function obj:_setWallpaper(filepath)
    local screens = hs.screen.allScreens()

    for _, screen in ipairs(screens) do
        screen:desktopImageURL("file://" .. filepath)
    end

    self.logger.i("Wallpaper set for " .. #screens .. " screen(s): " .. filepath)
end

return obj
