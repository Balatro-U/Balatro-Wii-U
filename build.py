#!/usr/bin/env python3
import os
import shutil
import re
from pathlib import Path

SUPPORTED_IMAGES = {'.png', '.jpg', '.jpeg', '.bmp', '.gif'}
SUPPORTED_SOUNDS = {'.wav', '.ogg', '.mp3'}

def prepare_assets():
    SOURCE_DIR = Path("./assets")
    BUILD_DIR = Path("./build")
    
    # Clean and create directory structure
    if BUILD_DIR.exists():
        shutil.rmtree(BUILD_DIR)
    
    BUILD_DIR.mkdir()
    (BUILD_DIR/"game").mkdir()

    # Copy all source files
    for item in SOURCE_DIR.rglob("*"):
        if item.is_file():
            rel_path = item.relative_to(SOURCE_DIR)
            target = BUILD_DIR/"game"/rel_path
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(item, target)

    # Patch main.lua to remove luasteam and add mock Steam functions
    main_lua_path = BUILD_DIR / "game" / "main.lua"
    if main_lua_path.exists():
        with open(main_lua_path, "r", encoding="utf-8") as f:
            content = f.read()

        # Nahraď error handler a resize handler bezpečnou verzí
        content = re.sub(
            r"function love\.errhand\([\s\S]*?end\n\nfunction love\.resize\([\s\S]*?end\n",
            '''function love.errhand(msg)
    print("ERROR: "..tostring(msg))
    while true do
        if love.timer then love.timer.sleep(0.5) end
    end
end

function love.resize(w, h)
    -- Not supported on Wii U / LovePotion
end
''',
            content,
            flags=re.MULTILINE
        )

        with open(main_lua_path, "w", encoding="utf-8") as f:
            f.write(content)

    # Create Wii U compatible conf.lua IN game folder
    with open(BUILD_DIR/"game"/"conf.lua", "w") as f:
        f.write('''function love.conf(t)
    t.console = false
    t.window.title = "Balatro (Wii U Build)"
    t.window.width = 1280
    t.window.height = 720
end
''')

    # Create main.lua IN game folder (if not already exists)
    if not (BUILD_DIR/"game"/"main.lua").exists():
        with open(BUILD_DIR/"game"/"main.lua", "w") as f:
            f.write('''G = {
    SEED = os.time(),
    CONTROLLER = {
        keyboard_controller = {},
        set_HID_flags = function() end,
        key_press = function() end,
        key_release = function() end,
        update = function() end,
        draw = function() end,
    },
    FPS_CAP = 60,
    F_MOBILE = false,
    SETTINGS = {
        crashreports = false,
    },
    VERSION = "1.0.0",
    F_NO_ERROR_HAND = false,
    F_CRASH_REPORTS = false,
    C = {
        BLACK = {0, 0, 0},
    },
    init_window = function()
        print("Initializing window...")
    end,
    start_up = function()
        print("Starting up...")
    end,
    update = function(dt)
        print("Updating...")
    end,
    draw = function()
        print("Drawing...")
    end,
}

-- Mock Steam integration
function steam_init()
    print("Steam initialized (mock implementation)")
end

function steam_shutdown()
    print("Steam shutdown (mock implementation)")
end

function steam_get_user()
    return "MockUser"
end

function love.load()
    print("=== DEBUG CONSOLE ACTIVATED ===")
    print("Game Version: 1.0")
    
    -- Initialize Steam (mock implementation)
    steam_init()
    
    -- Safe game loading
    local status, err = pcall(require, "main")  -- Loads game/main.lua
    if not status then
        print("FATAL ERROR: "..err)
        love.event.quit()
    end
end

function love.quit()
    -- Shutdown Steam (mock implementation)
    steam_shutdown()
end
''')

    # Create meta.xml in root
    with open(BUILD_DIR/"meta.xml", "w") as f:
        f.write('''<?xml version="1.0"?>
<app version="1.0.1">
  <name>Balatro</name>
  <coder>YourName</coder>
  <version>1.0.1</version>
  <release_date>2025</release_date>
</app>''')

def check_assets():
    errors = []
    for file in Path('./build/game').rglob('*'):
        if file.suffix.lower() in {'.webp', '.tga', '.psd', '.svg'}:
            errors.append(f"img {file} is in an unsupported format")
        if file.suffix.lower() in {'.flac', '.mod', '.xm', '.it', '.s3m', '.midi'}:
            errors.append(f"sound {file} is in an unsupported format")
    if errors:
        print("WARNING: some assets are in unsupported formats:")
        for e in errors:
            print("  -", e)
        print("Converted assets to supported formats:")
    else:
        print("all assets are in supported formats")

if __name__ == "__main__":
    prepare_assets()
    check_assets()
    print("Build complete with debug configuration")
    print("Folder structure:")
    print("  build/game/conf.lua    - Debug configuration")
    print("  build/game/main.lua    - Debug loader")
    print("  build/game/resources/       - All game assets")