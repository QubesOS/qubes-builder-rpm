#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

source "${SCRIPTSDIR}/distribution.sh"

export YUM_OPTS
${SCRIPTSDIR}/../prepare-chroot-base "${INSTALLDIR}" "${DIST}"

if grep -q openSUSE /etc/os-release; then
    # Build the rpmdb again, in case of huge rpm version difference that makes
    # rpmdb --rebuilddb doesn't work anymore. Export using rpm from outside
    # chroot and import using rpm from within chroot
    rpmdb "${RPM_OPTS[@]}" --root="${INSTALLDIR}" --exportdb > "${CACHEDIR}/rpmdb.export" || exit 1
    rm -rf "${INSTALLDIR}/var/lib/rpm"
    chroot "${INSTALLDIR}" rpmdb --importdb < "${CACHEDIR}/rpmdb.export" || exit 1
fi

# remove systemd-resolved symlink
rm -f "${INSTALLDIR}/etc/resolv.conf"
cp "${SCRIPTSDIR}/resolv.conf" "${INSTALLDIR}/etc/"
chmod 644 "${INSTALLDIR}/etc/resolv.conf"
cp "${SCRIPTSDIR}/network" "${INSTALLDIR}/etc/sysconfig/"
chmod 644 "${INSTALLDIR}/etc/sysconfig/network"
cp -a /dev/null /dev/zero /dev/random /dev/urandom "${INSTALLDIR}/dev/"

export YUM0=${PWD}/pkgs-for-template
yumInstall $YUM
