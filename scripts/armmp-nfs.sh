#!/bin/sh

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
#

set -e
set -x

SUITE=jessie
INCLUDE=''

while getopts "d:" opt; do
  case $opt in
    d)
      SUITE=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

if [ ${SUITE} = 'unstable' -o ${SUITE} = 'stretch' ]; then
    INCLUDE='--include systemd-sysv'
fi

rm -rf ${SUITE}-armhf/
debootstrap ${INCLUDE} --foreign --arch=armhf ${SUITE} ${SUITE}-armhf http://mirror.bytemark.co.uk/debian
echo deb http://mirror.bytemark.co.uk/debian ${SUITE} main > ${SUITE}-armhf/etc/apt/sources.list
echo ${SUITE} > ${SUITE}-armhf/etc/hostname
cp /usr/bin/qemu-arm-static ${SUITE}-armhf/usr/bin/
chroot ${SUITE}-armhf/ debootstrap/debootstrap --second-stage
chroot ${SUITE}-armhf/ passwd root -d
chroot ${SUITE}-armhf/ apt -q update
chroot ${SUITE}-armhf/ apt -y -q install linux-image-armmp
mv ${SUITE}-armhf/boot/* .
mv ${SUITE}-armhf/usr/lib/linux-image-* .
mv linux-image-* dtbs

if [ ${SUITE} = 'unstable' -o ${SUITE} = 'stretch' ]; then
  chroot ${SUITE}-armhf/ systemctl enable systemd-resolved
  rm ${SUITE}-armhf/etc/resolv.conf
  chroot ${SUITE}-armhf/ ln -sfT /run/systemd/resolve/resolv.conf /etc/resolv.conf
  echo '[Match]' > ${SUITE}-armhf/etc/systemd/network/99-dhcp.network
  echo 'Name=e*' >> ${SUITE}-armhf/etc/systemd/network/99-dhcp.network
  echo '' >> ${SUITE}-armhf/etc/systemd/network/99-dhcp.network
  echo '[Network]' >> ${SUITE}-armhf/etc/systemd/network/99-dhcp.network
  echo 'DHCP=yes' >> ${SUITE}-armhf/etc/systemd/network/99-dhcp.network
fi

tar -C ${SUITE}-armhf/ -czf modules.tar.gz ./lib/modules/
rm -rf ${SUITE}-armhf/lib/modules/
tar -C ${SUITE}-armhf/ -czf ${SUITE}-armhf-nfs.tar.gz .
rm -rf ${SUITE}-armhf/
ln -s initrd.img-*  initramfs.cpio.gz
ln -s vmlinuz-* vmlinuz
md5sum initramfs.cpio.gz > initramfs.cpio.gz.md5sum.txt
sha256sum initramfs.cpio.gz > initramfs.cpio.gz.sha256sum.txt
md5sum vmlinuz > vmlinuz.md5sum.txt
sha256sum vmlinuz > vmlinuz.sha256sum.txt
md5sum ${SUITE}-armhf-nfs.tar.gz > ${SUITE}-armhf-nfs.tar.gz.md5sum.txt
sha256sum ${SUITE}-armhf-nfs.tar.gz > ${SUITE}-armhf-nfs.tar.gz.sha256sum.txt
md5sum modules.tar.gz > modules.tar.gz.md5sum.txt
sha256sum modules.tar.gz > modules.tar.gz.sha256sum.txt
md5sum dtbs/* > dtbs.md5sum.txt
sha256sum dtbs/* > dtbs.sha256sum.txt
