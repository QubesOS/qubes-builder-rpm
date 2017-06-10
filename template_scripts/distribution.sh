#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

source ./functions.sh >/dev/null
source ./umount_kill.sh >/dev/null

output "${bold}${under}INFO: ${SCRIPTSDIR}/distribution.sh imported by: ${0}${reset}"

if [ -n "${REPO_PROXY}" ]; then
    YUM_OPTS="$YUM_OPTS --setopt=proxy=${REPO_PROXY}"
fi

if [ "${DIST/fc/}" -ge 22 ]; then
    YUM=dnf
else
    YUM=yum
fi

# ==============================================================================
# Cleanup function
# ==============================================================================
function cleanup() {
    errval=$?
    trap - ERR EXIT
    trap
    error "${1:-"${0}: Error.  Cleaning up and un-mounting any existing mounts"}"
    umount_kill "${INSTALLDIR}" || true

    exit $errval
}

# ==============================================================================
# Create system mount points
# ==============================================================================
function prepareChroot() {
    info "--> Preparing environment..."
    mount -t proc proc "${INSTALLDIR}/proc"
}

# Enable / disable repository
function yumConfigRepository() {
    local op=$1
    local repo=$2

    if [ "$YUM" = "dnf" ]; then
        chroot_cmd dnf config-manager --set-${op}d $repo
    else
        chroot_cmd yum-config-manager --${op} $repo
    fi
}

# ==============================================================================
# Yum install package(s)
# ==============================================================================
function yumInstall() {
    files="$@"
    mount --bind /etc/resolv.conf ${INSTALLDIR}/etc/resolv.conf
    if [ "$YUM" = "dnf" ]; then
        mkdir -p ${INSTALLDIR}/var/lib/dnf
    fi
    mkdir -p ${INSTALLDIR}/tmp/template-builder-repo
    mount --bind pkgs-for-template ${INSTALLDIR}/tmp/template-builder-repo
    if [ -e "${INSTALLDIR}/usr/bin/$YUM" ]; then
        cp ${SCRIPTSDIR}/template-builder-repo.repo ${INSTALLDIR}/etc/yum.repos.d/
        chroot_cmd $YUM --downloadonly \
            install ${YUM_OPTS} -y ${files[@]} || exit 1
        find ${INSTALLDIR}/var/cache/dnf -name '*.rpm' -print0 | xargs -r0 sha256sum
        find ${INSTALLDIR}/var/cache/yum -name '*.rpm' -print0 | xargs -r0 sha256sum
        # set http proxy to invalid one, to prevent any connection in case of
        # --cacheonly being buggy: better fail the build than install something
        # else than the logged one
        chroot_cmd $YUM install ${YUM_OPTS} -y \
            --cacheonly --setopt=proxy=http://127.0.0.1:1/ ${files[@]} || exit 1
        rm -f ${INSTALLDIR}/etc/yum.repos.d/template-builder-repo.repo
    else
        echo "$YUM not installed in $INSTALLDIR, exiting!"
        exit 1
    fi
    umount ${INSTALLDIR}/etc/resolv.conf
    umount ${INSTALLDIR}/tmp/template-builder-repo
}

# ==============================================================================
# Yum install group(s)
# ==============================================================================
function yumGroupInstall() {
    local optional=
    if [ "$1" = "with-optional" ]; then
        optional=with-optional
        shift
    fi
    files="$@"
    mount --bind /etc/resolv.conf ${INSTALLDIR}/etc/resolv.conf
    if [ "$YUM" = "dnf" ]; then
        mkdir -p ${INSTALLDIR}/var/lib/dnf
    else
        optional=--setopt=group_package_types=mandatory,default,optional
    fi
    mkdir -p ${INSTALLDIR}/tmp/template-builder-repo
    mount --bind pkgs-for-template ${INSTALLDIR}/tmp/template-builder-repo
    if [ -e "${INSTALLDIR}/usr/bin/$YUM" ]; then
        chroot_cmd $YUM clean expire-cache
        chroot_cmd $YUM --downloadonly \
            group install $optional ${YUM_OPTS} -y ${files[@]} || exit 1
        find ${INSTALLDIR}/var/cache/dnf -name '*.rpm' -print0 | xargs -r0 sha256sum
        find ${INSTALLDIR}/var/cache/yum -name '*.rpm' -print0 | xargs -r0 sha256sum
        # set http proxy to invalid one, to prevent any connection in case of
        # --cacheonly being buggy: better fail the build than install something
        # else than the logged one
        chroot_cmd $YUM group install $optional ${YUM_OPTS} -y \
            --cacheonly --setopt=proxy=http://127.0.0.1:1/ ${files[@]} || exit 1
    else
        echo "$YUM not installed in $INSTALLDIR, exiting!"
        exit 1
    fi
    umount ${INSTALLDIR}/etc/resolv.conf
    umount ${INSTALLDIR}/tmp/template-builder-repo
}

