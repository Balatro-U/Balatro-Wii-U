import os
import re
import shutil
import sys
from pathlib import Path

# Fix pro Windows console encoding
if sys.platform == "win32":
    try:
        import codecs
        sys.stdout = codecs.getwriter("utf-8")(sys.stdout.detach())
        sys.stderr = codecs.getwriter("utf-8")(sys.stderr.detach())
    except:
        # Fallback - používej pouze ASCII znaky
        pass

class BalatroWiiUPatcher:
    def __init__(self, project_dir=None):
        self.project_dir = Path(project_dir) if project_dir else Path(__file__).parent
        self.game_lua_path = self.project_dir / "build" / "game" / "game.lua"
        self.backup_path = self.project_dir / "build" / "game" / "game.lua.backup"
        
    def log(self, message):
        print(f"[PATCHER] {message}")
        
    def create_backup(self):
        """Vytvoří zálohu původního souboru"""
        if self.game_lua_path.exists() and not self.backup_path.exists():
            shutil.copy2(self.game_lua_path, self.backup_path)
            self.log(f"Záloha vytvořena: {self.backup_path}")
        
    def restore_backup(self):
        """Obnoví původní soubor ze zálohy"""
        if self.backup_path.exists():
            shutil.copy2(self.backup_path, self.game_lua_path)
            self.log("Soubor obnoven ze zálohy")
            return True
        return False
        
    def read_file(self):
        """Načte obsah game.lua"""
        try:
            with open(self.game_lua_path, 'r', encoding='utf-8') as f:
                return f.read()
        except Exception as e:
            self.log(f"Chyba při čtení souboru: {e}")
            return None
            
    def write_file(self, content):
        """Zapíše obsah do game.lua"""
        try:
            with open(self.game_lua_path, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        except Exception as e:
            self.log(f"Chyba při zápisu souboru: {e}")
            return False
            
    def patch_cursor_initialization(self, content):
        """Oprava CURSOR inicializace"""
        self.log("Aplikuji patch pro CURSOR inicializaci...")
        
        # Najdi řádek s CURSOR inicializací
        pattern = r'self\.CURSOR = Sprite\(0,0,0\.3, 0\.3, self\.ASSET_ATLAS\[\'gamepad_ui\'\], \{x = 18, y = 0\}\)'
        
        replacement = '''if self.ASSET_ATLAS and self.ASSET_ATLAS['gamepad_ui'] then
        self.CURSOR = Sprite(0,0,0.3, 0.3, self.ASSET_ATLAS['gamepad_ui'], {x = 18, y = 0})
    else
        -- Fallback cursor pro LovePotion
        self.CURSOR = {
            T = {x = 0, y = 0, w = 0.3, h = 0.3},
            states = {collide = {can = false}},
            translate_container = function(self) end,
            draw = function(self) end
        }
    end'''
        
        if re.search(pattern, content):
            content = re.sub(pattern, replacement, content)
            self.log("OK CURSOR inicializace opravena")
        else:
            self.log("! CURSOR inicializace nenalezena")
            
        return content
        
    def patch_shared_sprites(self, content):
        """Oprava sdílených spritů - zajistí že jsou zakomentované"""
        self.log("Aplikuji patch pro sdílené sprity...")
        
        # Jednodušší přístup - najdi a zakomentuj blok shared spritů
        if 'self.shared_debuff = Sprite(' in content and '--self.shared_debuff = Sprite(' not in content:
            # Nahraď všechny shared sprite inicializace komentáři
            patterns = [
                r'(\s+)(self\.shared_debuff = Sprite\([^)]+\))',
                r'(\s+)(self\.shared_soul = Sprite\([^)]+\))',
                r'(\s+)(self\.shared_undiscovered_joker = Sprite\([^)]+\))',
                r'(\s+)(self\.shared_undiscovered_tarot = Sprite\([^)]+\))',
                r'(\s+)(self\.shared_sticker_eternal = Sprite\([^)]+\))',
                r'(\s+)(self\.shared_sticker_perishable = Sprite\([^)]+\))',
                r'(\s+)(self\.shared_sticker_rental = Sprite\([^)]+\))',
            ]
            
            for pattern in patterns:
                content = re.sub(pattern, r'\1--\2', content)
            
            # Zakomentuj shared_stickers tabulku
            content = re.sub(r'(\s+)(self\.shared_stickers = \{[^}]+\})', r'\1--\2', content, flags=re.DOTALL)
            content = re.sub(r'(\s+)(self\.shared_seals = \{[^}]+\})', r'\1--\2', content, flags=re.DOTALL)
            
            self.log("OK Sdílené sprity zakomentovány")
        else:
            self.log("! Sdílené sprity už jsou zakomentovány nebo nenalezeny")
        
        return content
        
    def patch_asset_loading(self, content):
        """Přidá bezpečné načítání textur"""
        self.log("Aplikuji patch pro bezpečné načítání textur...")
        
        # Jednodušší pattern pro asset loading
        pattern = r'(self\.ASSET_ATLAS\[self\.asset_atli\[i\]\.name\]\.image = love\.graphics\.newImage\(self\.asset_atli\[i\]\.path\))'
        
        replacement = '''-- Bezpečné načítání textur pro LovePotion
        local success, image = pcall(love.graphics.newImage, self.asset_atli[i].path)
        if success then
            self.ASSET_ATLAS[self.asset_atli[i].name].image = image
        else
            self.ASSET_ATLAS[self.asset_atli[i].name].image = nil
            if wiiu_log then
                wiiu_log("Warning: Could not load asset texture: " .. self.asset_atli[i].path)
            end
        end'''
        
        if re.search(pattern, content):
            content = re.sub(pattern, replacement, content)
            self.log("OK Bezpečné načítání textur přidáno")
        else:
            self.log("! Asset loading pattern nenalezen")
        
        return content
        
    def patch_controller_init(self, content):
        """Oprava controller inicializace"""
        self.log("Aplikuji patch pro controller...")
        
        # Jednodušší pattern
        pattern = r'if self\.F_RUMBLE then\s+local joysticks = love\.joystick\.getJoysticks\(\)\s+if joysticks then\s+if joysticks\[1\] then\s+self\.CONTROLLER:set_gamepad\([^)]+\)\s+end\s+end\s+end'
        
        replacement = '''if self.F_RUMBLE then 
        pcall(function()
            local joysticks = love.joystick.getJoysticks()
            if joysticks and #joysticks > 0 then 
                if joysticks[1] then
                    self.CONTROLLER:set_gamepad(joysticks[1])
                end
            end
        end)
    end'''
        
        if re.search(pattern, content, re.DOTALL):
            content = re.sub(pattern, replacement, content, flags=re.DOTALL)
            self.log("OK Controller inicializace opravena")
        else:
            self.log("! Controller pattern nenalezen")
        
        return content
        
    def add_safe_functions(self, content):
        """Přidá bezpečné pomocné funkce"""
        self.log("Přidávám bezpečné pomocné funkce...")
        
        safe_functions = '''
-- LovePotion/Wii U compatibility functions
local function safe_set_shader(shader_name)
    if G.SHADERS and G.SHADERS[shader_name] then
        pcall(function()
            love.graphics.setShader(G.SHADERS[shader_name])
        end)
    else
        pcall(function()
            love.graphics.setShader()
        end)
    end
end

-- Fallback Particles class for LovePotion
if not Particles then
    Particles = function(x, y, w, h, options)
        return {
            fade = function(self, duration, target) end,
            fade_alpha = 1,
            remove = function(self) end
        }
    end
end

'''
        
        # Najdi Game = Object:extend() a vlož funkce za něj
        if 'Game = Object:extend()' in content and 'safe_set_shader' not in content:
            content = content.replace('Game = Object:extend()', f'Game = Object:extend(){safe_functions}')
            self.log("OK Bezpečné funkce přidány")
        else:
            self.log("! Game class nenalezena nebo funkce už existují")
        
        return content
        
    def patch_graphics_settings(self, content):
        """Oprava graphics nastavení"""
        self.log("Aplikuji patch pro graphics nastavení...")
        
        pattern = r'love\.graphics\.setDefaultFilter\([^)]+\)'
        
        replacement = '''pcall(function()
        if love.graphics.setDefaultFilter then
            love.graphics.setDefaultFilter(
                self.SETTINGS.GRAPHICS.texture_scaling == 1 and 'nearest' or 'linear',
                self.SETTINGS.GRAPHICS.texture_scaling == 1 and 'nearest' or 'linear', 1)
        end
    end)'''
        
        if re.search(pattern, content):
            content = re.sub(pattern, replacement, content)
            self.log("OK Graphics nastavení opraveno")
        else:
            self.log("! Graphics pattern nenalezen")
        
        return content
        
    def apply_all_patches(self):
        """Aplikuje všechny patche"""
        self.log("Začínám aplikaci patchů pro Balatro Wii U...")
        
        if not self.game_lua_path.exists():
            self.log(f"CHYBA: Soubor {self.game_lua_path} neexistuje!")
            return False
            
        # Vytvoř zálohu
        self.create_backup()
        
        # Načti soubor
        content = self.read_file()
        if not content:
            return False
            
        # Aplikuj patche
        content = self.add_safe_functions(content)
        content = self.patch_cursor_initialization(content)
        content = self.patch_shared_sprites(content)
        content = self.patch_asset_loading(content)
        content = self.patch_controller_init(content)
        content = self.patch_graphics_settings(content)
        
        # Zapiš opravený soubor
        if self.write_file(content):
            self.log("USPECH! Všechny patche aplikovány!")
            self.log("Balatro je nyní kompatibilní s LovePotion/Wii U")
            return True
        else:
            self.log("CHYBA při zápisu patchů")
            return False
            
    def show_status(self):
        """Zobrazí stav projektu"""
        self.log("=== STATUS PROJEKTU ===")
        self.log(f"Projekt: {self.project_dir}")
        self.log(f"Game.lua: {'EXISTUJE' if self.game_lua_path.exists() else 'NEEXISTUJE'}")
        self.log(f"Záloha: {'EXISTUJE' if self.backup_path.exists() else 'NEEXISTUJE'}")

def main():
    print("Balatro Wii U Patcher v1.0")
    print("=" * 50)
    
    patcher = BalatroWiiUPatcher()
    
    while True:
        print("\nVyberte akci:")
        print("1. Aplikovat patche")
        print("2. Obnovit ze zálohy") 
        print("3. Zobrazit status")
        print("4. Ukončit")
        
        choice = input("\nVaše volba (1-4): ").strip()
        
        if choice == "1":
            success = patcher.apply_all_patches()
            if success:
                print("\nPatching dokončen! Projekt je připraven pro Wii U.")
            else:
                print("\nPatching selhal!")
                
        elif choice == "2":
            if patcher.restore_backup():
                print("\nSoubor obnoven ze zálohy.")
            else:
                print("\nZáloha neexistuje!")
                
        elif choice == "3":
            patcher.show_status()
            
        elif choice == "4":
            print("\nUkončuji patcher...")
            break
            
        else:
            print("\nNeplatná volba!")

if __name__ == "__main__":
    main()