#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

source "${SCRIPTSDIR}/distribution.sh"
INSTALLDIR=${PWD}/mnt
VERSION=${DIST/fc/}

#### '----------------------------------------------------------------------
info ' Trap ERR and EXIT signals and cleanup (umount)'
#### '----------------------------------------------------------------------
trap cleanup ERR
trap cleanup EXIT

# Google Chrome
# =============
# Key Details:
# - Download: https://dl-ssl.google.com/linux/linux_signing_key.pub
# - Key ID: Google, Inc. Linux Package Signing Key <linux-packages-keymaster@google.com>
# - Fingerprint: 4CCA 1EAF 950C EE4A B839 76DC A040 830F 7FAC 5991
#
# sudo rpm --import linux_signing_key.pub
#
# You can verify the key installation by running:
# - rpm -qi gpg-pubkey-7fac5991-*
#
# To manually verify an RPM package, you can run the command:
# - rpm --checksig -v packagename.rpm
#
# RPMFusion
# =========
# RPM Fusion free for Fedora 20
# - pub  4096R/AE688223 2013-01-01 RPM Fusion free repository for Fedora (20) <rpmfusion-buildsys@lists.rpmfusion.org>
# Key fingerprint = 0017 DDFE FD13 2929 9D55  B1D3 963A 8848 AE68 8223
#
# RPM Fusion nonfree for Fedora 20
# - pub  4096R/B5F29883 2013-01-01 RPM Fusion nonfree repository for Fedora (20) <rpmfusion-buildsys@lists.rpmfusion.org>
# Key fingerprint = A84D CF58 46CB 10B6 5C47  6C35 63C0 DE8C B5F2 9883
#
# RPM Fusion free for Fedora 21
# - pub  4096R/6446D859 2013-06-28 RPM Fusion free repository for Fedora (21) <rpmfusion-buildsys@lists.rpmfusion.org>
#   Key fingerprint = E9AF 4932 31E2 DF6F FDFE  0852 3C83 7D0D 6446 D859
#
# RPM Fusion nonfree for Fedora 21
# - pub  4096R/A668B376 2013-06-28 RPM Fusion nonfree repository for Fedora (21) <rpmfusion-buildsys@lists.rpmfusion.org>
# Key fingerprint = E160 058E F06F A4C3 C15D  0F86 0174 46D1 A668 B376

#### '----------------------------------------------------------------------
info ' Copying 3rd party software to "tmp" directory to prepare for installation'
#### '----------------------------------------------------------------------
cp -a "${SCRIPTSDIR}/3rd_party_software" "${INSTALLDIR}/tmp"

#### '----------------------------------------------------------------------
info ' Installing google-chrome repos'
#### '----------------------------------------------------------------------
install -m 0644 "${SCRIPTSDIR}/3rd_party_software/google-linux_signing_key.pub" "${INSTALLDIR}/etc/pki/rpm-gpg/"
cat << EOF > "${INSTALLDIR}/etc/yum.repos.d/google-chrome.repo"
[google-chrome]
name=google-chrome - \$basearch
baseurl=http://dl.google.com/linux/chrome/rpm/stable/\$basearch
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/google-linux_signing_key.pub
EOF
 
#### '----------------------------------------------------------------------
info ' Installing adobe repo'
#### '----------------------------------------------------------------------
yumInstall /tmp/3rd_party_software/adobe-release-x86_64.noarch.rpm

if [ "$TEMPLATE_FLAVOR" == "fullyloaded" ]; then
    #### '------------------------------------------------------------------
    info ' Installing 3rd party software'
    #### '------------------------------------------------------------------
    yumInstall google-chrome-stable
    yumInstall flash-plugin
else
    chroot yum-config-manager --disable google-chrome > /dev/null
    chroot yum-config-manager --disable adobe-linux-x86_64 > /dev/null
fi

#### '----------------------------------------------------------------------
info ' Installing rpmfusion repos'
#### '----------------------------------------------------------------------
if [ ${VERSION} -ge 20 ]; then
    # Install repos
    yumInstall /tmp/3rd_party_software/rpmfusion-free-release-${VERSION}.noarch.rpm
    yumInstall /tmp/3rd_party_software/rpmfusion-nonfree-release-${VERSION}.noarch.rpm

    # Disable rpmfusion-free repos
    chroot yum-config-manager --disable rpmfusion-free > /dev/null
    chroot yum-config-manager --disable rpmfusion-free-debuginfo > /dev/null
    chroot yum-config-manager --disable rpmfusion-free-source > /dev/null
    chroot yum-config-manager --disable rpmfusion-free-updates > /dev/null
    chroot yum-config-manager --disable rpmfusion-free-updates-debuginfo > /dev/null
    chroot yum-config-manager --disable rpmfusion-free-updates-source > /dev/null
    chroot yum-config-manager --disable rpmfusion-free-updates-testing > /dev/null
    chroot yum-config-manager --disable rpmfusion-free-updates-testing-debuginfo > /dev/null
    chroot yum-config-manager --disable rpmfusion-free-updates-testing-source > /dev/null
    chroot yum-config-manager --disable rpmfusion-free-rawhide > /dev/null
    chroot yum-config-manager --disable rpmfusion-free-rawhide-debuginfo > /dev/null
    chroot yum-config-manager --disable rpmfusion-free-rawhide-source > /dev/null

    # Disable rpmfusion-nonfree repos
    chroot yum-config-manager --disable rpmfusion-nonfree > /dev/null
    chroot yum-config-manager --disable rpmfusion-nonfree-debuginfo > /dev/null
    chroot yum-config-manager --disable rpmfusion-nonfree-source > /dev/null
    chroot yum-config-manager --disable rpmfusion-nonfree-updates > /dev/null
    chroot yum-config-manager --disable rpmfusion-nonfree-updates-debuginfo > /dev/null
    chroot yum-config-manager --disable rpmfusion-nonfree-updates-source > /dev/null
    chroot yum-config-manager --disable rpmfusion-nonfree-updates-testing > /dev/null
    chroot yum-config-manager --disable rpmfusion-nonfree-updates-testing-debuginfo > /dev/null
    chroot yum-config-manager --disable rpmfusion-nonfree-updates-testing-source > /dev/null
    chroot yum-config-manager --disable rpmfusion-nonfree-rawhide > /dev/null
    chroot yum-config-manager --disable rpmfusion-nonfree-rawhide-debuginfo > /dev/null
    chroot yum-config-manager --disable rpmfusion-nonfree-rawhide-source > /dev/null
fi

#### '----------------------------------------------------------------------
info ' Cleanup'
#### '----------------------------------------------------------------------
rm -rf "${INSTALLDIR}/tmp/3rd_party_software"
trap - ERR EXIT
trap
