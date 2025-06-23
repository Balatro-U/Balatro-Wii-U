import os
import re

ROOT = r'build/game'  # uprav podle potřeby

# KOMPLETNÍ seznam nepodporovaných funkcí v LovePotion 3.0.0 prerelease 5 na Wii U
FUNCTIONS = [
    # === GRAPHICS - Nepodporované ===
    'love.graphics.setShader',
    'love.graphics.newShader', 
    'love.graphics.setCanvas',
    'love.graphics.newCanvas',
    'love.graphics.newMesh',
    'love.graphics.newSpriteBatch',
    'love.graphics.newParticleSystem',
    'love.graphics.newVideo',
    'love.graphics.playVideo',
    'love.graphics.setScissor',
    'love.graphics.getScissor',
    'love.graphics.setColorMask',
    'love.graphics.getColorMask',
    'love.graphics.setWireframe',
    'love.graphics.getWireframe',
    'love.graphics.setDefaultFilter',
    'love.graphics.getDefaultFilter',
    'love.graphics.setLineStyle',
    'love.graphics.getLineStyle',
    'love.graphics.setLineJoin',
    'love.graphics.getLineJoin',
    'love.graphics.captureScreenshot',
    'love.graphics.getRendererInfo',
    'love.graphics.getSystemLimits',
    'love.graphics.getStats',
    'love.graphics.getSupported',
    'love.graphics.getDPIScale',
    'love.graphics.getStackDepth',
    'love.graphics.validateShader',
    'love.graphics.flushBatch',
    'love.graphics.newArrayTexture',
    'love.graphics.newVolumeTexture',
    
    # === MOUSE - Kompletně nepodporováno ===
    'love.mouse.getX',
    'love.mouse.getY', 
    'love.mouse.getPosition',
    'love.mouse.setPosition',
    'love.mouse.isDown',
    'love.mouse.wasPressed',
    'love.mouse.wasReleased',
    'love.mouse.setVisible',
    'love.mouse.isVisible',
    'love.mouse.setCursor',
    'love.mouse.getCursor',
    'love.mouse.newCursor',
    'love.mouse.getSystemCursor',
    'love.mouse.setGrabbed',
    'love.mouse.isGrabbed',
    'love.mouse.setRelativeMode',
    'love.mouse.getRelativeMode',
    
    # === TOUCH - Nepodporováno ===
    'love.touch.getTouches',
    'love.touch.getPosition',
    'love.touch.getPressure',
    
    # === WINDOW - Většina nepodporována ===
    'love.window.setMode',
    'love.window.getMode', 
    'love.window.setFullscreen',
    'love.window.getFullscreen',
    'love.window.setPosition',
    'love.window.getPosition',
    'love.window.setIcon',
    'love.window.getIcon',
    'love.window.setTitle',
    'love.window.getTitle',
    'love.window.minimize',
    'love.window.maximize',
    'love.window.restore',
    'love.window.isMinimized',
    'love.window.isMaximized',
    'love.window.hasFocus',
    'love.window.hasMouseFocus',
    'love.window.isVisible',
    'love.window.setVSync',
    'love.window.getVSync',
    'love.window.requestAttention',
    'love.window.toPixels',
    'love.window.fromPixels',
    'love.window.getDPIScale',
    'love.window.getDesktopDimensions',
    'love.window.showMessageBox',
    
    # === THREAD - Kompletně nepodporováno ===
    'love.thread.newThread',
    'love.thread.newChannel', 
    'love.thread.getChannel',
    
    # === PHYSICS - Kompletně nepodporováno ===
    'love.physics.newWorld',
    'love.physics.newBody',
    'love.physics.newFixture',
    'love.physics.newShape',
    'love.physics.newJoint',
    'love.physics.getDistance',
    'love.physics.getMeter',
    'love.physics.setMeter',
    
    # === FILESYSTEM - Částečně omezeno ===
    'love.filesystem.mount',
    'love.filesystem.unmount',
    'love.filesystem.getSourceBaseDirectory',
    'love.filesystem.getUserDirectory', 
    'love.filesystem.getAppdataDirectory',
    'love.filesystem.getWorkingDirectory',
    'love.filesystem.setSymlinksEnabled',
    'love.filesystem.areSymlinksEnabled',
    'love.filesystem.createDirectory',
    'love.filesystem.remove',
    'love.filesystem.getDirectoryItems',
    'love.filesystem.lines',
    
    # === SYSTEM - Většina nepodporována ===
    'love.system.openURL',
    'love.system.vibrate',
    'love.system.setClipboardText',
    'love.system.getClipboardText',
    'love.system.getPowerInfo',
    'love.system.hasBackgroundMusic',
    
    # === AUDIO - Částečně omezeno ===
    'love.audio.getDistanceModel',
    'love.audio.setDistanceModel',
    'love.audio.getDopplerScale', 
    'love.audio.setDopplerScale',
    'love.audio.getOrientation',
    'love.audio.setOrientation',
    'love.audio.getPosition',
    'love.audio.setPosition',
    'love.audio.getVelocity',
    'love.audio.setVelocity',
    'love.audio.getRecordingDevices',
    'love.audio.getActiveEffects',
    'love.audio.getActiveSourceCount',
    'love.audio.getMaxSceneEffects',
    'love.audio.getMaxSourceEffects',
    'love.audio.isEffectsSupported',
    
    # === JOYSTICK - Částečně omezeno ===
    'love.joystick.loadGamepadMappings',
    'love.joystick.saveGamepadMappings',
    'love.joystick.setVibration',
    'love.joystick.getVibration',
    
    # === TIMER - Některé funkce ===
    'love.timer.getAverageDelta',
    'love.timer.getFPS',
    
    # === FONT - Pokročilé funkce ===
    'love.graphics.newImageFont',
    'love.graphics.newBMFont',
    'love.graphics.setNewFont',
    
    # === MATH - Pokročilé funkce ===
    'love.math.newBezierCurve',
    'love.math.triangulate',
    'love.math.isConvex',
    'love.math.gammaToLinear',
    'love.math.linearToGamma',
    'love.math.noise',
    
    # === IMAGE DATA - Pokročilé manipulace ===
    'love.image.newCompressedData',
    'love.image.newImageData',
    'love.image.isCompressed',
    
    # === SOUND DATA - Pokročilé ===
    'love.sound.newSoundData',
    'love.sound.newDecoder',
    
    # === EVENT - Pokročilé ===
    'love.event.wait',
    'love.event.pump',
    'love.event.poll',
    'love.event.push',
    'love.event.clear',
    
    # === OS/IO - Systémové funkce ===
    'os.execute',
    'os.getenv',
    'os.remove',
    'os.rename',
    'os.tmpname',
    'io.popen',
    'io.tmpfile',
    
    # === EXTERNÍ KNIHOVNY ===
    'ffi',              # LuaJIT FFI
    'bit',              # Bit operations
    'jit',              # JIT kontrola
    'package.loadlib',  # C knihovny
    'require',          # Omezené na Wii U
    'loadfile',         # Omezené
    'dofile',           # Omezené
    'loadstring',       # Částečně omezené
    
    # === STEAM/PLATFORM SPECIFICKÉ ===
    'luasteam',
    'winapi',
    'discord',
    'steamworks',
    
    # === DEBUG/PROFILING ===
    'debug.getinfo',
    'debug.traceback',
    'debug.sethook',
    'debug.gethook',
    'collectgarbage',   # Částečně
    
    # === NETWORKING ===
    'socket',           # LuaSocket
    'http',
    'https',
    'tcp',
    'udp',
    
    # === COROUTINES - Částečně ===
    'coroutine.wrap',
    'coroutine.create',
    'coroutine.resume',
    'coroutine.yield',
    'coroutine.status',
]

