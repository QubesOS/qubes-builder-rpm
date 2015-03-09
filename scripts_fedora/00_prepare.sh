#!/bin/sh

pushd $SCRIPTSDIR
rm -f keys base_rpms
ln -sf keys_$DIST keys
ln -sf base_rpms_$DIST base_rpms
popd

createrepo -q -g $PWD/comps-qubes-template.xml yum_repo_qubes/$DIST -o yum_repo_qubes/$DIST
chown -R --reference=yum_repo_qubes/$DIST yum_repo_qubes/$DIST
