#!/bin/sh

set -e

# Download Debian armmp kernel package and build files suitable
# for a LAVA pipeline job into a lava/ directory in the current
# working directory - unless the package already exists there.

# The dtb needs to be copied manually, depending on the board.
# Needs an apt source for arch=armhf.
# Jessie or newer only.

CWD=`pwd`
if [ ! -d 'lava' ]; then
	mkdir lava
fi
PKG=`apt show linux-image-armmp 2>/dev/null|grep Depends|cut -d' ' -f2`
VER=`apt list ${PKG} 2>/dev/null|grep -v Listing|cut -d' ' -f2`
if [ -f "lava/${PKG}_${VER}_armhf.deb" ]; then
	exit 0
fi
rm -rf lava/*
mkdir lava/dtbs
sudo apt -dy install $PKG
cp /var/cache/apt/archives/${PKG}_${VER}_armhf.deb lava/.
# linux-image-3.16.0-4-armmp_3.16.7-ckt7-1_armhf.deb
DIR=`mktemp -d`
cd ${DIR}
dpkg -X /var/cache/apt/archives/${PKG}_${VER}_armhf.deb .
find lib -type d -o -type f -name modules.\*  -o -type f -name \*.ko \
 \( -path \*/kernel/lib/\* -o  -path \*/kernel/crypto/\* \
 -o  -path \*/kernel/fs/mbcache.ko -o  -path \*/kernel/fs/ext\* \
 -o  -path \*/kernel/fs/jbd\* -o  -path \*/kernel/drivers/net/\* \
 -o -path \*/kernel/drivers/ata/\* -o  -path \*/kernel/drivers/scsi/\* \
 -o -path \*/kernel/drivers/md/\* \) -print0 | tar cfz ${CWD}/lava/modules.tgz --null -T -
cp ./boot/vmlinuz-*-armmp ${CWD}/lava/
cp -r ./usr/lib/${PKG}/* ${CWD}/lava/dtbs/
cd ${CWD}
rm -rf ${DIR}
