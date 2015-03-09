#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

source "${SCRIPTSDIR}/distribution.sh"

${SCRIPTSDIR}/../prepare-chroot-base "${INSTALLDIR}" "${DIST}"

cp "${SCRIPTSDIR}/resolv.conf" "${INSTALLDIR}/etc"
cp "${SCRIPTSDIR}/network" "${INSTALLDIR}/etc/sysconfig"
cp -a /dev/null /dev/zero /dev/random /dev/urandom "${INSTALLDIR}/dev/"
