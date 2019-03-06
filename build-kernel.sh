#!/bin/bash

set -x
set -e

export LC_ALL=C

ERR='\033[0;31m'
INFO='\033[0;32m'
NC='\033[0m' # No Color


if [ $EUID -ne 0 ]; then
    echo -e "$ERR ERROR: This script should be run as root. $NC" 1>&2
    exit 1
fi

clear
WELCOME="This installer will download and compile a Linux kernel\n
Important: create a backup copy of the system before installation!\n
continue installation?"

if (whiptail --title "emPC-X Installation Script" --yesno "$WELCOME" 20 60) then
    echo ""
else
    exit 0
fi

apt-get update -y

# Remove old Kernel sources
rm -f /usr/src/linux-source-*.tar.xz

DEBIAN_FRONTEND=noninteractive apt-get purge -y linux-source linux-source-*
DEBIAN_FRONTEND=noninteractive apt-get install -y linux-source build-essential libncurses5-dev fakeroot bc

cd /usr/src/
rm -rf KERNEL

mkdir -p KERNEL
cd KERNEL

# Extract Kernel
tar -xaf /usr/src/linux-source-*.tar.xz

cd linux-source*

# Apply Janz Tec specific Kernel patches
wget -nv https://github.com/janztec/empc-x-linux-drivers/raw/master/src/0006-serial.patch -O 0006-serial.patch
patch -p2 < 0006-serial.patch


# Use current Kernel configuration
cp /boot/config-`uname -r` .config
make olddefconfig

# Compile using 2 CPUs
if make -j2; then
    # Install Kernel and modules
    if make modules_install; then
        if make install; then
            if (whiptail --title "Info" --yesno "Installation completed! reboot required\n\nreboot now?" 12 60) then
                reboot
            fi
            exit 0
        fi
    fi
fi

echo "Error. Installation failed!"
exit 1
