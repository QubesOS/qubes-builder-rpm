#!/bin/sh

pushd $SCRIPTSDIR
rm -f keys base_rpms
ln -sf keys_$DIST keys
ln -sf base_rpms_$DIST base_rpms
popd

createrepo -q -g $SCRIPTSDIR/../comps-qubes-template.xml pkgs-for-template/$DIST -o pkgs-for-template/$DIST
chown -R --reference=pkgs-for-template/$DIST pkgs-for-template/$DIST
