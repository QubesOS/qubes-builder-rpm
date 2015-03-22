#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

INSTALLDIR=${PWD}/mnt

echo "-->  Creating Xwrapper.config override..."
mkdir -p ${INSTALLDIR}/etc/X11
cat > "${INSTALLDIR}/etc/X11/Xwrapper.config" <<EOF
allowed_users = anybody
needs_root_rights = yes
EOF

echo "--> Setting locale to utf8..."
cat > "${INSTALLDIR}/etc/locale.conf" <<EOF
LANG=en_US.utf8
EOF

