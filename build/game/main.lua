--debug
function wiiu_log(msg)
    if love.filesystem then
        love.filesystem.append("log.txt", os.date("[%H:%M:%S] ") .. tostring(msg) .. "\n")
    end
end

-- Přesměrování print na wiiu_log
print = wiiu_log

wiiu_log("Hra spuštěna!")
-- Logování všech načítaných assetů
--local old_newImage = love.graphics.newImage
--love.graphics.newImage = function(path, ...)
    --wiiu_log("Načítám obrázek: " .. tostring(path))
    --return old_newImage(path, ...)
--end

if newSource then
    if newSource then
        local old_newSource = love.audio.newSource
        love.audio.newSource = function(path, ...)
            wiiu_log("Načítám zvuk: " .. tostring(path))
            return old_newSource(path, ...)
        end
    end
end
local old_newFont = love.graphics.newFont
love.graphics.newFont = function(path, ...)
    wiiu_log("Načítám font: " .. tostring(path))
    return old_newFont(path, ...)
end

function love.errorhandler(msg)
    local trace = debug.traceback(msg, 2)
    wiiu_log("ERROR: " .. trace)
    return false
end
--konec debug
require "engine/object"
require "engine/node"
require "engine/moveable"
require "engine/sprite"
require "engine/animatedsprite"
require "bit"
require "engine/string_packer"
require "engine/controller"
require "back"
require "tag"
require "engine/event"
require "functions/misc_functions"
require "game"
require "globals"
require "engine/ui"
require "functions/UI_definitions"
require "functions/state_events"
require "functions/common_events"
require "functions/button_callbacks"
require "functions/misc_functions"
require "functions/test_functions"
require "card"
require "cardarea"
require "blind"
require "card_character"
require "engine/particles"
require "engine/text"
require "challenges"
require "test_runner"

math.randomseed(G.SEED)

function love.run()
    if love.load then love.load(love.arg.parseGameArguments(arg), arg) end
    if love.timer then love.timer.step() end
    local dt = 0
    local dt_smooth = 1/100
    local run_time = 0
    return function()
        run_time = love.timer.getTime()
        if love.event and G and G.CONTROLLER then
            love.event.pump()
            local _n,_a,_b,_c,_d,_e,_f,touched
            for name, a,b,c,d,e,f in love.event.poll() do
                if name == "quit" then
                    if not love.quit or not love.quit() then
                        return a or 0
                    end
                end
                if name == 'touchpressed' then
                    touched = true
                elseif name == 'mousepressed' then
                    _n,_a,_b,_c,_d,_e,_f = name,a,b,c,d,e,f
                else
                    love.handlers[name](a,b,c,d,e,f)
                end
            end
            if _n then
                love.handlers['mousepressed'](_a,_b,_c,touched)
            end
        end
        if love.timer then dt = love.timer.step() end
        dt_smooth = math.min(0.8*dt_smooth + 0.2*dt, 0.1)
        if love.update then love.update(dt_smooth) end
        if love.graphics and love.graphics.isActive() then
            if love.draw then love.draw() end
            love.graphics.present()
        end
        run_time = math.min(love.timer.getTime() - run_time, 0.1)
        G.FPS_CAP = G.FPS_CAP or 500
        if run_time < 1./G.FPS_CAP then love.timer.sleep(1./G.FPS_CAP - run_time) end
    end
end

function love.load()
    G:start_up()
    if mouse then
        if mouse then
            love.mouse.setVisible(false)
        end
    end
end

function love.quit()
    if G.SOUND_MANAGER then G.SOUND_MANAGER.channel:push({type = 'stop'}) end
    -- steam_shutdown() je mock, pokud ho chceš, přidej funkci steam_shutdown() jako prázdnou
end

function love.update(dt)
    timer_checkpoint(nil, 'update', true)
    G:update(dt)
end

function love.draw()
    timer_checkpoint(nil, 'draw', true)
    G:draw()
end

function love.keypressed(key)
    if not _RELEASE_MODE and G.keybind_mapping[key] then
        love.gamepadpressed(G.CONTROLLER.keyboard_controller, G.keybind_mapping[key])
    else
        G.CONTROLLER:set_HID_flags('mouse')
        G.CONTROLLER:key_press(key)
    end
