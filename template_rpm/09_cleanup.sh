#!/bin/bash
#
# The Qubes OS Project, http://www.qubes-os.org
#
# Copyright (C) 2015 Marek Marczykowski-Górecki <marmarek@invisiblethingslab.com>
# Copyright (C) 2021 Ivan Kardykov <kardykov@tabit.pro>
# Copyright (C) 2022 Frédéric Pierret (fepitre) <frederic@invisiblethingslab.com>
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
# You should have received a copy of the GNU General Public License along
# with this program. If not, see <https://www.gnu.org/licenses/>.
#
# SPDX-License-Identifier: GPL-2.0-or-later

# shellcheck source=template_rpm/distribution.sh
source "${TEMPLATE_CONTENT_DIR}/distribution.sh"

dbpath=$(chroot "${INSTALL_DIR}" rpm --eval '%{_dbpath}') || exit 1
rm -f "${INSTALL_DIR}${dbpath}"/__db.00* "${INSTALL_DIR}${dbpath}"/.rpm.lock
rm -f "${INSTALL_DIR}"/var/lib/systemd/random-seed
rm -rf "${INSTALL_DIR}"/var/log/journal/*

if [ "0${IS_LEGACY_BUILDER}" -eq 1 ]; then
    DNF_CONF="${SCRIPTSDIR}/../template-yum-${DIST_NAME}.conf"
else
    DNF_CONF="${PLUGINS_DIR}/source_rpm/dnf/template-dnf-${DIST_NAME}.conf"
fi

set -e
rootdir=$(readlink -f "${INSTALL_DIR}")
dnf -c "${DNF_CONF}" "${DNF_OPTS[@]}" clean packages "--installroot=$rootdir"

# Make sure that rpm database has right format (for rpm version in template, not host)
echo "--> Rebuilding rpm database..."
chroot "${INSTALL_DIR}" /bin/rpm --rebuilddb 2> /dev/null

if [ -x "${INSTALL_DIR}"/usr/bin/dnf ]; then
    chroot "${INSTALL_DIR}" dnf clean all
    # if dnf is used, remove yum cache completely
    rm -rf "${INSTALL_DIR}"/var/cache/yum/* || :
fi

truncate --no-create --size=0 "${INSTALL_DIR}"/var/log/dnf.*

if containsFlavor selinux; then
    sed -i -- 's/^SELINUX=\(disabled\|enforcing\)/SELINUX=permissive/' "$INSTALL_DIR/etc/selinux/config"
    unshare --mount -- chroot -- "$INSTALL_DIR" /bin/sh -euc 'mount --bind -- / "$2"
        umask 0755
        mkdir -p -m 0700 -- /dev /var /run
        mkdir -p -m 1777 -- /tmp /var/tmp /dev/shm
        find /tmp /var/tmp /run /dev/shm -mindepth 1 -delete
        : > /.qubes-relabeled
        rm -f /.autorelabel
        setfiles -r "$2" -- "/etc/selinux/$1/contexts/files/file_contexts" "$2"' sh targeted /mnt
    echo 'selinux=1' > ./template.conf
fi

exit 0
