function love.conf(t)
    t.console = true
    t.window.title = "Balatro (Debug Build)"
    
    -- Wii U specific settings
    t.window.width = 854
    t.window.height = 480
    t.window.fullscreen = false
    t.window.highdpi = false
    
    -- Wii U font/UI scale fix
    -- Force much smaller scale for better text visibility on Wii U
    t.window.scale = 0.15  -- Very small scale for visible text
    
    print("[CONF.LUA] Window size set to " .. t.window.width .. "x" .. t.window.height)
end
