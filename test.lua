local love_functions = {
    "love.arg.parseGameArguments",
    "love.audio",
    "love.audio.newSource",
    "love.audio.play",
    "love.audio.stop",
    "love.conf",
    "love.data.compress",
    "love.data.decompress",
    "love.draw",
    "love.errhand",
    "love.event",
    "love.event.poll",
    "love.event.pump",
    "love.event.quit",
    "love.filesystem",
    "love.filesystem.append",
    "love.filesystem.createDirectory",
    "love.filesystem.getDirectoryItems",
    "love.filesystem.getInfo",
    "love.filesystem.read",
    "love.filesystem.remove",
    "love.filesystem.write",
    "love.gamepadpressed",
    "love.gamepadreleased",
    "love.graphics",
    "love.graphics.clear",
    "love.graphics.dis",
    "love.graphics.draw",
    "love.graphics.getHeight",
    "love.graphics.getWidth",
    "love.graphics.isActive",
    "love.graphics.isCreated",
    "love.graphics.newCanvas",
    "love.graphics.newFont",
    "love.graphics.newImage",
    "love.graphics.newQuad",
    "love.graphics.newShader",
    "love.graphics.newText",
    "love.graphics.newVideo",
    "love.graphics.origin",
    "love.graphics.polygon",
    "love.graphics.pop",
    "love.graphics.present",
    "love.graphics.print",
    "love.graphics.printf",
    "love.graphics.push",
    "love.graphics.rectangle",
    "love.graphics.reset",
    "love.graphics.rotate",
    "love.graphics.scale",
    "love.graphics.setCanvas",
    "love.graphics.setColor",
    "love.graphics.setDefaultFilter",
    "love.graphics.setLineStyle",
    "love.graphics.setLineWidth",
    "love.graphics.setNewFont",
    "love.graphics.setShader",
    "love.graphics.translate",
    "love.handlers",
    "love.joystick",
    "love.joystick.getJoysticks",
    "love.joystick.loadGamepadMappings",
    "love.joystickaxis",
    "love.keypressed",
    "love.keyreleased",
    "love.load",
    "love.load.",
    "love.mouse",
    "love.mouse.getPosition",
    "love.mouse.isVisible",
    "love.mouse.setGrabbed",
    "love.mouse.setRelativeMode",
    "love.mouse.setVisible",
    "love.mousemoved",
    "love.mousepressed",
    "love.mousereleased",
    "love.quit",
    "love.resize",
    "love.run",
    "love.sound",
    "love.system",
    "love.system.getClipboardText",
    "love.system.getOS",
    "love.system.openURL",
    "love.system.setClipboardText",
    "love.thread",
    "love.thread.getChannel",
    "love.thread.newThread",
    "love.timer",
    "love.timer.getFPS",
    "love.timer.getTime",
    "love.timer.sleep",
    "love.timer.step",
    "love.touch.getTouches",
    "love.update",
    "love.window",
    "love.window.getDesktopDimensions",
    "love.window.getDisplayCount",
    "love.window.getFullscreenModes",
    "love.window.getMode",
    "love.window.getTitle",
    "love.window.isOpen",
    "love.window.setMode",
    "love.window.showMessageBox",
    "love.window.toPixels",
    "love.window.updateMode"
}

local log = {}

local function safe_call(func, ...)
    local ok, err = pcall(func, ...)
    if not ok then
        table.insert(log, tostring(err))
    end
end

local function get_func_by_path(path)
    local t = _G
    for part in string.gmatch(path, "[%w_]+") do
        t = t[part]
        if not t then return nil end
    end
    return t
end

function love.load()
    for _, fname in ipairs(love_functions) do
        local func = get_func_by_path(fname)
        if type(func) == "function" then
            -- Zkusíme zavolat s bezpečnými argumenty podle názvu
            if fname:find("newSource") then
                safe_call(func, "", "static")
            elseif fname:find("newImage") then
                safe_call(func, "")
            elseif fname:find("newFont") then
                safe_call(func, 12)
            elseif fname:find("newCanvas") then
                safe_call(func, 16, 16)
            elseif fname:find("newQuad") then
                safe_call(func, 0,0,1,1,1,1)
            elseif fname:find("newShader") then
                safe_call(func, "void main(){}")
            elseif fname:find("newText") then
                safe_call(func, love.graphics.getFont(), "test")
            elseif fname:find("newVideo") then
                safe_call(func, "")
            elseif fname:find("newThread") then
                safe_call(func, "return 1")
            elseif fname:find("getChannel") then
                safe_call(func, "test")
            elseif fname:find("append") or fname:find("write") then
                safe_call(func, "test.txt", "data")
            elseif fname:find("read") then
                safe_call(func, "test.txt")
            elseif fname:find("remove") then
                safe_call(func, "test.txt")
            elseif fname:find("createDirectory") then
                safe_call(func, "testdir")
            elseif fname:find("setCanvas") then
                safe_call(func, nil)
            elseif fname:find("setColor") then
                safe_call(func, 1,1,1,1)
            elseif fname:find("setLineWidth") then
                safe_call(func, 1)
            elseif fname:find("setLineStyle") then
                safe_call(func, "smooth")
            elseif fname:find("setShader") then
                safe_call(func, nil)
            elseif fname:find("setNewFont") then
                safe_call(func, 12)
            elseif fname:find("setDefaultFilter") then
                safe_call(func, "nearest", "nearest")
            elseif fname:find("setGrabbed") or fname:find("setRelativeMode") or fname:find("setVisible") then
                safe_call(func, false)
            elseif fname:find("showMessageBox") then
                safe_call(func, "title", "msg")
            elseif fname:find("setMode") then
                safe_call(func, 100, 100)
            elseif fname:find("toPixels") then
                safe_call(func, 0,0)
            elseif fname:find("openURL") then
                safe_call(func, "about:blank")
            elseif fname:find("setClipboardText") then
                safe_call(func, "test")
            elseif fname:find("sleep") then
                safe_call(func, 0)
            elseif fname:find("step") then
                safe_call(func)
            elseif fname:find("draw") then
                -- skip, needs drawable
            elseif fname:find("print") then
                safe_call(func, "test")
            elseif fname:find("printf") then
                safe_call(func, "test", 0, 0, 100)
            elseif fname:find("polygon") then
                safe_call(func, "fill", 0,0, 1,1, 2,2)
            elseif fname:find("rectangle") then
                safe_call(func, "fill", 0,0, 1,1)
            else
                safe_call(func)
            end
        else
            table.insert(log, fname .. " is not a function or not found")
        end
    end

    -- Zapiš log do souboru
    local f = love.filesystem.newFile("log.txt", "w")
    f:write(table.concat(log, "\n"))
    f:close()
    love.event.quit()
end