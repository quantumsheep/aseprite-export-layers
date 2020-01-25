local spr = app.activeSprite

local spr_path, spr_title = spr.filename:match("^(.+[/\\])(.-).([^.]*)$")

local dlg = Dialog()
dlg:file{
    id = "output",
    label = "Output:",
    filename = spr_path .. spr_title .. '.png',
    filetypes = {"png", "jpg", "jpeg"}
}
dlg:check{id = "trim", label = "Trim:"}
dlg:button{id = "ok", text = "OK"}
dlg:button{id = "cancel", text = "Cancel"}
dlg:show()

local data = dlg.data

function fullpath(path, name, layer, extension)
    return path .. name .. '-' .. layer.name .. '.' .. extension
end

if data.ok then
    local path, name, extension = data.output:match("^(.+[/\\])(.-).([^.]*)$")

    local msg = {"Do you want to export/overwrite the following files?"}

    for _, layer in ipairs(spr.layers) do
        table.insert(msg, '- ' .. fullpath(path, name, layer, extension))
    end

    if app.alert {
        title = "Export Sprite Sheets",
        text = msg,
        buttons = {"&Yes", "&No"}
    } ~= 1 then return end

    for _, layer in ipairs(spr.layers) do
        app.command.ExportSpriteSheet {
            ui = false,
            type = SpriteSheetType.HORIZONTAL,
            textureFilename = fullpath(path, name, layer, extension),
            layer = layer.name,
            listLayers = false,
            listTags = false,
            listSlices = false,
            trim = data.trim
        }
    end
end
