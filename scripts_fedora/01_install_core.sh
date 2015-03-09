#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

source "${SCRIPTSDIR}/distribution.sh"

if ! [ -f "${INSTALLDIR}/tmp/.prepared_base" ]; then
    echo "-> Initializing RPM database..."
    rpm --initdb --root="${INSTALLDIR}"
    rpm --import --root="${INSTALLDIR}" "${SCRIPTSDIR}/keys/"*

    if [ "$DIST" == "fc21" ]; then
        echo "-> Retreiving core RPM packages..."
        INITIAL_PACKAGES="filesystem setup fedora-release"

        yum --disablerepo=\* --enablerepo=fedora -y --installroot="${INSTALLDIR}" --releasever=${DIST/fc/} install --downloadonly --downloaddir="${SCRIPTSDIR}/base_rpms_${DIST}" ${INITIAL_PACKAGES}

        verifyPackages "${SCRIPTSDIR}/base_rpms_${DIST}"/* || exit 1
    fi

    echo "-> Installing core RPM packages..."
    rpm -i --root="${INSTALLDIR}" "${SCRIPTSDIR}/base_rpms/"*.rpm || exit 1

    touch "${INSTALLDIR}/tmp/.prepared_base"
fi

cp "${SCRIPTSDIR}/resolv.conf" "${INSTALLDIR}/etc"
cp "${SCRIPTSDIR}/network" "${INSTALLDIR}/etc/sysconfig"
cp -a /dev/null /dev/zero /dev/random /dev/urandom "${INSTALLDIR}/dev/"
