@echo off

::stolen from https://gist.github.com/maciakl/f30629d1a606030e55855842447472c5
if "%1" == "elevated" goto start
powershell -command "Start-Process %~nx0 elevated -Verb runas"
goto :EOF
:start

cls

:: Configuration
SET "BUILD_DIR=%~dp0to sdcard\wiiu\apps\Balatro"
SET "OUTPUT_NAME=Balatro_WiiU"

:MENU
cls
:: Build mode selection
echo ================================
echo    Balatro Wii U Builder
echo ================================
echo 1. Install dependencies
echo 2. Extract files
echo 3. Build
echo 0. Exit
echo ================================
set /p BUILD_MODE="Select build mode (0-3): "

if "%BUILD_MODE%"=="1" goto :INSTALL_DEPS
if "%BUILD_MODE%"=="2" goto :Extract
if "%BUILD_MODE%"=="3" goto :Build
if "%BUILD_MODE%"=="0" exit
goto :MENU

:INSTALL_DEPS
cls
echo ================================
echo Installing Dependencies...
echo ================================

:: Better admin check - try to create a file in Windows directory
echo Checking administrator privileges...
echo test > "%WINDIR%\admin_test.tmp" 2>nul
if not exist "%WINDIR%\admin_test.tmp" (
    echo ERROR: This script must be run as Administrator to install dependencies.
    echo Please:
    echo 1. Right-click on build.bat
    echo 2. Select "Run as administrator"
    echo 3. Choose option 1 again
    pause
    goto :MENU
) else (
    del "%WINDIR%\admin_test.tmp" 2>nul
    echo Administrator privileges confirmed.
)

echo Installing required dependencies for Wii U development...

:: Install Python
echo Installing Python 3.11...
winget install -e --id Python.Python.3.11 --silent --accept-package-agreements --accept-source-agreements 2>nul
if errorlevel 1 (
    echo WARNING: Python installation failed or already installed
    echo Trying alternative Python installation...
    winget install -e --id Python.Python.3.12 --silent --accept-package-agreements --accept-source-agreements 2>nul
)

:: Install Git
echo Installing Git...
winget install -e --id Git.Git --silent --accept-package-agreements --accept-source-agreements 2>nul
if errorlevel 1 (
    echo WARNING: Git installation failed or already installed
)

:: Install 7-Zip for archive extraction
echo Installing 7-Zip...
winget install -e --id 7zip.7zip --silent --accept-package-agreements --accept-source-agreements 2>nul
if errorlevel 1 (
    echo WARNING: 7-Zip installation failed or already installed
)
:: Install WSL
echo Installing Windows Subsystem for Linux (WSL)...
winget install -e --id Canonical.Ubuntu.2204 --silent --accept-package-agreements --accept-source-agreements 2>nul
if errorlevel 1 (
    echo WARNING: WSL installation failed or already installed
)

:: Install Docker
echo Installing Docker...
winget install -e --id Docker.DockerDesktop --silent --accept-package-agreements --accept-source-agreements 2>nul
if errorlevel 1 (
    echo WARNING: Docker installation failed or already installed
)

echo.
echo ================================
echo Dependency Installation Complete!
echo ================================
echo.
echo Components that should be installed:
echo - Python 3.11/3.12
echo - Git
echo - 7-Zip
echo - Ubuntu 22.04 WSL - you will need to set it up yourself
echo - Docker - you will need set it up yourself

pause
goto :MENU

:Extract
cls
echo ================================
echo Extracting needed files from Balatro...
echo ================================

:: Check for local Balatro.exe first (priority)
if exist "Balatro.exe" (
    echo Found local Balatro.exe
    set "BALATRO_PATH=%~dp0Balatro.exe"
    goto :EXTRACT_FILES
)

:: Search for Steam installation
echo Searching for Balatro in Steam...

