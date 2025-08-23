@echo off

::stolen from https://gist.github.com/maciakl/f30629d1a606030e55855842447472c5
if "%1" == "elevated" goto start
powershell -command "Start-Process %~nx0 elevated -Verb runas"
goto :EOF
:start

cls

:: Configuration
SET "ROOT_BUILD_DIR=%~dp0to sdcard"
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
echo 4. Clean
echo 0. Exit
echo ================================
set /p BUILD_MODE="Select build mode (0-4): "

if "%BUILD_MODE%"=="1" goto :INSTALL_DEPS
if "%BUILD_MODE%"=="2" goto :Extract
if "%BUILD_MODE%"=="3" goto :Build
if "%BUILD_MODE%"=="4" (
    cls
    echo ================================
    echo Cleaning...
    echo ================================
    rmdir /s /q "%ROOT_BUILD_DIR%"
    rmdir /s /q "%~dp0temp"
    echo Build directory cleaned.
    rmdir /s /q temp
    echo Temporary files cleaned.
    echo Cleaning up old Docker images...
    docker rmi lovepotion-wiiu 2>nul || echo No old image to remove
    docker builder prune -f -a 2>nul || echo No old build cache to prune
    pause
    goto :MENU
)
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
echo - Git
echo - 7-Zip
echo - Ubuntu 22.04 WSL - you will need to set it up yourself
echo - Docker - you will need set it up yourself

pause
goto :MENU

:Extract

cls
setlocal enabledelayedexpansion
echo ================================
echo Extracting needed files from Balatro...
echo ================================

:: Check for local Balatro.exe first (priority)
if exist "%~dp0Balatro.exe" (
    echo Found local Balatro.exe
    set "BALATRO_PATH=%~dp0Balatro.exe"
    echo Checking SHA256 hash of Balatro.exe...
    certUtil -hashfile "%~dp0Balatro.exe" SHA256 > hash.txt
    set "BALATRO_HASH="
    set "HASH_FOUND="
    for /f "skip=1 delims=" %%H in (hash.txt) do (
        if not defined HASH_FOUND if not "%%H"=="" (
            set "BALATRO_HASH=%%H"
            set "HASH_FOUND=1"
        )
    )
    set "BALATRO_HASH=!BALATRO_HASH: =!"
    del hash.txt
    if "!BALATRO_HASH!"=="" (
        echo ERROR: Failed to read SHA256 hash! Aborting.
        pause
        goto :MENU
    )
    set "BALATRO_HASH_EXPECTED=0d75fe164accf3312734d4b37ac98788dd15f0b8e4f9bb8b7f90c4e59de93f47"
    echo SHA256: !BALATRO_HASH!
    if /I not "!BALATRO_HASH!"=="!BALATRO_HASH_EXPECTED!" (
        echo WARNING: The hash of Balatro.exe does not match the expected version!
        echo Continue? (press any key to continue or Ctrl+C to cancel)
        pause
    )
    goto :EXTRACT_FILES
)

:: Search for Steam installation
echo Searching for Balatro in Steam...

