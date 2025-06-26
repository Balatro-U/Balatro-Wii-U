import os
import sys
import urllib.request
import subprocess
import shutil
from pathlib import Path
import ctypes

def is_admin():
    """Check if running with admin privileges"""
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False

def download_file(url, filename):
    """Download file with progress"""
    print(f"Downloading {filename}...")
    try:
        urllib.request.urlretrieve(url, filename)
        print(f"Downloaded {filename} successfully")
        return True
    except Exception as e:
        print(f"Failed to download {filename}: {e}")
        return False

def run_installer(installer_path):
    """Run installer"""
    try:
        print(f"Running installer: {installer_path}")
        result = subprocess.run([installer_path, "/S"], check=False, capture_output=True, text=True)
        if result.returncode == 0:
            print("Installation completed successfully")
            return True
        else:
            print("Silent install failed, trying interactive install...")
            result = subprocess.run([installer_path], check=False)
            print("Please complete the installation manually")
            return True
    except Exception as e:
        print(f"Failed to run installer: {e}")
        return False

def install_msys2():
    """Install MSYS2"""
    print("Installing MSYS2...")
    msys2_path = "C:\\msys64"
    if os.path.exists(msys2_path):
        print("MSYS2 already installed")
        return True
    msys2_url = "https://github.com/msys2/msys2-installer/releases/latest/download/msys2-x86_64-latest.exe"
    installer_path = "msys2-installer.exe"
    if download_file(msys2_url, installer_path):
        if run_installer(installer_path):
            print("MSYS2 installation completed")
            if os.path.exists(installer_path):
                os.remove(installer_path)
            return True
        if os.path.exists(installer_path):
            os.remove(installer_path)
    return False

def install_devkitpro():
    """Install DevkitPro"""
    print("Installing DevkitPro...")
    devkit_path = "C:\\devkitPro"
    if os.path.exists(devkit_path):
        print("DevkitPro already installed")
        return True
    devkit_url = "https://github.com/devkitPro/installer/releases/latest/download/devkitProUpdater-3.0.4.exe"
    installer_path = "devkitpro-installer.exe"
    if download_file(devkit_url, installer_path):
        if run_installer(installer_path):
            print("DevkitPro installation completed")
            if os.path.exists(installer_path):
                os.remove(installer_path)
            return True
        if os.path.exists(installer_path):
            os.remove(installer_path)
    return False

def setup_environment():
    """Setup environment variables"""
    print("Setting up environment variables...")
    devkitpro_path = "C:\\devkitPro"
    if os.path.exists(devkitpro_path):
        os.environ["DEVKITPRO"] = devkitpro_path
        os.environ["DEVKITPPC"] = f"{devkitpro_path}\\devkitPPC"
        print("Environment variables set for current session")
        return True
    else:
        print("DevkitPro installation directory not found")
        return False

def install_wut_packages():
    """Install WUT packages via pacman"""
    print("Installing WUT packages...")
    msys2_path = "C:\\msys64\\usr\\bin\\bash.exe"
    if os.path.exists(msys2_path):
        commands = [
            "pacman -Sy --noconfirm",
            "pacman -S --noconfirm --needed base-devel",
            "pacman -S --noconfirm --needed wut-tools",
            "pacman -S --noconfirm --needed wiiu-dev",
            "pacman -S --noconfirm --needed devkitPPC"
        ]
        success_count = 0
        for cmd in commands:
            try:
                print(f"Running: {cmd}")
                result = subprocess.run([msys2_path, "-c", cmd], check=False, capture_output=True, text=True, timeout=300)
                if result.returncode == 0:
                    print(f"Success: {cmd}")
                    success_count += 1
                else:
                    print(f"Warning: {cmd} - {result.stderr}")
            except subprocess.TimeoutExpired:
                print(f"Timeout: {cmd}")
            except Exception as e:
                print(f"Failed: {cmd} - {e}")
        if success_count >= 3:
            return True
        else:
            return False
    else:
        print("MSYS2 not found, skipping package installation")
        return False

def main():
    print("DevkitPro Automated Installer")
    print("==============================")
    if not is_admin():
        print("WARNING: Not running as administrator")
        print("Some installations may fail")
    success_count = 0
    total_steps = 4
    print("\nStep 1/4: Installing MSYS2...")
    if install_msys2():
        success_count += 1
    print("\nStep 2/4: Installing DevkitPro...")
    if install_devkitpro():
        success_count += 1
    print("\nStep 3/4: Setting up environment...")
    if setup_environment():
        success_count += 1
    print("\nStep 4/4: Installing WUT packages...")
    if install_wut_packages():
        success_count += 1
    print(f"\nCompleted {success_count}/{total_steps} steps successfully")
    if success_count >= 3:
        print("Most dependencies installed successfully!")
        print("Please restart your command prompt or computer")
        print("to ensure environment variables are loaded.")
        return True
    else:
        print("Several installations failed. Please check the output above.")
        print("You may need to install some components manually:")
        print("- MSYS2: https://www.msys2.org/")
        print("- DevkitPro: https://github.com/devkitPro/installer/releases")
        return False

if __name__ == "__main__":
    success = main()
    input("Press Enter to continue...")
    sys.exit(0 if success else 1)