:: Common Steam paths
set "STEAM_PATHS="
set "STEAM_PATHS=%STEAM_PATHS%;%ProgramFiles(x86)%\Steam"
set "STEAM_PATHS=%STEAM_PATHS%;%ProgramFiles%\Steam"
set "STEAM_PATHS=%STEAM_PATHS%;C:\Steam"
set "STEAM_PATHS=%STEAM_PATHS%;D:\Steam"
set "STEAM_PATHS=%STEAM_PATHS%;E:\Steam"

:: Check each Steam path
for %%p in (%STEAM_PATHS%) do (
    if exist "%%p\steamapps\common\Balatro\Balatro.exe" (
        echo Found Balatro in Steam: %%p\steamapps\common\Balatro\
        set "BALATRO_PATH=%%p\steamapps\common\Balatro\Balatro.exe"
        goto :EXTRACT_FILES
    )
)

:: Try to find Steam through registry
echo Checking Steam registry...
for /f "tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Valve\Steam" /v "InstallPath" 2^>nul') do (
    if exist "%%b\steamapps\common\Balatro\Balatro.exe" (
        echo Found Balatro via registry: %%b\steamapps\common\Balatro\
        set "BALATRO_PATH=%%b\steamapps\common\Balatro\Balatro.exe"
        goto :EXTRACT_FILES
    )
)

:: Alternative registry path
for /f "tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Valve\Steam" /v "InstallPath" 2^>nul') do (
    if exist "%%b\steamapps\common\Balatro\Balatro.exe" (
        echo Found Balatro via registry: %%b\steamapps\common\Balatro\
        set "BALATRO_PATH=%%b\steamapps\common\Balatro\Balatro.exe"
        goto :EXTRACT_FILES
    )
)

echo ERROR: Balatro.exe not found!
echo.
echo Please either:
echo 1. Copy Balatro.exe to this folder, OR
echo 2. Install Balatro through Steam
echo.
echo Searched locations:
echo - Current folder: %~dp0Balatro.exe
echo - Steam common folders
echo.
pause
goto :MENU

:EXTRACT_FILES
echo Using Balatro from: %BALATRO_PATH%
echo.

:: Create game directory if it doesn't exist
if not exist "game" (
    echo Creating game directory...
    mkdir "game"
)

:: Check if 7z is available
where 7z >nul 2>&1
if errorlevel 1 (
    echo ERROR: 7-Zip not found! Please install 7-Zip first (option 1).
    pause
    goto :MENU
)

:: Extract Balatro.exe (it's a ZIP archive)
echo Extracting Balatro.exe contents...
7z x "%BALATRO_PATH%" -o"game" -y

if errorlevel 1 (
    echo ERROR: Failed to extract Balatro.exe
    echo Make sure the file is not corrupted and 7-Zip is installed.
    pause
    goto :MENU
)

echo.
echo ================================
echo Extraction completed successfully!
echo ================================
echo.
echo Game files extracted to: game\
echo.

:: List extracted files
echo Extracted contents:
dir /b "game"

pause
goto :MENU

:Build
cls
echo ================================
echo Building...
echo ================================
echo Cloning Lovepotion repository...
mkdir temp
cd temp
git clone https://github.com/xtomasnemec/lovepotion.git --branch 3.1.0-development --single-branch
if errorlevel 1 (
    echo ERROR: Failed to clone Lovepotion repository.
    echo Make sure Git is installed and working.
    pause
    goto :MENU
)
cd ..
:: Copy game files to temp directory
echo Copying game files to temp directory...
copy /Y "game\*" ".\temp\lovepotion\game\"
cd temp\lovepotion
echo Building Lovepotion...
call build.bat
cd ..

:: Copy built file(s) to build dir
echo Copying built files to %BUILD_DIR%...
if not exist "%BUILD_DIR%" (
    mkdir "%BUILD_DIR%"
)
copy /Y ".\temp\lovepotion\build\balatro.wuhb" "%BUILD_DIR%\"
rmdir /s /q temp

cls
echo ================================
echo Build complete!
echo ================================
pause
goto :MENU