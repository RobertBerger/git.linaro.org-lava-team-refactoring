#!/bin/sh

# Copyright 2016 Neil Williams <codehelp@debian.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.
#

set -e
set -x

ARCH=amd64
SUITE=jessie
INCLUDE=''
MIRROR=http://mirror.bytemark.co.uk/debian

while getopts "d:m:" opt; do
  case $opt in
    d)
      SUITE=$OPTARG
      ;;
    m)
      MIRROR=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

TARGET=${SUITE}-${ARCH}
NAME=${TARGET}

if [ ${SUITE} = 'unstable' -o ${SUITE} = 'stretch' ]; then
    INCLUDE='--include systemd-sysv'
fi

rm -rf ${TARGET}/
debootstrap ${INCLUDE} ${SUITE} ${TARGET} ${MIRROR}
echo deb ${MIRROR} ${SUITE} main > ${TARGET}/etc/apt/sources.list
echo ${SUITE} > ${TARGET}/etc/hostname
chroot ${TARGET}/ passwd root -d
chroot ${TARGET}/ apt -q update
DEBIAN_FRONTEND=noninteractive LC_ALL=C LANGUAGE=C LANG=C chroot ${TARGET}/ apt -y -q install linux-image-amd64

if [ ${SUITE} = 'unstable' -o ${SUITE} = 'stretch' ]; then
    chroot ${TARGET}/ systemctl enable systemd-resolved
    rm ${TARGET}/etc/resolv.conf
    chroot ${TARGET}/ ln -sfT /run/systemd/resolve/resolv.conf /etc/resolv.conf
fi
mv ${TARGET}/boot/* .
tar -C ${TARGET}/ -czf modules.tar.gz ./lib/modules/
rm -rf ${TARGET}/lib/modules/
tar -C ${TARGET}/ -czf ${NAME}-nfs.tar.gz .
rm -rf ${TARGET}/
ln -s initrd.img-*  initramfs.cpio.gz
ln -s vmlinuz-* vmlinuz
md5sum initramfs.cpio.gz > initramfs.cpio.gz.md5sum.txt
sha256sum initramfs.cpio.gz > initramfs.cpio.gz.sha256sum.txt
md5sum vmlinuz > vmlinuz.md5sum.txt
sha256sum vmlinuz > vmlinuz.sha256sum.txt
md5sum ${NAME}-nfs.tar.gz > ${NAME}-nfs.tar.gz.md5sum.txt
sha256sum ${NAME}-nfs.tar.gz > ${NAME}-nfs.tar.gz.sha256sum.txt
md5sum modules.tar.gz > modules.tar.gz.md5sum.txt
sha256sum modules.tar.gz > modules.tar.gz.sha256sum.txt
