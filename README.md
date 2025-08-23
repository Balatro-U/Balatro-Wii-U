
# Balatro Wii U (Aroma Port)
![Wii U Banner](WiiU.png)

This is an unofficial port of **Balatro** for the Wii U (Aroma) using my [custom LovePotion fork](https://github.com/xtomasnemec/lovepotion/tree/3.1.0-development).

---

> [!WARNING]  
> The game is still in development, see [#2](https://github.com/xtomasnemec/Balatro-Wii-U/issues/2)


## Features
- Runs natively on Wii U via Aroma
- Based on the official Steam version of Balatro
- Easy automated build process (Windows)

---

## Requirements
- Windows 10/11 (Linux: WIP)
- A *legal* copy of **Balatro** (Steam version)

---

## Quick Start (Windows)
1. **Clone this repository**
2. **Run** `build.bat`
3. **Select** option `1` to install dependencies
   - _Note: You may need to set up Docker manually if not already installed_
4. **Select** option `2` to extract game files
   - Place your `Balatro.exe` (Steam version) in the repo folder, or ensure it is installed via Steam
5. **Select** option `3` to build the game _(this may take a while)_
6. **Select** option `4` to clean up build files (optional)
7. **Copy** the contents of the `to sdcard` folder to your SD card
8. **Insert SD card** into your Wii U and launch the game from the home menu
9. **Profit**
10. **???**

---

## Quick Start (Linux)
1. `curl -sSL https://raw.githubusercontent.com/xtomasnemec/Balatro-Wii-U/main/install.sh | sudo bash`
2. Place your `Balatro.exe` (Steam version) in the repo folder
1. **Copy** the contents of the `to sdcard` folder to your SD card
2. **Insert SD card** into your Wii U and launch the game from the home menu
3. **Profit**
4.  **???**
---

## Troubleshooting
- **Hash mismatch?**
  - Only the official Steam version (1.0.1o-Full) of Balatro is tested.
- **Missing dependencies?**
  - Use option 1 in `build.bat` to install those dependencies automatically.
- **Build fails or is slow?**
  - Building can take a long time, even my PC takes 3 minutes to build.
- **Docker is not supported on my PC**
  - Try compiling it in Linux (when the Linux support is done)
  - Or compile it at your friend's house ¯\\_\(ツ)\_/¯
---

## Credits
- Banner and icons: [Rodrick_](https://github.com/rodrickhmmm)
- Original game: [LocalThunk](https://localthunk.com/) (pls don't sue me)
- [devkitPro](https://devkitpro.org/)
- [LovePotion](https://lovebrew.org/)