end

function love.keyreleased(key)
    if not _RELEASE_MODE and G.keybind_mapping[key] then
        love.gamepadreleased(G.CONTROLLER.keyboard_controller, G.keybind_mapping[key])
    else
        G.CONTROLLER:set_HID_flags('mouse')
        G.CONTROLLER:key_release(key)
    end
end

function love.gamepadpressed(joystick, button)
    button = G.button_mapping[button] or button
    G.CONTROLLER:set_gamepad(joystick)
    G.CONTROLLER:set_HID_flags('button', button)
    G.CONTROLLER:button_press(button)
end

function love.gamepadreleased(joystick, button)
    button = G.button_mapping[button] or button
    G.CONTROLLER:set_gamepad(joystick)
    G.CONTROLLER:set_HID_flags('button', button)
    G.CONTROLLER:button_release(button)
end

if mouse then
    if mouse then
        function love.mousepressed(x, y, button, touch)
    end
end
    G.CONTROLLER:set_HID_flags(touch and 'touch' or 'mouse')
    if button == 1 then G.CONTROLLER:queue_L_cursor_press(x, y) end
    if button == 2 then G.CONTROLLER:queue_R_cursor_press(x, y) end
end

if mouse then
    if mouse then
        function love.mousereleased(x, y, button)
    end
end
    if button == 1 then G.CONTROLLER:L_cursor_release(x, y) end
end

if mouse then
    if mouse then
        function love.mousemoved(x, y, dx, dy, istouch)
    end
end
    G.CONTROLLER.last_touch_time = G.CONTROLLER.last_touch_time or -1
    if touch then
        if touch then
            if next(love.touch.getTouches()) ~= nil then
        end
    end
        G.CONTROLLER.last_touch_time = G.TIMERS.UPTIME
    end
    G.CONTROLLER:set_HID_flags(G.CONTROLLER.last_touch_time > G.TIMERS.UPTIME - 0.2 and 'touch' or 'mouse')
end

function love.joystickaxis(joystick, axis, value)
    if math.abs(value) > 0.2 and joystick:isGamepad() then
        G.CONTROLLER:set_gamepad(joystick)
        G.CONTROLLER:set_HID_flags('axis')
    end
end

function love.resize(w, h)
    if w/h < 1 then
        h = w/1
    end
    if w/h < G.window_prev.orig_ratio then
        G.TILESCALE = G.window_prev.orig_scale*w/G.window_prev.w
    else
        G.TILESCALE = G.window_prev.orig_scale*h/G.window_prev.h
    end
    if G.ROOM then
        G.ROOM.T.w = G.TILE_W
        G.ROOM.T.h = G.TILE_H
        G.ROOM_ATTACH.T.w = G.TILE_W
        G.ROOM_ATTACH.T.h = G.TILE_H
        if w/h < G.window_prev.orig_ratio then
            G.ROOM.T.x = G.ROOM_PADDING_W
            G.ROOM.T.y = (h/(G.TILESIZE*G.TILESCALE) - (G.ROOM.T.h+G.ROOM_PADDING_H))/2 + G.ROOM_PADDING_H/2
        else
            G.ROOM.T.y = G.ROOM_PADDING_H
            G.ROOM.T.x = (w/(G.TILESIZE*G.TILESCALE) - (G.ROOM.T.w+G.ROOM_PADDING_W))/2 + G.ROOM_PADDING_W/2
        end
        G.ROOM_ORIG = {
            x = G.ROOM.T.x,
            y = G.ROOM.T.y,
            r = G.ROOM.T.r
        }
        if G.buttons then G.buttons:recalculate() end
        if G.HUD then G.HUD:recalculate() end
    end
    G.WINDOWTRANS = {
        x = 0, y = 0,
        w = G.TILE_W+2*G.ROOM_PADDING_W,
        h = G.TILE_H+2*G.ROOM_PADDING_H,
        real_window_w = w,
        real_window_h = h
    }
    G.CANV_SCALE = 1
    if newCanvas then
        if newCanvas then
            G.CANVAS = love.graphics.newCanvas(w*G.CANV_SCALE, h*G.CANV_SCALE, {type = '2d', readable = true})
        end
    end
    G.CANVAS:setFilter('linear', 'linear')
end