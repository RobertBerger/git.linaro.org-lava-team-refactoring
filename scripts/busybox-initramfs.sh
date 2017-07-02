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

# NOT to be run on the main system - this script is intended for
# a dedicated jenkins slave or disposable chroot.

# The ./initramfs directory is left behind.

set -e

if [ -z "$1" ]; then
    echo "Specify the architecture"
    exit
fi

ARCH=`dpkg-architecture -a $1 -q DEB_HOST_ARCH`

apt-get clean
apt -y install cpio
dpkg --add-architecture $ARCH
apt -q update
apt -d install busybox-static:$ARCH
mkdir initramfs
dpkg -X /var/cache/apt/archives/busybox-static_*_${ARCH}.deb ./initramfs/
ln -sr initramfs/bin/busybox initramfs/bin/sh
cd initramfs/
echo "Making directories"
mkdir proc sys dev etc etc/init.d root sbin usr/bin usr/sbin
echo "Making device notes"
mknod -m 622 dev/console c 5 1
mknod -m 622 dev/tty0 c 4 0
echo "Making rcS"
cat <<EOT >> etc/init.d/rcS
#!/bin/sh

#Create all the symlinks to /bin/busybox
/bin/busybox --install -s

#Mount things needed by this script
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs none /dev

[ -z "\$CMDLINE" ] && CMDLINE=\`cat /proc/cmdline\`
for arg in \$CMDLINE; do
    optarg=\`expr "x\$arg" : 'x[^=]*=\(.*\)'\`
    case \$arg in
        console=*)
            tty=\${arg#console=}
            tty=\${tty#/dev/}
            case \$tty in
                tty[a-zA-Z]* )
                    port=\${tty%%,*}
            esac ;;
        debug) set -x ;;
    esac
done

export PS1="root@busybox: #"

#Create device nodes
mdev -s

setsid sh </dev/\${port} >/dev/\${port} 2>&1

EOT
chmod +x etc/init.d/rcS
echo "Symlinking /init"
ln -sr ./bin/busybox ./init
echo "Creating initramfs-${ARCH}.cpio"
find . | cpio -o --format=newc > ../initramfs-${ARCH}.cpio
cd ..
echo "Compressing"
gzip -f initramfs-${ARCH}.cpio
md5sum initramfs-${ARCH}.cpio.gz
sha256sum initramfs-${ARCH}.cpio.gz
echo "prompt: root@busybox: #"
