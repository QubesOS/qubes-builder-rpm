#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

echo "-->  Creating Xwrapper.config override..."
cat > "${INSTALLDIR}/etc/X11/Xwrapper.config" <<EOF
allowed_users = anybody
needs_root_rights = yes
EOF

echo "--> Setting locale to utf8..."
cat > "${INSTALLDIR}/etc/locale.conf" <<EOF
LANG=en_US.utf8
EOF
