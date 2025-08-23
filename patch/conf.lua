function love.conf(t)
    t.console = true
    t.window.title = "Balatro (Debug Build)"
    
    -- Wii U specific settings
    t.window.width = 800
    t.window.height = 600
    t.window.fullscreen = false
    t.window.highdpi = false
    
    --scale
    t.window.scale = 0.1
    
    print("[CONF.LUA] Window size set to " .. t.window.width .. "x" .. t.window.height)
end
