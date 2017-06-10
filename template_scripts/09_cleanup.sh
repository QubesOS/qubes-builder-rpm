#!/bin/sh

rm -f $INSTALLDIR/var/lib/rpm/__db.00* $INSTALLDIR/var/lib/rpm/.rpm.lock
rm -f $INSTALLDIR/var/lib/systemd/random-seed
yum -c $SCRIPTSDIR/../template-yum.conf $YUM_OPTS clean packages --installroot=$INSTALLDIR

# Make sure that rpm database has right format (for rpm version in template, not host)
echo "--> Rebuilding rpm database..."
chroot `pwd`/mnt /bin/rpm --rebuilddb 2> /dev/null

if [ -x mnt/usr/bin/dnf ]; then
    chroot mnt dnf clean packages
    # if dnf is used, remove yum cache completely
    rm -rf mnt/var/cache/yum/* || :
fi

exit 0
