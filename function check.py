import os
import re

GAME_DIR = "game"
love_calls = set()
pattern = re.compile(r'\blove\.[a-zA-Z0-9_\.]+')

for root, _, files in os.walk(GAME_DIR):
    for fname in files:
        if fname.endswith(('.lua', '.txt', '.conf', '.init', '.moon')):
            with open(os.path.join(root, fname), encoding="utf-8", errors="ignore") as f:
                for line in f:
                    for match in pattern.findall(line):
                        love_calls.add(match)

print("Použité funkce LOVE ve složce 'game':")
for func in sorted(love_calls):
    print(func)