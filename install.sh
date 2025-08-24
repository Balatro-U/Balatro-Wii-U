#!/bin/bash
#!/bin/bash

# Self-elevate if not running as root
if [ "$EUID" -ne 0 ]; then
	if [ -z "$SUDO_COMMAND" ]; then
		echo "This script requires root privileges. Re-running with sudo..."
		exec sudo bash "$0" "$@"
	fi
fi

sudo rm -rf Balatro-Wii-U
git clone https://github.com/xtomasnemec/Balatro-Wii-U.git
sudo chmod +x ./Balatro-Wii-U/build.sh