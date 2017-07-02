#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#  guest-img.py
#
#  Copyright 2016 Neil Williams <codehelp@debian.org>
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#

import os
import sys
import shutil
import atexit
import tarfile
import argparse
import tempfile
import guestfs


def rmtree(directory):
    """
    Wrapper around shutil.rmtree to remove a directory tree while ignoring most
    errors.
    If called on a symbolic link, this function will raise a RuntimeError.
    """
    # TODO: consider how to handle problems if the directory has already been removed -
    # coding bugs may trigger this Runtime exception - implement before moving to production.
    try:
        shutil.rmtree(directory)
    except OSError as exc:
        raise RuntimeError("Error when trying to remove '%s': %s"
                           % (directory, exc))


def mkdtemp(autoremove=True, basedir='/tmp'):
    """
    returns a temporary directory that's deleted when the process exits

    """
    tmpdir = tempfile.mkdtemp(dir=basedir)
    os.chmod(tmpdir, 0o755)
    if autoremove:
        atexit.register(rmtree, tmpdir)
    return tmpdir


def main(name):
    """
    The only output is the blkid
    """
    output = '%s.img' % name
    overlay = '%s.tar' % name
    size = 1024
    guest = guestfs.GuestFS(python_return_dict=True)
    guest.disk_create(output, "raw", size * 1024 * 1024)
    guest.add_drive_opts(output, format="raw", readonly=False)
    guest.launch()
    devices = guest.list_devices()
    if len(devices) != 1:
        raise RuntimeError("Unable to prepare guestfs")
    guest_device = devices[0]
    guest.part_disk(devices[0], "mbr")
    partitions = guest.list_partitions()
    guest_partition = partitions[0]
    guest.mke2fs(guest_partition, label='GUEST')
    # extract to a temp location
    tar_output = mkdtemp()
    # Now mount the filesystem so that we can add files.
    guest.mount(guest_partition, "/")
    guest.tar_in(overlay, '/')
    guest.umount(guest_partition)
    print(guest.blkid(guest_partition)['UUID'])
    return 0

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("--name", help="base name of input and output")
    args = parser.parse_args()
    ret = 1
    try:
        if args.name:
            ret = main(args.name)
    except Exception as exc:
        print(exc)
        sys.exit(2)
    sys.exit(ret)
