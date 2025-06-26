@echo off

cls

:: Configuration
SET "CPP_BUILD_DIR=%~dp0build_cpp"
SET "OUTPUT_NAME=Balatro_WiiU"

:MENU
cls
:: Build mode selection
echo ================================
echo    Balatro Wii U Build System
echo ================================
echo 1. Install dependencies (DevkitPro, MSYS2, etc.)
echo 2. Convert to C++ and build native
echo 3. Deploy to Wii U
echo 4. Clean build files
echo 0. Exit
echo ================================
set /p BUILD_MODE="Select build mode (0-4): "

if "%BUILD_MODE%"=="1" goto :INSTALL_DEPS
if "%BUILD_MODE%"=="2" goto :BUILD_CPP
if "%BUILD_MODE%"=="3" goto :DEPLOY
if "%BUILD_MODE%"=="4" goto :CLEAN
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

:: Run DevkitPro installation (must exist as tools\install_devkitpro.py)
echo Running DevkitPro installation...
python tools\install_devkitpro.py
if errorlevel 1 (
    echo WARNING: DevkitPro installation had some issues
    echo You may need to install some components manually
)

:: Install Visual Studio Build Tools (needed for some native packages)
echo Installing Visual Studio Build Tools...
winget install -e --id Microsoft.VisualStudio.2022.BuildTools --silent --accept-package-agreements --accept-source-agreements 2>nul
if errorlevel 1 (
    echo WARNING: Visual Studio Build Tools installation failed or already installed
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
echo - MSYS2
echo - DevkitPro
echo - WUT (Wii U Toolchain)
echo - Visual Studio Build Tools
echo.
echo IMPORTANT NEXT STEPS:
echo 1. Close this command prompt
echo 2. Open a NEW command prompt (or restart computer)
echo 3. Run build.bat again and choose option 2
echo.
echo Manual installation links (if needed):
echo - MSYS2: https://www.msys2.org/
echo - DevkitPro: https://github.com/devkitPro/installer/releases

pause
goto :MENU

:BUILD_CPP
cls
echo ================================
echo Converting to C++ and building...
echo ================================

:: Setup environment variables directly (no external script)
echo Setting up environment...
if exist "C:\devkitPro" (
    set "DEVKITPRO=C:\devkitPro"
    set "DEVKITPPC=C:\devkitPro\devkitPPC"
    echo DevkitPro found at: %DEVKITPRO%
) else (
    echo ERROR: DevkitPro not found at C:\devkitPro
    echo Please run option 1 to install dependencies first.
    pause
    goto :MENU
)

:: Setup PATH with proper escaping (use % instead of ! for PATH)
set "PATH=%DEVKITPRO%\tools\bin;%DEVKITPPC%\bin;C:\msys64\usr\bin;%PATH%"

:: Check Python
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python not found. Please run option 1 to install dependencies.
    pause
    goto :MENU
)

:: Remove existing build directory if it exists
if exist "%CPP_BUILD_DIR%" (
    echo Removing existing build directory...
    rmdir /s /q "%CPP_BUILD_DIR%"
)

:: Run converter (must exist as tools\balatro_converter.py)
echo Running Lua to C++ conversion...
python tools\balatro_converter.py

:: Build C++ version
if exist "%CPP_BUILD_DIR%" (
    echo Building C++ version...
    cd "%CPP_BUILD_DIR%"
    
    :: Check if make is available
    make --version >nul 2>&1
    if errorlevel 1 (
        echo Searching for make in MSYS2...
        if exist "C:\msys64\usr\bin\make.exe" (
            echo Found make in MSYS2
        ) else (
            echo ERROR: make not found. 
            echo Please ensure MSYS2 is installed and in PATH.
            echo Run option 1 to install dependencies.
            pause
            cd "%~dp0"
            goto :MENU
        )
    )
    
    echo.
    echo Checking build environment...
    echo DEVKITPRO=%DEVKITPRO%
    echo DEVKITPPC=%DEVKITPPC%
    
    :: Check for required WUT tools
    if exist "%DEVKITPRO%\wut\share\wut_rules" (
        echo WUT rules found
    ) else (
        echo WARNING: WUT rules not found - build may fail
    )
    
    echo.
    echo Cleaning previous build files...
    make clean 2>nul
    
    echo Compiling...
    echo This may take a few minutes...
    make -j4
    
    if exist "balatro_wiiu.wuhb" (
        echo.
        echo ================================
        echo C++ build completed successfully!
        echo ================================
        copy "balatro_wiiu.wuhb" "..\%OUTPUT_NAME%.wuhb" >nul
        echo Output: %OUTPUT_NAME%.wuhb
        echo.
        echo The WUHB file is ready for Wii U!
        echo You can now use option 3 to deploy it.
    ) else if exist "balatro_wiiu.rpx" (
        echo.
        echo C++ build completed (RPX only)!
        copy "balatro_wiiu.rpx" "..\%OUTPUT_NAME%.rpx" >nul
        echo Output: %OUTPUT_NAME%.rpx
        echo Note: WUHB creation failed, but RPX is available
    ) else (
        echo.
        echo ================================
        echo ERROR: C++ build failed
        echo ================================
        echo Checking for common issues...
        if not exist "src\main.cpp" (
            echo - Missing src/main.cpp
        )
        if not exist "Makefile" (
            echo - Missing Makefile
        )
        echo.
        echo Debug information:
        echo DEVKITPRO=%DEVKITPRO%
        echo Current directory: %CD%
        echo.
        echo Build errors:
        make 2>&1
        echo.
        echo Try running option 1 to install dependencies first.
        pause
        cd "%~dp0"
        goto :MENU
    )
    
    cd "%~dp0"
) else (
    echo ERROR: Conversion failed - build directory not created.
    echo Make sure tools\balatro_converter.py exists and works correctly.
    pause
    goto :MENU
)

pause
goto :MENU

:DEPLOY
cls
echo ================================
echo Deploying to Wii U...
echo ================================

:: Check if there are files to deploy
if not exist "*.wuhb" if not exist "*.rpx" (
    echo ERROR: No WUHB or RPX files found to deploy.
    echo Please run option 2 to build first.
    pause
    goto :MENU
)

set /p WIIU_IP="Enter Wii U IP address: "
python tools\deploy_wiiu.py %WIIU_IP%

pause
goto :MENU

:CLEAN
cls
echo ================================
echo Cleaning build files...
echo ================================

if exist "%CPP_BUILD_DIR%" (
    echo Removing C++ build directory...
    rmdir /s /q "%CPP_BUILD_DIR%"
)

if exist "*.wuhb" (
    echo Removing WUHB files...
    del /q "*.wuhb"
)

if exist "*.rpx" (
    echo Removing RPX files...
    del /q "*.rpx"
)

echo Cleanup completed!
echo NOTE: Dependencies (DevkitPro, MSYS2) were NOT removed.
echo To remove them, use Windows "Add or Remove Programs"

pause
goto :MENU