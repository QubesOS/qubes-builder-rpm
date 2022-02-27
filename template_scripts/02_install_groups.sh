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
info ' Distribution specific steps (install systemd, add sources, etc)'
#### '----------------------------------------------------------------------
buildStep "$0" "${DIST}"

#### '----------------------------------------------------------------------
info " Installing extra packages in script_${DIST}/packages.list file"
#### '----------------------------------------------------------------------
export YUM0=${PWD}/pkgs-for-template
chroot_cmd ${YUM} clean all
installPackages
yumUpdate

if [ "$TEMPLATE_ROOT_FSTYPE" = "btrfs" ]; then
    yumInstall btrfs-progs
fi

#### '----------------------------------------------------------------------
info ' Cleanup'
#### '----------------------------------------------------------------------
trap - ERR EXIT
trap