:: Try to find Steam through registry
echo Checking Steam registry...
for /f "tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Valve\Steam" /v "InstallPath" 2^>nul') do (
    if exist "%%b\steamapps\common\Balatro\Balatro.exe" (
        echo Found Balatro via registry: %%b\steamapps\common\Balatro\
        set "BALATRO_PATH=%%b\steamapps\common\Balatro\Balatro.exe"
        echo Checking SHA256 hash of Balatro.exe...
        certUtil -hashfile "%%b\steamapps\common\Balatro\Balatro.exe" SHA256 > hash.txt
        set "BALATRO_HASH="
        for /f "skip=1 delims=" %%H in (hash.txt) do (
            if not "%%H"=="" (
                set "BALATRO_HASH=%%H"
            )
        )
        set "BALATRO_HASH="
        set "HASH_FOUND="
        for /f "skip=1 delims=" %%H in (hash.txt) do (
            if not defined HASH_FOUND if not "%%H"=="" (
                set "BALATRO_HASH=%%H"
                set "HASH_FOUND=1"
            )
        )
        set "BALATRO_HASH=!BALATRO_HASH: =!"
        del hash.txt
        if "!BALATRO_HASH!"=="" (
            echo ERROR: Failed to read SHA256 hash! Aborting.
            pause
            goto :MENU
        )
        set "BALATRO_HASH_EXPECTED=0d75fe164accf3312734d4b37ac98788dd15f0b8e4f9bb8b7f90c4e59de93f47"
        echo SHA256: !BALATRO_HASH!
        if /I not "!BALATRO_HASH!"=="!BALATRO_HASH_EXPECTED!" (
            echo WARNING: The hash of Balatro.exe does not match the expected version!
            echo Continue? (press any key to continue or Ctrl+C to cancel)
            pause
        )
        goto :EXTRACT_FILES
    )
}
:: Alternative registry path
for /f "tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Valve\Steam" /v "InstallPath" 2^>nul') do (
    if exist "%%b\steamapps\common\Balatro\Balatro.exe" (
        echo Found Balatro via registry: %%b\steamapps\common\Balatro\
        set "BALATRO_PATH=%%b\steamapps\common\Balatro\Balatro.exe"
        echo Checking SHA256 hash of Balatro.exe...
        certUtil -hashfile "%%b\steamapps\common\Balatro\Balatro.exe" SHA256 > hash.txt
        set "BALATRO_HASH="
        for /f "skip=1 delims=" %%H in (hash.txt) do (
            if not "%%H"=="" (
                set "BALATRO_HASH=%%H"
            )
        )
        set "BALATRO_HASH="
        set "HASH_FOUND="
        for /f "skip=1 delims=" %%H in (hash.txt) do (
            if not defined HASH_FOUND if not "%%H"=="" (
                set "BALATRO_HASH=%%H"
                set "HASH_FOUND=1"
            )
        )
        set "BALATRO_HASH=!BALATRO_HASH: =!"
        del hash.txt
        if "!BALATRO_HASH!"=="" (
            echo ERROR: Failed to read SHA256 hash! Aborting.
            pause
            goto :MENU
        )
        set "BALATRO_HASH_EXPECTED=0d75fe164accf3312734d4b37ac98788dd15f0b8e4f9bb8b7f90c4e59de93f47"
        echo SHA256: !BALATRO_HASH!
        if /I not "!BALATRO_HASH!"=="!BALATRO_HASH_EXPECTED!" (
            echo WARNING: The hash of Balatro.exe does not match the expected version!
            echo Continue? (press any key to continue or Ctrl+C to cancel)
            pause
        )
        goto :EXTRACT_FILES
    )
}
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
echo Using Balatro from: "%BALATRO_PATH%"
echo Debug: BALATRO_PATH="%BALATRO_PATH%"
if "%BALATRO_PATH%"=="" (
    echo ERROR: BALATRO_PATH is not set!
    pause
    goto :MENU
)
if not exist "%~dp0game" (
    echo Creating game directory...
    mkdir "%~dp0game"
) else (
    echo Removing existing game directory...
    rmdir /s /q "%~dp0game" 2>nul
    mkdir "%~dp0game"
)
7z x "%BALATRO_PATH%" -o"%~dp0game" -y

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

pause
goto :MENU

:Build
cls
echo ================================
echo Building...
echo ================================
rmdir /s /q "%ROOT_BUILD_DIR%"
rmdir /s /q "%~dp0temp"
echo Build directory cleaned.
echo Cloning Lovepotion repository...
mkdir "%~dp0temp"
cd /d "%~dp0temp"
git clone https://github.com/xtomasnemec/lovepotion.git --branch 3.1.0-development --single-branch
if errorlevel 1 (
    echo ERROR: Failed to clone Lovepotion repository.
    echo Make sure Git is installed and working.
    pause
    goto :MENU
)
cd /d "%~dp0"
echo Patching the game files...
xcopy "%~dp0game\*" "%~dp0temp\lovepotion\game\" /E /Y /I
xcopy "%~dp0patch\*" "%~dp0temp\lovepotion\game\" /E /Y /I
cd /d "%~dp0temp\lovepotion"
echo Building Lovepotion...
call build.bat
cd /d "%~dp0"

:: Check existence and size of balatro.wuhb
set "WUHBSRC=%~dp0temp\lovepotion\build\balatro.wuhb"
if not exist "%WUHBSRC%" (
    echo ERROR: balatro.wuhb not found in %WUHBSRC%.
    pause
    goto :MENU
)
for %%F in ("%WUHBSRC%") do set "WUHBSIZE=%%~zF"
echo Size of balatro.wuhb after build: %WUHBSIZE% bytes

:: Copy built file(s) to build dir
echo Copying built files to %BUILD_DIR%...
if not exist "%BUILD_DIR%" (
    mkdir "%BUILD_DIR%"
)
xcopy "%WUHBSRC%" "%BUILD_DIR%\" /E /Y /I
for %%F in ("%BUILD_DIR%\balatro.wuhb") do set "WUHBSIZE2=%%~zF"
echo Size of balatro.wuhb in %BUILD_DIR%: %WUHBSIZE2% bytes

cls
echo ================================
echo Build complete!
echo ================================
pause
goto :MENU