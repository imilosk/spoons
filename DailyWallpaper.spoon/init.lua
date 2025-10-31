local obj = {}
obj.__index = obj

-- Metadata
obj.name = "DailyWallpaper"
obj.version = "1.0"
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

    self.logger.i("Found wallpaper: " .. title)

    local imageUrl = "https://www.bing.com" .. urlbase .. "_UHD.jpg"
    local fallbackUrl = "https://www.bing.com" .. urlbase .. "_1920x1080.jpg"

    self:_downloadWallpaperImage(imageUrl, fallbackUrl, title)
end

function obj:_downloadWallpaperImage(imageUrl, fallbackUrl, title)
    local filename = os.date("%Y-%m-%d") .. ".jpg"
    local dir = self.wallpaperDir:gsub("/$", "") .. "/"
    local filepath = dir .. filename

    self.logger.i("Downloading wallpaper for hash comparison: " .. filename)

    hs.http.asyncGet(imageUrl, nil, function(status, body, headers)
        if status == 200 then
            self:_checkHashAndSave(body, filepath, title)
        else
            self.logger.w("UHD download failed (status: " .. status .. "), trying fallback resolution")
            hs.http.asyncGet(fallbackUrl, nil, function(status2, body2, headers2)
                if status2 == 200 then
                    self:_checkHashAndSave(body2, filepath, title)
                else
                    self.logger.e("Both UHD and fallback downloads failed")
                end
            end)
        end
    end)
end

function obj:_checkHashAndSave(imageData, filepath, title)
    local newHash = self:_calculateHash(imageData)
    self.logger.d("New image hash: " .. newHash)

    -- Check if today's file already exists
    local todayFileExists = hs.fs.attributes(filepath)
    local existingHash = nil

    if todayFileExists then
        existingHash = self:_getFileHash(filepath)
        self.logger.d("Existing file hash: " .. (existingHash or "unknown"))

        if existingHash == newHash then
            self.logger.i("Today's wallpaper already exists and is current: " .. filepath)
            self:_setWallpaper(filepath)
            return
        else
            self.logger.i("Today's wallpaper exists but is outdated, will override")
        end
    end

    -- Check if we already have this image elsewhere
    local existingFile = self:_findImageByHash(newHash)

    if existingFile and existingFile ~= filepath then
        self.logger.i("Image with same hash already exists: " .. existingFile)
        self.logger.i("Creating symlink instead of duplicate download")

        -- Remove existing file if it exists (since we're overriding)
        if todayFileExists then
            os.remove(filepath)
            self.logger.i("Removed outdated file: " .. filepath)
        end

        -- Create symlink to existing file
        local command = "ln -sf '" .. existingFile .. "' '" .. filepath .. "'"
        local output, status = hs.execute(command)

        if status then
            self.logger.i("Created symlink: " .. filepath .. " -> " .. existingFile)
            self:_setWallpaper(filepath)

            hs.notify.new({
                title = "Daily Wallpaper",
                informativeText = "Reusing existing wallpaper: " .. title,
                withdrawAfter = 3
            }):send()
        else
            self.logger.e("Failed to create symlink, saving as new file instead")
            self:_saveWallpaper(imageData, filepath, title)
            self:_storeImageHash(filepath, newHash)
        end
    else
        -- Save new image and store its hash (this will override existing file if needed)
        self:_saveWallpaper(imageData, filepath, title)
        self:_storeImageHash(filepath, newHash)

        -- If we had an old hash for this file, clean it up from the database
        if existingHash and existingHash ~= newHash then
            self:_removeHashFromDatabase(existingHash)
        end
    end
end

function obj:_calculateHash(data)
    -- Use Hammerspoon's built-in hash function
    return hs.hash.SHA256(data)
end

function obj:_getHashFilePath()
    return self.wallpaperDir:gsub("/$", "") .. "/hashes.json"
end

function obj:_loadHashDatabase()
    local hashFile = self:_getHashFilePath()

    if not hs.fs.attributes(hashFile) then
        return {}
    end

    local file = io.open(hashFile, "r")
    if not file then
        return {}
    end

    local content = file:read("*all")
    file:close()

    local success, data = pcall(hs.json.decode, content)
    return success and data or {}
end

function obj:_saveHashDatabase(hashDb)
    local hashFile = self:_getHashFilePath()
    local file = io.open(hashFile, "w")

    if file then
        file:write(hs.json.encode(hashDb))
        file:close()
        return true
    end

    return false
end

function obj:_storeImageHash(filepath, hash)
    local hashDb = self:_loadHashDatabase()
    hashDb[hash] = filepath

    if self:_saveHashDatabase(hashDb) then
        self.logger.d("Stored hash for: " .. filepath)
    else
        self.logger.w("Failed to store hash for: " .. filepath)
    end
end

function obj:_findImageByHash(hash)
    local hashDb = self:_loadHashDatabase()
    local filepath = hashDb[hash]

    -- Verify the file still exists
    if filepath and hs.fs.attributes(filepath) then
        return filepath
    elseif filepath then
        -- File was deleted, remove from hash database
        hashDb[hash] = nil
        self:_saveHashDatabase(hashDb)
    end

    return nil
end

function obj:_getFileHash(filepath)
    -- Check if it's a symlink first
    local command = "readlink '" .. filepath .. "'"
    local output, status = hs.execute(command)

    if status then
        -- It's a symlink, get the target file's hash
        local targetFile = output:gsub("%s+$", "") -- trim whitespace
        return self:_getFileHash(targetFile)
    end

    -- Read the actual file and calculate its hash
    local file = io.open(filepath, "rb")
    if not file then
        self.logger.w("Could not open file for hash calculation: " .. filepath)
        return nil
    end

    local content = file:read("*all")
    file:close()

    if content then
        return self:_calculateHash(content)
    end

    return nil
end

function obj:_removeHashFromDatabase(hash)
    local hashDb = self:_loadHashDatabase()
    if hashDb[hash] then
        hashDb[hash] = nil
        if self:_saveHashDatabase(hashDb) then
            self.logger.d("Removed old hash from database: " .. hash)
        else
            self.logger.w("Failed to remove old hash from database")
        end
    end
end

function obj:_saveWallpaper(imageData, filepath, title)
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
