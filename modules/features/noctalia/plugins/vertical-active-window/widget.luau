-- The plugin UI has no rotation primitive. Noctalia renders this SVG at the
-- widget's logical size, retaining sharp text on scaled displays.
local busy = false
local previous = nil
local lastError = nil
local icons = {}
local names = {}
local runtime = noctalia.getenv("XDG_RUNTIME_DIR")
local output = (barWidget.outputName() or "default"):gsub("[^%w_-]", "_")
local imagePath = runtime and (runtime .. "/noctalia-active-window-" .. output .. ".svg")

local function xml(value)
    return (value:gsub("[%z\1-\8\11\12\14-\31]", "")
        :gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
        :gsub('"', "&quot;"):gsub("'", "&apos;"))
end

local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function base64(data)
    local result = {}
    for i = 1, #data, 3 do
        local a, b, c = data:byte(i, i + 2)
        local value = a * 65536 + (b or 0) * 256 + (c or 0)
        local function digit(shift)
            local index = math.floor(value / shift) % 64 + 1
            return alphabet:sub(index, index)
        end
        result[#result + 1] = digit(262144) .. digit(4096)
            .. (b and digit(64) or "=") .. (c and digit(1) or "=")
    end
    return table.concat(result)
end

local function iconData(appId)
    if icons[appId] ~= nil then return icons[appId] end
    local path = noctalia.appIconPath(appId, 32)
    local data = path and noctalia.readFile(path)
    local uri = ""
    if data and #data < 131072 then
        local mime = path:lower():match("%.svg$") and "image/svg+xml" or "image/png"
        uri = "data:" .. mime .. ";base64," .. base64(data)
    end
    icons[appId] = uri
    return uri
end

local function report(message)
    if message ~= lastError then noctalia.log(message) end
    lastError = message
    previous = nil
    barWidget.setVisible(false)
end

local function appName(appId)
    if names[appId] then return names[appId] end
    local dirs = (noctalia.getenv("XDG_DATA_HOME")
        or ((noctalia.getenv("HOME") or "~") .. "/.local/share"))
        .. ":" .. (noctalia.getenv("XDG_DATA_DIRS") or "/run/current-system/sw/share:/usr/local/share:/usr/share")
    for dir in dirs:gmatch("[^:]+") do
        local desktop = noctalia.readFile(dir .. "/applications/" .. appId .. ".desktop")
        if not desktop then
            for _, file in ipairs(noctalia.listDir(dir .. "/applications") or {}) do
                if file:lower() == appId:lower() .. ".desktop" then
                    desktop = noctalia.readFile(dir .. "/applications/" .. file)
                    break
                end
            end
        end
        if desktop then
            local entry = desktop:match("%[Desktop Entry%]([^%[]+)") or ""
            local name = entry:match("\nName=([^\r\n]+)")
            if name then names[appId] = name; return name end
        end
    end
    local name = (appId:match("([^%.]+)$") or appId):gsub("[-_]", " ")
        :gsub("(%a)([%w]*)", function(first, rest) return first:upper() .. rest end)
    names[appId] = name
    return name
end

local function resolveColor(value, fallback)
    if not value or value == "" then value = fallback end
    return value:sub(1, 1) == "#" and value
        or noctalia.getColor(value) or "#ffffff"
end

-- Estimate logical text width without a renderer dependency. The widget grows
-- to accommodate the entire title; there is no length cap or ellipsis.
local function fitTitle(title)
    local chars, used = {}, 0
    for _, code in utf8.codes(title) do
        local char = utf8.char(code)
        local size = 8.5
        if char:match("[ilI%.,'!| ]") then size = 4
        elseif char:match("[MW@%%]") or code > 0x2fff then size = 13 end
        chars[#chars + 1] = char
        used = used + size
    end
    return table.concat(chars), math.max(40, math.ceil(used + 8))
end

barWidget.setVisible(false)
noctalia.setUpdateInterval(250)

function update()
    if busy then return end
    if not imagePath then
        report("XDG_RUNTIME_DIR is unavailable; this widget needs a running Niri session")
        return
    end
    busy = true
    local launched = noctalia.runAsync({
        noctalia.getenv("NOCTALIA_PLUGIN_NIRI") or "niri", "msg", "-j", "focused-window",
    }, function(result)
        busy = false
        if result.exitCode ~= 0 then
            report("Cannot read focused Niri window: " .. result.stderr)
            return
        end
        local window, err = noctalia.json.decode(result.stdout)
        if err then report("Invalid Niri response: " .. err); return end
        lastError = nil
        if type(window) ~= "table" then
            previous = nil
            barWidget.setVisible(false)
            return
        end
        local appId = window.app_id or ""
        local title = appName(appId)
        local widget = noctalia.getSetting("widget.vertical_active_window") or {}
        local bar = noctalia.getSetting("bar.min-vertical") or {}
        local capsule = widget.capsule
        if capsule == nil then capsule = bar.capsule end
        local foreground = capsule and (widget.capsule_foreground or bar.capsule_foreground) or nil
        local colorRole = widget.color or bar.color or foreground
        local color = resolveColor(colorRole, "on_surface")
        -- App artwork can have an opaque background. Tinting it with the
        -- capsule foreground turns the whole icon into a solid square.
        local iconRole = widget.icon_color or bar.icon_color
        local iconColor = iconRole and resolveColor(iconRole, "on_surface") or ""
        local family = widget.font_family
        if not family or family == "" then family = bar.font_family end
        if not family or family == "" then family = noctalia.getSetting("shell.font_family") or "sans-serif" end
        local weight = tonumber(widget.font_weight) or tonumber(bar.font_weight) or 400
        local fontScale = (tonumber(widget.font_scale) or 1) * (tonumber(bar.font_scale) or 1)
        local fontSize = 14 * fontScale
        local rotation = tonumber(noctalia.getConfig("rotation")) == -90 and -90 or 90
        local key = noctalia.json.encode({title, appId, color, family, rotation, iconColor, weight, fontSize})
        if key == previous then return end
        local icon = iconData(appId)
        -- Always vertical: isVertical() can report false during bar layout.
        local label, length = fitTitle(title)
        length = math.ceil((length - 8) * fontScale + 8)
        local padding, gap = 4, 12
        local width = math.max(20, math.ceil(fontSize * 1.5))
        local height = length + 16 + gap + padding * 2
        local transform = rotation == 90
            and string.format("translate(%d %d) rotate(90)", width, padding + 16 + gap)
            or string.format("translate(0 %d) rotate(-90)", height - padding)
        local tint = iconColor ~= "" and ' filter="url(#icon-tint)"' or ""
        local svg = string.format(
            '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="%d" height="%d" viewBox="0 0 %d %d">'
            .. '<defs><clipPath id="title"><rect width="%d" height="%d"/></clipPath>'
            .. '<filter id="icon-tint" color-interpolation-filters="sRGB"><feFlood flood-color="%s"/><feComposite in2="SourceAlpha" operator="in"/></filter></defs>'
            .. '<image x="%g" y="4" width="16" height="16" xlink:href="%s"%s/>'
            .. '<g transform="%s"><text x="4" y="%g" textLength="%d" lengthAdjust="spacingAndGlyphs" font-family="%s" font-size="%g" font-weight="%d" fill="%s" clip-path="url(#title)">%s</text></g></svg>',
            width, height, width, height, length, width, xml(iconColor ~= "" and iconColor or "#ffffff"),
            (width - 16) / 2, icon, tint, transform, (width + fontSize * 0.7) / 2,
            length - 8, xml(family), fontSize, weight, xml(color), xml(label)
        )
        local ok, writeError = noctalia.writeFile(imagePath, svg)
        if not ok then report("Cannot write widget SVG: " .. tostring(writeError)); return end
        barWidget.setImage(imagePath, true, width, height)
        barWidget.setText("")
        barWidget.setTooltip(title)
        barWidget.setVisible(true)
        previous = key
    end)
    if not launched then
        busy = false
        report("Could not start the Niri query")
    end
end
