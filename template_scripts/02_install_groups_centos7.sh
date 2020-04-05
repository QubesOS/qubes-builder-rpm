#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

source "${SCRIPTSDIR}/distribution.sh"
INSTALLDIR=${PWD}/mnt

#### '----------------------------------------------------------------------
info ' Trap ERR and EXIT signals and cleanup (umount)'
#### '----------------------------------------------------------------------
trap cleanup ERR
trap cleanup EXIT

#### '----------------------------------------------------------------------
info ' Enable fepitre/epel-7-qubes COPR repo'
#### '----------------------------------------------------------------------
yumCopr enable fepitre/epel-7-qubes

#### '----------------------------------------------------------------------
info ' Cleanup'
#### '----------------------------------------------------------------------
trap - ERR EXIT
trap
