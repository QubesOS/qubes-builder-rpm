#!/bin/sh

createrepo -q -g $SCRIPTSDIR/../comps-qubes-template.xml pkgs-for-template/$DIST -o pkgs-for-template/$DIST
chown -R --reference=pkgs-for-template/$DIST pkgs-for-template/$DIST
