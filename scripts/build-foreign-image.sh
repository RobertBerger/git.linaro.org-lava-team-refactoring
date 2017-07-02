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

SUITE=sid
ARCH=arm64
BIN_FMT=/usr/bin/qemu-aarch64-static
MIRROR=http://mirror.bytemark.co.uk/debian

while getopts "a:b:d:m:" opt; do
  case $opt in
    a)
      ARCH=$OPTARG
      ;;
    b)
      BIN_FMT=$OPTARG
      ;;
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
INCLUDE=''
rm -rf ${TARGET}/

debootstrap ${INCLUDE} --foreign --arch=${ARCH} ${SUITE} ${TARGET} ${MIRROR}
cp ${BIN_FMT} ${TARGET}/usr/bin/
chroot ${TARGET}/ debootstrap/debootstrap --second-stage
echo "deb ${MIRROR} ${SUITE} main" > ${TARGET}/etc/apt/sources.list
echo ${SUITE} > ${TARGET}/etc/hostname
chroot ${TARGET}/ passwd root -d
if [ ${SUITE} = 'sid' -o ${SUITE} = 'stretch' ]; then
    chroot ${TARGET}/ apt -q -y install systemd-sysv
    chroot ${TARGET}/ systemctl enable systemd-networkd
    chroot ${TARGET}/ systemctl enable systemd-resolved
    rm ${TARGET}/etc/resolv.conf
    chroot ${TARGET}/ ln -sfT /run/systemd/resolve/resolv.conf /etc/resolv.conf
    echo '[Match]' > ${TARGET}/etc/systemd/network/99-dhcp.network
    echo 'Name=e*' >> ${TARGET}/etc/systemd/network/99-dhcp.network
    echo '' >> ${TARGET}/etc/systemd/network/99-dhcp.network
    echo '[Network]' >> ${TARGET}/etc/systemd/network/99-dhcp.network
    echo 'DHCP=yes' >> ${TARGET}/etc/systemd/network/99-dhcp.network
fi
tar -C ${TARGET}/ -cf ${NAME}.tar .
rm -rf ${TARGET}/
python ./guest-img.py --name ${NAME} > ${NAME}.img.uuid.txt
cat ${NAME}.img.uuid.txt
rm ${NAME}.tar
gzip ${NAME}.img
md5sum ${NAME}.img.gz > ${NAME}.img.gz.md5sum.txt
sha256sum ${NAME}.img.gz > ${NAME}.img.gz.sha256sum.txt
