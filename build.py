import os
import re

ROOT = r'build/game'  # uprav podle potřeby

# Seznam funkcí, které chceme podmínit
FUNCTIONS = [
    'love.graphics.setShader',
    'love.graphics.newShader',
    'love.graphics.setDefaultFilter',
    'love.graphics.setLineStyle',
    'love.graphics.setCanvas',
    'love.graphics.newCanvas',
    'love.graphics.newVideo',
    'love.graphics.playVideo',
    'love.graphics.newMesh',
    'love.graphics.newSpriteBatch',
    'love.graphics.newParticleSystem',
    'love.graphics.setScissor',
    'love.graphics.setColorMask',
    'love.graphics.setWireframe',
    'love.graphics.setBlendMode',
    'love.graphics.getRendererInfo',
    'love.graphics.getSystemLimits',
    'love.graphics.getStats',
    'love.graphics.getSupported',
    'love.graphics.getCanvas',
    'love.graphics.getShader',
    'love.graphics.getScissor',
    'love.graphics.getColorMask',
    'love.graphics.getWireframe',
    'love.graphics.getBlendMode',
    'love.graphics.getLineStyle',
    'love.graphics.getLineJoin',
    'love.graphics.getFont',
    'love.graphics.getBackgroundColor',
    'love.graphics.getColor',
    'love.graphics.getDimensions',
    'love.graphics.getDPIScale',
    'love.graphics.captureScreenshot',
    'love.audio.newSource',
    'love.filesystem.getSourceBaseDirectory',
    'love.filesystem.getSaveDirectory',
    'love.filesystem.mount',
    'love.filesystem.unmount',
    'os.execute',
    'io.popen',
    'os.remove',
    'os.rename',
    'ffi',
    'winapi',
    'luasteam',
    'love.joystick.setVibration',
    'love.mouse',
    'love.touch',
    'love.thread',
    'love.physics',
    'love.window',
    'love.clipboard',
    'love.system.getOS',
    'love.system.openURL',
    'love.system.vibrate',
    'love.system.getPowerInfo',
    'love.system.getUserDirectory',
    'love.system.getTime',
    'love.system.setClipboardText',
    'love.system.getClipboardText',
]

def wrap_line(line, func):
    indent = re.match(r'^(\s*)', line).group(1)
    return f"{indent}if {func.split('.')[-1]} then\n{indent}    {line.strip()}\n{indent}end\n"

for dirpath, _, filenames in os.walk(ROOT):
    for fname in filenames:
        if fname.endswith('.lua'):
            fpath = os.path.join(dirpath, fname)
            with open(fpath, encoding='utf-8') as f:
                lines = f.readlines()
            new_lines = []
            for line in lines:
                changed = False
                for func in FUNCTIONS:
                    # Pokud je funkce v řádku a není zakomentovaná
                    if func in line and not line.strip().startswith('--'):
                        # Pokud už není podmíněná
                        if f"if {func.split('.')[-1]}" not in line:
                            new_lines.append(wrap_line(line, func))
                            changed = True
                            break
                if not changed:
                    new_lines.append(line)
            with open(fpath, 'w', encoding='utf-8') as f:
                f.writelines(new_lines)