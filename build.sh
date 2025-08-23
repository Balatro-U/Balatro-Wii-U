#!/bin/bash

# Check if running interactively
if [[ ! -t 0 ]]; then
    echo "This script requires an interactive terminal. Please run it directly."
    exit 1
fi

# Configuration
ROOT_BUILD_DIR="$(dirname "$0")/to sdcard"
BUILD_DIR="$ROOT_BUILD_DIR/wiiu/apps/Balatro"
OUTPUT_NAME="Balatro U"
PKGS="git p7zip"

function install_deps() {
    clear
    echo "==============================="
    echo "Installing Dependencies..."
    echo "==============================="

    # Detect package manager
    if command -v apt-get &> /dev/null; then
        PM="apt-get"
        INSTALL="sudo apt-get install -y"
    elif command -v dnf &> /dev/null; then
        PM="dnf"
        INSTALL="sudo dnf install -y"
    elif command -v pacman &> /dev/null; then
        PM="pacman"
        INSTALL="sudo pacman -S --noconfirm"
    else
        echo "Unsupported package manager. Please install dependencies manually: $PKGS"
        exit 1
    fi

    sudo $PM update -y || true
    $INSTALL $PKGS

    echo
    echo "==============================="
    echo "Dependency Installation Complete!"
    echo "==============================="
    echo
    echo "Components that should be installed:"
    echo "- Git"
    echo
    read -n 1 -s -r -p "Press any key to continue..."
}

function extract() {
    clear
    echo "==============================="
    echo "Extracting needed files from Balatro..."
    echo "==============================="

    BALATRO_PATH="$(dirname "$0")/Balatro.exe"
    if [[ -f "$BALATRO_PATH" ]]; then
        echo "Found local Balatro.exe"
    else
        echo "ERROR: Balatro.exe not found!"
        echo
        echo "Please copy Balatro.exe to this folder."
        echo
        read -n 1 -s -r -p "Press any key to continue..."
        return
    fi

    echo "Using Balatro from: \"$BALATRO_PATH\""
    GAME_DIR="$(dirname "$0")/game"
    if [[ ! -d "$GAME_DIR" ]]; then
        echo "Creating game directory..."
        mkdir "$GAME_DIR"
    else
        echo "Removing existing game directory..."
        rm -rf "$GAME_DIR"
        mkdir "$GAME_DIR"
    fi

    7z x "$BALATRO_PATH" -o"$GAME_DIR" -y
    if [[ $? -ne 0 ]]; then
        echo "ERROR: Failed to extract Balatro.exe"
        echo "Make sure the file is not corrupted"
        read -n 1 -s -r -p "Press any key to continue..."
        return
    fi

    echo
    echo "==============================="
    echo "Extraction completed successfully!"
    echo "==============================="
    echo
    echo "Game files extracted to: game/"
    echo
    read -n 1 -s -r -p "Press any key to continue..."
}

function build() {
    clear
    echo "==============================="
    echo "Building..."
    echo "==============================="
    rm -rf "$ROOT_BUILD_DIR"
    rm -rf "$(dirname "$0")/temp"
    echo "Build directory cleaned."
    echo "Cloning Lovepotion repository..."
    mkdir -p "$(dirname "$0")/temp"
    cd "$(dirname "$0")/temp"
    git clone https://github.com/xtomasnemec/lovepotion.git --branch 3.1.0-development --single-branch
    if [[ $? -ne 0 ]]; then
        echo "ERROR: Failed to clone Lovepotion repository."
        echo "Make sure Git is installed and working."
        read -n 1 -s -r -p "Press any key to continue..."
        return
    fi
    cd "$(dirname "$0")"
    echo "Patching the game files..."
    cp -r "$(dirname "$0")/game/." "$(dirname "$0")/temp/lovepotion/game/"
    cp -r "$(dirname "$0")/patch/." "$(dirname "$0")/temp/lovepotion/game/"
    cd "$(dirname "$0")/temp/lovepotion"
    sudo chmod +x build.sh
    ./build.sh
    cd "$(dirname "$0")"

    WUHBSRC="$(dirname "$0")/temp/lovepotion/build/balatro.wuhb"
    if [[ ! -f "$WUHBSRC" ]]; then
        echo "ERROR: balatro.wuhb not found in $WUHBSRC."
        read -n 1 -s -r -p "Press any key to continue..."
        return
    fi
    WUHBSIZE=$(stat -c%s "$WUHBSRC")
    echo "Size of balatro.wuhb after build: $WUHBSIZE bytes"

    echo "Copying built files to $BUILD_DIR..."
    mkdir -p "$BUILD_DIR"
    cp "$WUHBSRC" "$BUILD_DIR/"
    WUHBSIZE2=$(stat -c%s "$BUILD_DIR/balatro.wuhb")
    echo "Size of balatro.wuhb in $BUILD_DIR: $WUHBSIZE2 bytes"

    clear
    echo "==============================="
    echo "Build complete!"
    echo "==============================="
    read -n 1 -s -r -p "Press any key to continue..."
}

# End of script
install_deps
extract
build

exit 0