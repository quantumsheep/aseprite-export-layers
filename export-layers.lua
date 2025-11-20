local spr = app.activeSprite
if not spr then
    app.alert("No active sprite.")
    return
end

--- Split full path into directory, name, extension
---@param filepath string
local function splitPath(filepath)
    if filepath == nil then
        return "", "sprite", "png"
    end

    -- Try: dir + name + .ext
    local dir, name, ext = filepath:match("^(.-)([^/\\]+)%.([^%.\\/]*)$")
    if not dir then
        -- Fallback: dir + name (no extension)
        dir, name = filepath:match("^(.-)([^/\\]+)$")
    end
    return dir or "", name or "sprite", ext or "png"
end

local spr_path, spr_title, spr_ext = splitPath(spr.filename)

--- Ensure sprite is saved on disk
local function ensureSpriteOnDisk(sprite)
    if spr_path ~= "" and spr_path ~= nil and spr_title ~= "" and spr_title ~= nil then
        return true
    end

    app.alert("Sprite must be saved before exporting layers.")
    app.command.SaveFileAs()

    spr_path, spr_title, spr_ext = splitPath(spr.filename)
    return spr_path ~= "" and spr_path ~= nil and spr_title ~= "" and spr_title ~= nil
end

if not ensureSpriteOnDisk(spr) then
    return
end

-- Build dialog
local dlg = Dialog {
    title = "Export Layers as Sprite Sheets"
}
dlg:file{
    id = "output",
    label = "Output:",
    filename = spr_path .. spr_title .. ".png",
    filetypes = {"png", "jpg", "jpeg"}
}
dlg:entry{
    id = "separator",
    label = "Layer name separator:",
    text = "-"
}
dlg:combobox{
    id = "case",
    label = "Filename case:",
    option = "Original",
    options = {"Original", "UPPERCASE", "lowercase"}
}
dlg:check{
    id = "trim",
    label = "Trim:",
    selected = false
}
dlg:check{
    id = "visibleOnly",
    label = "Only visible layers:",
    selected = true
}
dlg:check{
    id = "ignoreGroups",
    label = "Skip group layers:",
    selected = true
}
dlg:newrow()
dlg:button{
    id = "ok",
    text = "Export"
}
dlg:button{
    id = "cancel",
    text = "Cancel"
}
dlg:show()

local data = dlg.data
if not data.ok then
    return
end

local path, baseName, extension = splitPath(data.output)
if extension == "" or not extension then
    extension = "png"
end

--- Sanitize layer name so it can be used as a filename
---@param layerName string
local function sanitizeName(layerName)
    -- Replace forbidden filename chars, collapse whitespace and apply case option
    layerName = layerName:gsub('[\\/:*?"<>|]', "_")
    layerName = layerName:gsub("%s+", "_")

    if data.case == "UPPERCASE" then
        layerName = layerName:upper()
    elseif data.case == "lowercase" then
        layerName = layerName:lower()
    end

    return layerName
end

--- Get full path for layer
local function fullpath(layer)
    return path .. baseName .. data.separator .. sanitizeName(layer.name) .. "." .. extension
end

-- Collect layers according to options
local exportLayers = {}

---@param layers any[]
local function collectLayers(layers)
    for _, layer in ipairs(layers) do
        if (not data.visibleOnly or layer.isVisible) then
            if layer.isGroup then
                if not data.ignoreGroups then
                    table.insert(exportLayers, layer)
                end

                collectLayers(layer.layers)
            else
                table.insert(exportLayers, layer)
            end
        end
    end
end

collectLayers(spr.layers)

if #exportLayers == 0 then
    app.alert("No layers to export with the current options.")
    return
end

local msg = {"Do you want to export/overwrite the following files?"}
for _, layer in ipairs(exportLayers) do
    table.insert(msg, "- " .. fullpath(layer))
end

if app.alert {
    title = "Export Sprite Sheets",
    text = msg,
    buttons = {"&Yes", "&No"}
} ~= 1 then
    return
end

for _, layer in ipairs(exportLayers) do
    app.command.ExportSpriteSheet {
        ui = false,
        type = SpriteSheetType.HORIZONTAL,
        textureFilename = fullpath(layer),
        layer = layer.name,
        listLayers = false,
        listTags = false,
        listSlices = false,
        trim = data.trim
    }
end