def wrap_line(line, func):
    """Zabalí řádek do bezpečnostní podmínky"""
    indent = re.match(r'^(\s*)', line).group(1)
    func_name = func.split('.')[-1]
    return f"{indent}if {func_name} then\n{indent}    {line.strip()}\n{indent}end\n"

def process_files():
    """Zpracuje všechny .lua soubory v ROOT slozce"""
    files_processed = 0
    functions_wrapped = 0
    
    for dirpath, _, filenames in os.walk(ROOT):
        for fname in filenames:
            if fname.endswith('.lua'):
                fpath = os.path.join(dirpath, fname)
                try:
                    with open(fpath, 'r', encoding='utf-8') as f:
                        lines = f.readlines()
                    
                    new_lines = []
                    file_changes = 0
                    
                    for line in lines:
                        changed = False
                        for func in FUNCTIONS:
                            # Pokud je funkce v řádku a není zakomentovaná
                            if func in line and not line.strip().startswith('--'):
                                # Pokud už není podmíněná
                                func_check = f"if {func.split('.')[-1]}"
                                if func_check not in line:
                                    new_lines.append(wrap_line(line, func))
                                    changed = True
                                    file_changes += 1
                                    functions_wrapped += 1
                                    break
                        
                        if not changed:
                            new_lines.append(line)
                    
                    # Ulož pouze pokud byly změny
                    if file_changes > 0:
                        with open(fpath, 'w', encoding='utf-8') as f:
                            f.writelines(new_lines)
                        print(f"{fname}: {file_changes} funkci zabaleno")
                        files_processed += 1
                    
                except Exception as e:
                    print(f"Chyba pri zpracovani {fname}: {e}")
    
    print(f"\nHotovo! {files_processed} souboru upraveno, {functions_wrapped} funkci zabaleno.")
if __name__ == "__main__":
    print(f"Zpracovavam slozku: {ROOT}")
    print(f"Zabaluji {len(FUNCTIONS)} nepodporovanych funkci...")
    print()
    process_files()