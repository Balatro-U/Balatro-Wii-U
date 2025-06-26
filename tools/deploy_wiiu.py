import ftplib
import os
import sys

def find_wuhb_files():
    """Find all WUHB files to deploy"""
    wuhb_files = []
    for file in os.listdir('.'):
        if file.endswith('.wuhb'):
            wuhb_files.append(file)
    return wuhb_files

def deploy_to_wiiu(wiiu_ip):
    """Deploy WUHB files to Wii U via FTP"""
    try:
        print(f"Connecting to Wii U at {wiiu_ip}...")
        ftp = ftplib.FTP(wiiu_ip, timeout=10)
        ftp.login()

        # Create app directory
        try:
            ftp.mkd('/fs/vol/external01/wiiu/apps/balatro')
        except:
            pass

        # Deploy WUHB files
        wuhb_files = find_wuhb_files()
        if not wuhb_files:
            print("No WUHB files found to deploy!")
            return False
        for wuhb_file in wuhb_files:
            print(f"Uploading {wuhb_file}...")
            with open(wuhb_file, 'rb') as f:
                ftp.storbinary(f'STOR /fs/vol/external01/wiiu/apps/balatro/{wuhb_file}', f)

        ftp.quit()
        print("Deployment successful!")
        return True

    except Exception as e:
        print(f"Deployment failed: {e}")
        print("Make sure:")
        print("1. Wii U is connected to same network")
        print("2. FTP server is running on Wii U (ftpiiu or similar)")
        print("3. IP address is correct")
        return False

if __name__ == "__main__":
    if len(sys.argv) != 2:
        wiiu_ip = input("Enter Wii U IP address: ")
    else:
        wiiu_ip = sys.argv[1]

    if deploy_to_wiiu(wiiu_ip):
        print("Ready to run on Wii U!")
        print("Launch from Homebrew Launcher")
    else:
        print("Deployment failed.")