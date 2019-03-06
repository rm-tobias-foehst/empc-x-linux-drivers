#!/bin/bash

export LC_ALL=C

ERR='\033[0;31m'
INFO='\033[0;32m'
NC='\033[0m' # No Color

KERNEL=$(uname -r)

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

rm -f /usr/src/linux-source-*.tar.xz

DEBIAN_FRONTEND=noninteractive apt-get install -y linux-source build-essential libncurses5-dev fakeroot bc

cd /usr/src/
mkdir kernel
cd kernel

tar -xaf /usr/src/linux-source-*.tar.xz
cp /boot/config-`uname -r` .config
make olddefconfig
make -j2

make modules_install
make install
