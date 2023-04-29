#!/bin/sh

set -ex

[ -z "$1" ] && { echo "Usage: $0 <repo_dir>"; exit 1; }

REPO_DIR="$1"

# shellcheck disable=SC2230
createrepo="$(which createrepo_c createrepo | head -n 1)"

mkdir -p "$REPO_DIR/rpm"
if [ -e "$REPO_DIR/repodata/repomd.xml" ]; then
    $createrepo --update -q "$REPO_DIR"
else
    $createrepo -q "$REPO_DIR"
fi

if [ "$(id -u)" -eq 0 ]; then
    chown -R --reference="$REPO_DIR/.." "$REPO_DIR"
fi
