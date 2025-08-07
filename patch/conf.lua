function love.conf(t)
    t.console = true
    t.window.title = "Balatro (Debug Build)"
    
    -- Wii U specific settings
    t.window.width = 1920
    t.window.height = 1080
    t.window.fullscreen = true
    t.window.highdpi = false
    
    --scale
    t.window.scale = 1
    
    print("[CONF.LUA] Window size set to " .. t.window.width .. "x" .. t.window.height)
end
