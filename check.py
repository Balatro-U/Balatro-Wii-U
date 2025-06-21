import os
import re

# Kořenová složka s tvými Lua soubory
ROOT = r'build/game'

# Výrazy, které hledat (nepodporované v LovePotion/Wii U)
PATTERNS = [
    r'luasteam',
    r'clipboard',
    r'winapi',
    r'love\.window',
    r'love\.clipboard',
    r'love\.system\.getOS',
    r'love\.system\.openURL',
    r'love\.system\.vibrate',
    r'love\.system\.getPowerInfo',
    r'love\.system\.getUserDirectory',
    r'love\.system\.getTime',
    r'love\.system\.setClipboardText',
    r'love\.system\.getClipboardText',
    r'love\.thread',
    r'love\.physics',
    r'love\.touch',
    r'love\.mouse',
    r'love\.joystick\.setVibration',
    r'love\.graphics\.setShader',
    r'love\.graphics\.newShader',
    r'love\.graphics\.newCanvas',
    r'love\.graphics\.setCanvas',
    r'love\.graphics\.newVideo',
    r'love\.graphics\.playVideo',
    r'love\.graphics\.newMesh',
    r'love\.graphics\.newSpriteBatch',
    r'love\.graphics\.newParticleSystem',
    r'love\.graphics\.setScissor',
    r'love\.graphics\.setColorMask',
    r'love\.graphics\.setWireframe',
    r'love\.graphics\.setBlendMode',
    r'love\.graphics\.setDefaultFilter',
    r'love\.graphics\.setLineStyle',
    r'love\.graphics\.setLineJoin',
    r'love\.graphics\.setNewFont',
    r'love\.graphics\.getRendererInfo',
    r'love\.graphics\.getSystemLimits',
    r'love\.graphics\.getStats',
    r'love\.graphics\.getSupported',
    r'love\.graphics\.getCanvas',
    r'love\.graphics\.getShader',
    r'love\.graphics\.getScissor',
    r'love\.graphics\.getColorMask',
    r'love\.graphics\.getWireframe',
    r'love\.graphics\.getBlendMode',
    r'love\.graphics\.getLineStyle',
    r'love\.graphics\.getLineJoin',
    r'love\.graphics\.getFont',
    r'love\.graphics\.getBackgroundColor',
    r'love\.graphics\.getColor',
    r'love\.graphics\.getDimensions',
    r'love\.graphics\.getDPIScale',
    r'love\.graphics\.captureScreenshot',
    r'love\.audio\.newSource',
    r'love\.filesystem\.getSourceBaseDirectory',
    r'love\.filesystem\.getSaveDirectory',
    r'love\.filesystem\.mount',
    r'love\.filesystem\.unmount',
    r'os\.execute',
    r'io\.popen',
    r'os\.remove',
    r'os\.rename',
    r'ffi',
    r'function\s+love\.errhand',
]

regex = re.compile('|'.join(PATTERNS))

for dirpath, _, filenames in os.walk(ROOT):
    for fname in filenames:
        if fname.endswith('.lua'):
            fpath = os.path.join(dirpath, fname)
            with open(fpath, encoding='utf-8') as f:
                for i, line in enumerate(f, 1):
                    # Přeskoč řádky začínající na "--" (komentáře)
                    if line.strip().startswith('--'):
                        continue
                    if regex.search(line):
                        print(f"{fpath}:{i}: {line.strip()}")