# ==============================================================================
# Yum update
# ==============================================================================
function yumUpdate() {
    files="$@"
    mount --bind /etc/resolv.conf ${INSTALLDIR}/etc/resolv.conf
    if [ "$YUM" = "dnf" ]; then
        mkdir -p ${INSTALLDIR}/var/lib/dnf
    fi
    mkdir -p ${INSTALLDIR}/tmp/template-builder-repo
    mount --bind pkgs-for-template ${INSTALLDIR}/tmp/template-builder-repo
    if [ -e "${INSTALLDIR}/usr/bin/$YUM" ]; then
        cp ${SCRIPTSDIR}/template-builder-repo.repo ${INSTALLDIR}/etc/yum.repos.d/
        chroot_cmd $YUM --downloadonly \
            update ${YUM_OPTS} -y ${files[@]} || exit 1
        find ${INSTALLDIR}/var/cache/dnf -name '*.rpm' -print0 | xargs -r0 sha256sum
        find ${INSTALLDIR}/var/cache/yum -name '*.rpm' -print0 | xargs -r0 sha256sum
        # set http proxy to invalid one, to prevent any connection in case of
        # --cacheonly being buggy: better fail the build than install something
        # else than the logged one
        chroot_cmd $YUM update ${YUM_OPTS} -y \
            --cacheonly --setopt=proxy=http://127.0.0.1:1/ ${files[@]} || exit 1
        rm -f ${INSTALLDIR}/etc/yum.repos.d/template-builder-repo.repo
    else
        echo "$YUM not installed in $INSTALLDIR, exiting!"
        exit 1
    fi
    umount ${INSTALLDIR}/etc/resolv.conf
    umount ${INSTALLDIR}/tmp/template-builder-repo
}
# ==============================================================================
# Verify RPM packages
# ==============================================================================
function verifyPackages() {
    for file in $@; do
        result=$(rpm --root="${INSTALLDIR}" --checksig "${file}") || {
            echo "Filename: ${file} failed verification.  Exiting!"
            exit 1
        }
        result_status="${result##*:}"
        echo "${result_status}" | grep -q 'PGP' && {
            echo "Filename: ${file} contains an invalid PGP signature.  Exiting!"
            exit 1
        }
        echo "${result_status}" | grep -q 'pgp' || {
            echo "Filename: ${file} is not signed.  Exiting!"
            exit 1
        }
    done
    sha256sum "$@"

    return 0
}

# ==============================================================================
# Install extra packages in script_${DIST}/packages.list file
# -and / or- TEMPLATE_FLAVOR directories
# ==============================================================================
function installPackages() {
    if [ -n "${1}" ]; then
        # Locate packages within sub dirs
        if [ ${#@} == "1" ]; then
            getFileLocations packages_list "${1}" ""
        else
            packages_list="$@"
        fi
    else
        # TODO:  Add into template flavor handler the ability to 
        #        detect flavors that will not append recursive values
        # Only file 'minimal' package lists
        if [ "$TEMPLATE_FLAVOR" == "minimal" ]; then
            getFileLocations packages_list "packages.list" "${DIST}_minimal"
        else
            getFileLocations packages_list "packages.list" "${DIST}"
        fi
        if [ -z "${packages_list}" ]; then
            error "Can not locate a package.list file!"
            umount_all || true
            exit 1
        fi
    fi

    for package_list in ${packages_list[@]}; do
        debug "Installing extra packages from: ${package_list}"
        declare -a packages
        readarray -t packages < "${package_list}"

        info "Packages: "${packages[@]}""
        yumInstall "${packages[@]}" || return $?
    done
}
