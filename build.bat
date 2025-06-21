@echo off
SETLOCAL EnableDelayedExpansion

:: Configuration
SET "LOVEPOTION_DIR=%~dp0"
SET "LOVEPOTION_WUHB=%LOVEPOTION_DIR%\lovepotion.wuhb"
SET "BUILD_DIR=%~dp0build"
SET "OUTPUT_NAME=Balatro_Debug"
SET "LOVEPOTION_URL=https://lovebrew.org/releases/lovepotion.wuhb"

rmdir /s /q "%BUILD_DIR%"

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

:: Prepare assets with debug
echo Preparing debug assets...
python "%~dp0build.py" --debug
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to prepare debug assets.
    pause
    exit /b 1
)
python "%~dp0remove_errhand.py" "%BUILD_DIR%\game\main.lua"

:: Verify debug files
if not exist "%BUILD_DIR%\game\main.lua" (
    echo ERROR: Debug setup failed. Missing main.lua in build directory.
    dir /b "%BUILD_DIR%"
    pause
    exit /b 1
)

:: Build debug package
echo Building DEBUG package...
copy /b "%LOVEPOTION_WUHB%"+"%BUILD_DIR%\game" "%BUILD_DIR%\%OUTPUT_NAME%.wuhb"

if exist "%BUILD_DIR%\%OUTPUT_NAME%.wuhb" (
    echo.
    echo DEBUG BUILD SUCCESS!
    echo.
    echo Run on Wii U and check:
    echo 1. Launch Homebrew Browser
    echo 2. Visit: http://[YOUR_PC_IP]:8080
    echo.
    echo Package: "%BUILD_DIR%\%OUTPUT_NAME%.wuhb"
) else (
    echo.
    echo DEBUG BUILD FAILED
    echo Try manually:
    echo   copy /b "%LOVEPOTION_WUHB%"+"%BUILD_DIR%\game" "%BUILD_DIR%\%OUTPUT_NAME%.wuhb"
)

pause