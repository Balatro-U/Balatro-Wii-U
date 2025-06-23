import os
import re
from pathlib import Path
import sys
import locale

sys.stdout.reconfigure(encoding='utf-8')

def create_consolidated_balatro():
    """
    Spojí všechny Lua soubory Balatro projektu do jednoho main.lua souboru
    """
    
    # Definice struktury souborů v pořadí pro správné načítání
    file_order = [
        # Core engine files
        "engine/object.lua",
        "engine/node.lua", 
        "engine/moveable.lua",
        "engine/sprite.lua",
        "engine/animatedsprite.lua",
        "engine/string_packer.lua",
        "engine/controller.lua",
        "engine/event.lua",
        "engine/ui.lua",
        "engine/particles.lua",
        "engine/text.lua",
        
        # Bit operations
        "bit.lua",
        
        # Game systems
        "back.lua",
        "tag.lua", 
        "blind.lua",
        "card.lua",
        "card_character.lua",
        "cardarea.lua",
        
        # Functions
        "functions/misc_functions.lua",
        "functions/UI_definitions.lua",
        "functions/state_events.lua", 
        "functions/common_events.lua",
        "functions/button_callbacks.lua",
        "functions/test_functions.lua",
        
        # Core game
        "globals.lua",
        "game.lua",
        "challenges.lua",
        
        # Tests
        "test_runner.lua"
    ]
    
    # Cesty
    source_dir = Path("build/game")
    tests_dir = Path("tests")
    output_file = Path("main-consolidated.lua")
    
    # Začátek konsolidovaného souboru
    consolidated_content = '''-- Balatro - Kompletní konsolidovaná verze pro Wii U/LovePotion
-- Všechny moduly jsou sloučené do jednoho souboru
-- Generováno automaticky pomocí consolidate_balatro.py

--[[
=== DEBUG SYSTÉM ===
]]--
function wiiu_log(msg)
    love.filesystem.append("log.txt", os.date("[%H:%M:%S] ") .. tostring(msg) .. "\\n")
end

-- Přesměrování print na wiiu_log
print = wiiu_log

wiiu_log("Balatro Wii U - Konsolidovaná verze spuštěna!")

-- Logování všech načítaných assetů
local old_newImage = love.graphics.newImage
love.graphics.newImage = function(path, ...)
    wiiu_log("Načítám obrázek: " .. tostring(path))
    return old_newImage(path, ...)
end

local old_newSource = love.audio.newSource
love.audio.newSource = function(path, ...)
    wiiu_log("Načítám zvuk: " .. tostring(path))
    return old_newSource(path, ...)
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

'''

    def clean_lua_content(content, filename):
        """Vyčistí a upraví obsah Lua souboru"""
        
        # Odstraň require příkazy
        content = re.sub(r'require\s+["\'][^"\']+["\']', '', content)
        
        # Odstraň komentáře o cestách
        content = re.sub(r'--\s*filepath:.*?\n', '', content)
        
        # Odstraň duplicitní prázdné řádky
        content = re.sub(r'\n\s*\n\s*\n', '\n\n', content)
        
        # Speciální úpravy pro různé soubory
        if filename == "bit.lua":
            # Přidej podmínku pro bit modul
            content = "bit = bit or {}\n" + content
            
        elif filename == "game.lua":
            # Odstraň duplicitní definice G
            content = re.sub(r'G\s*=\s*{[^}]*}', '', content)
            
        elif filename.startswith("engine/"):
            # Pro engine soubory přidej komentář
            module_name = filename.replace("engine/", "").replace(".lua", "").upper()
            content = f"--[[\n=== {module_name} SYSTEM ===\n]]--\n" + content
            
        return content.strip()

    def read_file_content(filepath):
        """Načte obsah souboru"""
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                return f.read()
        except FileNotFoundError:
            print(f"Soubor nenalezen: {filepath}")
            return ""
        except Exception as e:
            print(f"Chyba při čtení {filepath}: {e}")
            return ""

    # Načti a spojuj soubory
    total_lines = 0
    processed_files = []
    
    for filename in file_order:
        # Zkus najít soubor v různých složkách
        possible_paths = [
            source_dir / filename,
            tests_dir / filename,
            Path(filename)
        ]
        
        content = ""
        found_path = None
        
        for path in possible_paths:
            if path.exists():
                content = read_file_content(path)
                found_path = path
                break
        
        if content:
            print(f"Zpracovávám: {found_path}")
            
            # Vyčisti obsah
            cleaned_content = clean_lua_content(content, filename)
            
            if cleaned_content:
                # Přidej do konsolidovaného souboru
                module_comment = f"\n--[[\n=== {filename.upper().replace('/', ' - ').replace('.LUA', '')} ===\n]]--\n"
                consolidated_content += module_comment + cleaned_content + "\n\n"
                
                processed_files.append(filename)
                total_lines += len(cleaned_content.split('\n'))
        else:
            print(f"VAROVÁNÍ: Soubor {filename} nebyl nalezen!")

    # Přidej LOVE callbacks
    consolidated_content += '''
--[[
=== LOVE CALLBACKS ===
]]--

function love.load(arg)
    -- Inicializace systému
    wiiu_log("LOVE.load zavoláno")
    
    -- Načti všechny potřebné assety
    for i, asset in ipairs(G.assets) do
        if asset.type == "image" then
            local success, image = pcall(love.graphics.newImage, asset.path)
            if success then
                asset.image = image
            else
                asset.image = nil
                wiiu_log("Varování: Nepodařilo se načíst obrázek: " .. asset.path)
            end
        elseif asset.type == "sound" then
            local success, sound = pcall(love.audio.newSource, asset.path, "static")
            if success then
                asset.sound = sound
            else
                asset.sound = nil
                wiiu_log("Varování: Nepodařilo se načíst zvuk: " .. asset.path)
            end
        end
    end

    -- Inicializace herních stavů
    G.state = "start"
    G.score = 0
    G.lives = 3
    
    -- Zavolej hlavní menu
    goto_main_menu()
end

function love.update(dt)
    -- Aktualizace herních objektů
    if G.state == "play" then
        update_game_objects(dt)
    end
end

function love.draw()
    -- Vykreslení herních objektů
    if G.state == "play" then
        draw_game_objects()
    end
end

function love.keypressed(key, scancode, isrepeat)
    -- Zpracování stisknutí klávesy
    if G.state == "play" then
        handle_input(key)
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    -- Zpracování stisknutí myši
    if G.state == "play" then
        handle_mouse_click(x, y, button)
    end
end

function love.quit()
    wiiu_log("Hra ukončena")
end
'''

    # Ulož konsolidovaný soubor
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(consolidated_content)
        print(f"\nKonsolidovaný soubor úspěšně vytvořen: {output_file}")
        print(f"Celkový počet zpracovaných řádků: {total_lines}")
        print("Hotovo! Nyní můžete spustit hru pomocí main.lua souboru.")
    except Exception as e:
        print(f"Chyba při ukládání konsolidovaného souboru: {e}")

# Spuštění konsolidace
create_consolidated_balatro()