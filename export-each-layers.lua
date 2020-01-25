local spr = app.activeSprite

local path, title = spr.filename:match("^(.+[/\\])(.-).([^.]*)$")

local msg = {"Do you want to export/overwrite the following files?"}

for i, layer in ipairs(spr.layers) do
    local fn = path .. title .. '-' .. layer.name
    table.insert(msg, '-' .. fn .. '.png')
end

if app.alert {
    title = "Export Sprite Sheets",
    text = msg,
    buttons = {"&Yes", "&No"}
} ~= 1 then return end

for i, layer in ipairs(spr.layers) do
    local fn = path .. '/' .. title .. '-' .. layer.name

    app.command.ExportSpriteSheet {
        ui = false,
        type = SpriteSheetType.HORIZONTAL,
        textureFilename = fn .. '.png',
        layer = layer.name,
        listLayers = false,
        listTags = false,
        listSlices = false
    }
end
