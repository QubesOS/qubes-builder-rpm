#!/bin/sh

rm -f $INSTALLDIR/var/lib/rpm/__db.00* $INSTALLDIR/var/lib/rpm/.rpm.lock
yum -c $PWD/yum.conf $YUM_OPTS clean packages --installroot=$INSTALLDIR

# Make sure that rpm database has right format (for rpm version in template, not host)
echo "--> Rebuilding rpm database..."
chroot `pwd`/mnt /bin/rpm --rebuilddb 2> /dev/null
