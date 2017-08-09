!#/bin/bash

export LC_ALL=C

apt-get update -y
apt-get -y install whiptail

clear
WELCOME="These drivers will be compiled and installed:\n
- CAN driver (SocketCAN)\n
These software components will be installed:\n
- autoconf, libtool, libsocketcan, can-utils\n
continue installation?"

if (whiptail --title "emPC-X Installation Script" --yesno "$WELCOME" 20 60) then
    echo ""
else
    exit 0
fi


apt-get -y install bc build-essential linux-headers-$(uname -r)

# get installed gcc version
GCCVERBACKUP=$(gcc --version | egrep -o '[0-9]+\.[0-9]+' | head -n 1)
# get gcc version of installed kernel
GCCVER=$(cat /proc/version | egrep -o 'gcc version [0-9]+\.[0-9]+' | egrep -o '[0-9.]+')



if [ ! -f "/usr/bin/gcc-$GCCVER" ] || [ ! -f "/usr/bin/g++-$GCCVER" ]; then
    echo "no such version gcc/g++ $GCCVER installed" 1>&2
    exit 1
fi

update-alternatives --remove-all gcc 
update-alternatives --remove-all g++

update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-$GCCVERBACKUP 10
update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-$GCCVERBACKUP 10

update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-$GCCVER 50
update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-$GCCVER 50

update-alternatives --set gcc "/usr/bin/gcc-$GCCVER"
update-alternatives --set g++ "/usr/bin/g++-$GCCVER"


#rm -rf /tmp/empc-x-linux-drivers
mkdir -p /tmp/empc-x-linux-drivers
cd /tmp/empc-x-linux-drivers


KERNEL=$(uname -r)

VERSION=$(echo $KERNEL | cut -d. -f1)
PATCHLEVEL=$(echo $KERNEL | cut -d. -f2)
SUBLEVEL=$(echo $KERNEL | cut -d. -f3 | cut -d- -f1)




wget -nv https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git/plain/drivers/net/can/sja1000/sja1000.c?h=v$VERSION.$PATCHLEVEL.$SUBLEVEL -O sja1000.c
wget -nv https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git/plain/drivers/net/can/sja1000/sja1000.h?h=v$VERSION.$PATCHLEVEL.$SUBLEVEL -O sja1000.h
wget -nv https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git/plain/drivers/net/can/sja1000/sja1000_platform.c?h=v$VERSION.$PATCHLEVEL.$SUBLEVEL -O sja1000_platform.c

echo "obj-m += sja1000.o" >Makefile
echo "obj-m += sja1000_platform.o" >>Makefile

echo "all:">>Makefile
echo -e "\tmake -C /lib/modules/$KERNEL/build M=/tmp/empc-x-linux-drivers modules" >>Makefile

make


if [ ! -f "sja1000.ko" ] || [ ! -f "sja1000_platform.ko" ]; then
 echo -e "$ERR Error: Installation failed! (driver modules build failed) $NC" 1>&2
 whiptail --title "Error" --msgbox "Installation failed! (driver modules build failed)" 10 60
 exit 1
fi

/bin/cp -rf sja1000.ko /lib/modules/$KERNEL/kernel/drivers/net/can/spi/sja1000.ko
/bin/cp -rf sja1000_platform.ko /lib/modules/$KERNEL/kernel/drivers/net/can/spi/sja1000_platform.ko


if [ ! -f "/usr/local/bin/cansend" ]; then
 if (whiptail --title "emPC-A/RPI3 Installation Script" --yesno "Third party SocketCan library and utilities\n\n- libsocketcan-0.0.10\n- can-utils\n - candump\n - cansend\n - cangen\n\ninstall?" 16 60) then

    apt-get -y install git
    apt-get -y install autoconf
    apt-get -y install libtool

    cd /usr/src/

    wget http://www.pengutronix.de/software/libsocketcan/download/libsocketcan-0.0.10.tar.bz2
    tar xvjf libsocketcan-0.0.10.tar.bz2
    rm -rf libsocketcan-0.0.10.tar.bz2
    cd libsocketcan-0.0.10
    ./configure && make && make install

    cd /usr/src/

    git clone https://github.com/linux-can/can-utils.git
    cd can-utils
    ./autogen.sh
    ./configure && make && make install

 fi
fi


update-alternatives --set gcc "/usr/bin/gcc-$GCCVERBACKUP"
update-alternatives --set g++ "/usr/bin/g++-$GCCVERBACKUP"

