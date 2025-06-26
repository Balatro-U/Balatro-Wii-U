import os
import re
import shutil
from pathlib import Path

class BalatroConverter:
    def __init__(self, input_dir="game", output_dir="build_cpp"):
        self.input_dir = Path(input_dir)
        self.output_dir = Path(output_dir)

    def generate_main_cpp(self):
        return '''// main.cpp - Wii U Entry Point
#include <whb/proc.h>
#include <whb/log.h>
#include <whb/gfx.h>
#include <vpad/input.h>
#include <coreinit/time.h>

int main(int argc, char **argv) {
    WHBProcInit();
    WHBLogUdpInit();
    WHBGfxInit();

    WHBLogPrintf("Balatro for Wii U starting...");

    uint64_t lastTime = OSGetSystemTime();

    while(WHBProcIsRunning()) {
        VPADStatus vpadStatus;
        VPADReadError vpadError;
        VPADRead(VPAD_CHAN_0, &vpadStatus, 1, &vpadError);

        if(vpadError == VPAD_READ_SUCCESS) {
            if(vpadStatus.trigger & VPAD_BUTTON_HOME) break;
            
            // Game controls
            if(vpadStatus.trigger & VPAD_BUTTON_A) {
                WHBLogPrintf("A button pressed");
            }
        }

        // Calculate delta time
        uint64_t currentTime = OSGetSystemTime();
        float deltaTime = (float)(currentTime - lastTime) / (float)OSGetSystemTimeBase();
        lastTime = currentTime;

        WHBGfxBeginRender();
        WHBGfxClearColor(0.1f, 0.1f, 0.2f, 1.0f);
        
        // TODO: Render game content here
        
        WHBGfxFinishRender();
    }

    WHBGfxShutdown();
    WHBLogUdpDeinit();
    WHBProcShutdown();
    return 0;
}'''

    def generate_makefile(self):
        return '''#---------------------------------------------------------------------------------
# Balatro Wii U - C++ Version
#---------------------------------------------------------------------------------

ifeq ($(strip $(DEVKITPRO)),)
$(error "Please set DEVKITPRO in your environment")
endif

TOPDIR ?= $(CURDIR)
include $(DEVKITPRO)/wut/share/wut_rules

TARGET := balatro_wiiu
BUILD := build
SOURCES := src
DATA := data
INCLUDES := include

CFLAGS := -Wall -O2 -ffunction-sections $(MACHDEP)
CFLAGS += $(INCLUDE) -D__WIIU__ -D__WUT__
CXXFLAGS := $(CFLAGS) -std=c++17

LDFLAGS = $(ARCH) $(RPXSPECS) -Wl,-Map,$(notdir $*.map)
LIBS := -lwut

LIBDIRS := $(PORTLIBS) $(WUT_ROOT)

include $(DEVKITPRO)/wut/share/wut_rules

all: $(TARGET).wuhb

$(TARGET).wuhb: $(TARGET).rpx
$(TARGET).rpx: $(TARGET).elf
$(TARGET).elf: $(OFILES)

clean:
\t@echo clean ...
\t@rm -fr $(BUILD) $(TARGET).rpx $(TARGET).elf $(TARGET).wuhb

-include $(DEPENDS)'''

    def scan_lua_files(self):
        """Scan input directory for Lua files and extract basic info"""
        lua_files = []
        if self.input_dir.exists():
            for file in self.input_dir.rglob("*.lua"):
                lua_files.append(file)
                print(f"Found Lua file: {file}")
        return lua_files

    def copy_lua_files(self, lua_files):
        """Copy all Lua files to data directory"""
        if not lua_files:
            return
        
        lua_dest = self.output_dir / "data" / "lua"
        lua_dest.mkdir(parents=True, exist_ok=True)
        
        copied_count = 0
        for lua_file in lua_files:
            # Maintain directory structure
            relative_path = lua_file.relative_to(self.input_dir)
            dest_file = lua_dest / relative_path
            dest_file.parent.mkdir(parents=True, exist_ok=True)
            
            try:
                shutil.copy2(lua_file, dest_file)
                copied_count += 1
            except Exception as e:
                print(f"Failed to copy {lua_file}: {e}")
        
        print(f"Copied {copied_count} Lua files to data/lua/")

    def copy_all_assets(self):
        """Copy all files from game directory"""
        if not self.input_dir.exists():
            return
        
        copied_count = 0
        for item in self.input_dir.rglob("*"):
            if item.is_file():
                # Skip .lua files (handled separately)
                if item.suffix.lower() == ".lua":
                    continue
                
                # Calculate relative path and destination
                relative_path = item.relative_to(self.input_dir)
                dest_file = self.output_dir / "data" / "game" / relative_path
                dest_file.parent.mkdir(parents=True, exist_ok=True)
                
                try:
                    shutil.copy2(item, dest_file)
                    copied_count += 1
                except Exception as e:
                    print(f"Failed to copy {item}: {e}")
        
        if copied_count > 0:
            print(f"Copied {copied_count} asset files to data/game/")

    def convert_project(self):
        print("Converting Balatro from Lua to C++...")
        print(f"Input directory: {self.input_dir}")
        print(f"Output directory: {self.output_dir}")

        # Scan for Lua files
        lua_files = self.scan_lua_files()
        if lua_files:
            print(f"Found {len(lua_files)} Lua files to convert")
        else:
            print("No Lua files found - creating basic template")

        # Create output directories
        self.output_dir.mkdir(exist_ok=True)
        (self.output_dir / "src").mkdir(exist_ok=True)
        (self.output_dir / "include").mkdir(exist_ok=True)
        (self.output_dir / "data").mkdir(exist_ok=True)

        # Generate main.cpp
        with open(self.output_dir / "src" / "main.cpp", "w") as f:
            f.write(self.generate_main_cpp())

        # Generate Makefile
        with open(self.output_dir / "Makefile", "w") as f:
            f.write(self.generate_makefile())

        # Copy Lua files
        self.copy_lua_files(lua_files)
        
        # Copy all other assets
        self.copy_all_assets()

        print(f"C++ project generated in: {self.output_dir}")
        print("Files created:")
        print("- src/main.cpp")
        print("- Makefile")
        
        # Count copied files
        if (self.output_dir / "data").exists():
            data_files = list((self.output_dir / "data").rglob("*"))
            if data_files:
                print(f"- data/ ({len([f for f in data_files if f.is_file()])} files total)")

        return True

if __name__ == "__main__":
    converter = BalatroConverter("game", "build_cpp")
    try:
        converter.convert_project()
        print("\nConversion completed successfully!")
    except Exception as e:
        print(f"Conversion failed: {e}")
        exit(1)