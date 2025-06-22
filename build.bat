@echo off
SETLOCAL EnableDelayedExpansion

:: Configuration
SET "LOVEPOTION_DIR=%~dp0"
SET "LOVEPOTION_WUHB=%LOVEPOTION_DIR%\lovepotion.wuhb"
SET "BUILD_DIR=%~dp0build"
SET "OUTPUT_NAME=Balatro_Debug"
SET "LOVEPOTION_URL=https://lovebrew.org/releases/lovepotion.wuhb"

::rmdir /s /q "%BUILD_DIR%"

:: Install dependencies
winget install -e --id Python.Python.3.10

:: Verify LovePotion exists, download if missing
if not exist "%LOVEPOTION_WUHB%" (
    echo LovePotion.wuhb not found. Downloading...
    powershell -Command "Invoke-WebRequest -Uri %LOVEPOTION_URL% -OutFile '%LOVEPOTION_WUHB%'"
    if not exist "%LOVEPOTION_WUHB%" (
        echo ERROR: Failed to download LovePotion.wuhb.
        pause
        exit /b 1
    )
)