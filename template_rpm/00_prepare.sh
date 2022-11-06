#!/bin/sh
# shellcheck disable=SC2230
createrepo="$(which createrepo_c createrepo | head -n 1)"

$createrepo -q -g "$SCRIPTSDIR/../comps-qubes-template.xml" "pkgs-for-template/$DIST" -o "pkgs-for-template/$DIST"
chown -R --reference="pkgs-for-template/$DIST" "pkgs-for-template/$DIST"
