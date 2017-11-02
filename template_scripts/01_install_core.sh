#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

source "${SCRIPTSDIR}/distribution.sh"

export YUM_OPTS
${SCRIPTSDIR}/../prepare-chroot-base "${INSTALLDIR}" "${DIST}"

cp "${SCRIPTSDIR}/resolv.conf" "${INSTALLDIR}/etc/"
chmod 644 "${INSTALLDIR}/etc/resolv.conf"
cp "${SCRIPTSDIR}/network" "${INSTALLDIR}/etc/sysconfig/"
chmod 644 "${INSTALLDIR}/etc/sysconfig/network"
cp -a /dev/null /dev/zero /dev/random /dev/urandom "${INSTALLDIR}/dev/"

export YUM0=${PWD}/pkgs-for-template
yumInstall $YUM
