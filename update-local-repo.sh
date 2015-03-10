#!/bin/sh

set -e

[ -z "$1" ] && { echo "Usage: $0 <dist>"; exit 1; }

REPO_DIR=$BUILDER_REPO_DIR
DIST=$1

mkdir -p $REPO_DIR/rpm
if [ -e $REPO_DIR/repodata/repomd.xml ]; then
    createrepo --update -q $REPO_DIR
else
    createrepo -q $REPO_DIR
fi

if [ `id -u` -eq 0 ]; then
    chown -R --reference=$REPO_DIR/.. $REPO_DIR
fi
