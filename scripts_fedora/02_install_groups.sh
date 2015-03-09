#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

source "${SCRIPTSDIR}/distribution.sh"

# Create system mount points
prepareChroot

#### '----------------------------------------------------------------------
info ' Trap ERR and EXIT signals and cleanup (umount)'
#### '----------------------------------------------------------------------
trap cleanup ERR
trap cleanup EXIT

#### '----------------------------------------------------------------------
info " Installing extra packages in script_${DIST}/packages.list file"
#### '----------------------------------------------------------------------
export YUM0=${PWD}/yum_repo_qubes
yum clean all -c ${PWD}/yum.conf ${YUM_OPTS} -y --installroot=${INSTALLDIR}
installPackages
yum update -c ${PWD}/yum.conf ${YUM_OPTS} -y --installroot=${INSTALLDIR} || exit 1

#### '----------------------------------------------------------------------
info ' Cleanup'
#### '----------------------------------------------------------------------
trap - ERR EXIT
trap
