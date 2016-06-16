#!/bin/bash

source "${SCRIPTSDIR}/distribution.sh"

prepareChroot

export YUM0=$PWD/pkgs-for-template
with_optional=
if [ "$TEMPLATE_FLAVOR" == "minimal" ]; then
    YUM_OPTS="$YUM_OPTS --setopt=group_package_types=mandatory"
    rpmbuild -bb --target noarch --define "_rpmdir $CACHEDIR" $SCRIPTSDIR/qubes-template-minimal-stub.spec || exit 1
    stub_name=`ls "$CACHEDIR/noarch/"qubes-template-minimal-stub*rpm|tail -1`
    stub_name=`basename "$stub_name"`
    cp "$CACHEDIR/noarch/$stub_name" ${INSTALLDIR}/tmp/ || exit 1
    chroot_cmd ${YUM} install $YUM_OPTS -y "/tmp/$stub_name" || exit 1
    rm -f "${INSTALLDIR}/tmp/$stub_name"
else
    with_optional=with-optional
fi

echo "--> Installing RPMs..."
yumGroupInstall $with_optional qubes-vm || RETCODE=1

chroot_cmd sh -c 'rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-qubes-*'

if [ "$TEMPLATE_FLAVOR" != "minimal" ]; then
    echo "--> Installing 3rd party apps"
    $SCRIPTSDIR/add_3rd_party_software.sh || RETCODE=1
fi


if [ -e mnt/etc/sysconfig/i18n ]; then
    echo "--> Setting up default locale..."
    echo LC_CTYPE=en_US.UTF-8 > mnt/etc/sysconfig/i18n
fi

# Distribution specific steps
source ./functions.sh
buildStep "${0}" "${DIST}"

exit $RETCODE
