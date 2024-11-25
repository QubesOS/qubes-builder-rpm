#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

if [ "0${IS_LEGACY_BUILDER}" -eq 1 ]; then
    TEMPLATE_SCRIPTS_DIR="$(readlink -f .)"
    PACKAGES_DIR="${PWD}/pkgs-for-template/${DIST}"
    # shellcheck disable=SC2034
    KEYS_DIR="$SCRIPTSDIR/../keys"
    # shellcheck disable=SC2153
    INSTALL_DIR="${INSTALLDIR}"
    # shellcheck disable=SC2034
    DIST_CODENAME="$DIST"
    if [ "${DIST#fc}" != "${DIST}" ]; then
        DIST_NAME="fedora"
        DIST_VER="${DIST#fc}"
    elif [ "${DIST#centos-stream}" != "${DIST}" ]; then
        DIST_NAME="centos-stream"
        DIST_VER="${DIST#centos-stream}"
    fi
fi

# shellcheck disable=SC1091
source "${TEMPLATE_SCRIPTS_DIR}/functions.sh" >/dev/null
# shellcheck disable=SC1091
source "${TEMPLATE_SCRIPTS_DIR}/umount-kill" >/dev/null

# shellcheck disable=SC2154
info "${TEMPLATE_CONTENT_DIR}/distribution.sh imported by: ${0}"

DNF=dnf

if [ -z "${DIST_NAME}" ]; then
    error "Please provide DIST_NAME in environment."
fi

if [ -z "${DIST_VER}" ]; then
    error "Please provide DIST_VER in environment."
fi

DNF_OPTS=(-y
          "--releasever=${DIST_VER}"
          --setopt=deltarpm=False
          --setopt=zchunk=False
          --setopt=gpgcheck=1)

if [ -n "${REPO_PROXY}" ]; then
    DNF_OPTS+=("--setopt=proxy=${REPO_PROXY}")
fi


if [ "${DIST_NAME}" == "fedora" ]; then
    if [ -n "${FEDORA_MIRROR}" ]; then
        DNF_OPTS+=("--setopt=fedora.baseurl=${FEDORA_MIRROR%/}/releases/${DIST_VER}/Everything/x86_64/os/")
        DNF_OPTS+=("--setopt=updates.baseurl=${FEDORA_MIRROR%/}/updates/${DIST_VER}/Everything/x86_64/")
    fi
elif [ "${DIST_NAME}" == "centos-stream" ]; then
    DNF_OPTS+=(--nobest)
    if [ -n "${CENTOS_MIRROR}" ]; then
        DNF_OPTS+=("--setopt=base.baseurl=${CENTOS_MIRROR%/}/${DIST_VER}/os/x86_64")
        DNF_OPTS+=("--setopt=updates.baseurl=${CENTOS_MIRROR%/}/${DIST_VER}/updates/x86_64")
        DNF_OPTS+=("--setopt=extras.baseurl=${CENTOS_MIRROR%/}/${DIST_VER}/extras/x86_64")
    fi
    if [ -n "${EPEL_MIRROR}" ]; then
        DNF_OPTS+=("--setopt=epel.baseurl=${EPEL_MIRROR%/}/${DIST_VER}/x86_64")
    fi
fi

# if updates-testing repo is enabled, make it deterministic which one will get
# used in case package is in both "updates" and "updates-testing"
DNF_OPTS+=(--setopt=updates-testing.priority=80)

# ==============================================================================
# Cleanup function
# ==============================================================================
function cleanup() {
    errval=$?
    trap - ERR EXIT
    trap
    error "${1:-"${0}: Error.  Cleaning up and un-mounting any existing mounts"}"
    umount_kill "${INSTALL_DIR}" || true

    exit $errval
}

# ==============================================================================
# Create system mount points
# ==============================================================================
function prepareChroot() {
    info "Preparing environment..."
    mount -t proc proc "${INSTALL_DIR}/proc"
}

# ==============================================================================
# Enable / disable repository
# ==============================================================================
function yumConfigRepository() {
    local op=$1
    local repo=$2

    if [ "$(readlink "$INSTALL_DIR/usr/bin/dnf")" = "dnf5" ]; then
        if [ "$op" = enable ]; then
            value=1
        elif [ "$op" = disable ]; then
            value=0
        else
            echo "Invalid operation for yumConfigRepository: $op" >&2
            exit 1
        fi
        chroot_cmd dnf config-manager setopt "$repo".enabled=$value
    else
        chroot_cmd dnf config-manager --set-"${op}"d "$repo"
    fi
}

# ==============================================================================
# Enable or Disable Copr repositories
# ==============================================================================
function yumCopr() {
    mount --bind /etc/resolv.conf "${INSTALL_DIR}"/etc/resolv.conf
    local op=$1
    local repo=$2

    chroot_cmd $DNF copr "${op}" -y "$repo"
    umount "${INSTALL_DIR}"/etc/resolv.conf
}


# ==============================================================================
# Yum install package(s)
# ==============================================================================
function yumInstall() {
    declare -a files
    files=("$@")
    mount --bind /etc/resolv.conf "${INSTALL_DIR}/etc/resolv.conf"
    if [ "$DNF" = "dnf" ]; then
        mkdir -p "${INSTALL_DIR}/var/lib/dnf"
    fi
    mkdir -p "${INSTALL_DIR}/tmp/template-builder-repo"
    mount --bind "${PACKAGES_DIR}" "${INSTALL_DIR}/tmp/template-builder-repo"
    if [ -e "${INSTALL_DIR}/usr/bin/$DNF" ]; then
        cp "${TEMPLATE_CONTENT_DIR}/template-builder-repo-${DIST_NAME}.repo" "${INSTALL_DIR}/etc/yum.repos.d/"
        chroot_cmd $DNF \
            install --downloadonly "${DNF_OPTS[@]}" "${files[@]}" || exit 1
        find "${INSTALL_DIR}/var/cache/dnf" -name '*.rpm' -print0 | xargs -r0 sha256sum
        find "${INSTALL_DIR}/var/cache/libdnf5" -name '*.rpm' -print0 | xargs -r0 sha256sum
        find "${INSTALL_DIR}/var/cache/yum" -name '*.rpm' -print0 | xargs -r0 sha256sum
        # set http proxy to invalid one, to prevent any connection in case of
        # --cacheonly being buggy: better fail the build than install something
        # else than the logged one
        chroot_cmd $DNF install "${DNF_OPTS[@]}" --cacheonly --setopt=proxy=http://127.0.0.1:1/ "${files[@]}" || exit 1
        rm -f "${INSTALL_DIR}/etc/yum.repos.d/template-builder-repo-${DIST_NAME}.repo"
    else
        echo "$DNF not installed in $INSTALL_DIR, exiting!"
        exit 1
    fi
    umount "${INSTALL_DIR}/etc/resolv.conf"
    umount "${INSTALL_DIR}/tmp/template-builder-repo"
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
    declare -a files
    files=("$@")
    mount --bind /etc/resolv.conf "${INSTALL_DIR}/etc/resolv.conf"
    if [ "$DNF" = "dnf" ]; then
        mkdir -p "${INSTALL_DIR}/var/lib/dnf"
    else
        optional=--setopt=group_package_types=mandatory,default,optional
    fi
    mkdir -p "${INSTALL_DIR}/tmp/template-builder-repo"
    mount --bind "${PACKAGES_DIR}" "${INSTALL_DIR}/tmp/template-builder-repo"
    if [ -e "${INSTALL_DIR}/usr/bin/$DNF" ]; then
        chroot_cmd $DNF clean expire-cache
        chroot_cmd $DNF group install --downloadonly $optional "${DNF_OPTS[@]}" "${files[@]}" || exit 1
        find "${INSTALL_DIR}/var/cache/dnf" -name '*.rpm' -print0 | xargs -r0 sha256sum
        find "${INSTALL_DIR}/var/cache/libdnf5" -name '*.rpm' -print0 | xargs -r0 sha256sum
        find "${INSTALL_DIR}/var/cache/yum" -name '*.rpm' -print0 | xargs -r0 sha256sum
        # set http proxy to invalid one, to prevent any connection in case of
        # --cacheonly being buggy: better fail the build than install something
        # else than the logged one
        chroot_cmd $DNF install "${DNF_OPTS[@]}" --cacheonly --setopt=proxy=http://127.0.0.1:1/ "${files[@]}" || exit 1
    else
        echo "$DNF not installed in $INSTALL_DIR, exiting!"
        exit 1
    fi
    umount "${INSTALL_DIR}/etc/resolv.conf"
    umount "${INSTALL_DIR}/tmp/template-builder-repo"
}

# ==============================================================================
# Yum update
# ==============================================================================
function yumUpdate() {
    declare -a files
    files=("$@")
    mount --bind /etc/resolv.conf "${INSTALL_DIR}"/etc/resolv.conf
    if [ "$DNF" = "dnf" ]; then
        mkdir -p "${INSTALL_DIR}"/var/lib/dnf
    fi
    mkdir -p "${INSTALL_DIR}"/tmp/template-builder-repo
    mount --bind "${PACKAGES_DIR}" "${INSTALL_DIR}"/tmp/template-builder-repo
    if [ -e "${INSTALL_DIR}/usr/bin/$DNF" ]; then
        cp "${TEMPLATE_CONTENT_DIR}/template-builder-repo-${DIST_NAME}.repo" "${INSTALL_DIR}"/etc/yum.repos.d/
        chroot_cmd $DNF update --downloadonly "${DNF_OPTS[@]}" "${files[@]}" || exit 1
        find "${INSTALL_DIR}"/var/cache/dnf -name '*.rpm' -print0 | xargs -r0 sha256sum
        find "${INSTALL_DIR}"/var/cache/libdnf5 -name '*.rpm' -print0 | xargs -r0 sha256sum
        find "${INSTALL_DIR}"/var/cache/yum -name '*.rpm' -print0 | xargs -r0 sha256sum
        # set http proxy to invalid one, to prevent any connection in case of
        # --cacheonly being buggy: better fail the build than install something
        # else than the logged one
        chroot_cmd $DNF update "${DNF_OPTS[@]}" --cacheonly --setopt=proxy=http://127.0.0.1:1/ "${files[@]}" || exit 1
        rm -f "${INSTALL_DIR}/etc/yum.repos.d/template-builder-repo-${DIST_NAME}.repo"
    else
        echo "$DNF not installed in $INSTALL_DIR, exiting!"
        exit 1
    fi
    umount "${INSTALL_DIR}"/etc/resolv.conf
    umount "${INSTALL_DIR}"/tmp/template-builder-repo
}
# ==============================================================================
# Verify RPM packages
# ==============================================================================
function verifyPackages() {
    for file in "$@"; do
        result=$(rpm --root="${INSTALL_DIR}" --checksig "${file}") || {
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
            packages_list="$*"
        fi
    else
        if [ -n "$TEMPLATE_FLAVOR" ]; then
            getFileLocations packages_list "packages.list" "${DIST_NAME}_${DIST_VER}_${TEMPLATE_FLAVOR}"
            if [ -z "${packages_list}" ]; then
                getFileLocations packages_list "packages.list" "${DIST_NAME}_${TEMPLATE_FLAVOR}"
            fi
        else
            getFileLocations packages_list "packages.list" "${DIST_NAME}_${DIST_VER}"
            if [ -z "${packages_list}" ]; then
                getFileLocations packages_list "packages.list" "${DIST_NAME}"
            fi
        fi
        if [ -z "${packages_list}" ]; then
            error "Can not locate a package.list file!"
            umount_kill "${INSTALL_DIR}" || true
            exit 1
        fi
    fi

    for package_list in "${packages_list[@]}"; do
        debug "Installing extra packages from: ${package_list}"
        declare -a packages
        readarray -t packages < "${package_list}"

        # Exclude pipewire only on Qubes 4.1, this used to be part of packages_list files
        if [ "$RELEASE" == "4.1" ]; then
            packages+=( "--exclude=pipewire"
                        "--exclude=pipewire-utils"
                        "--exclude=pipewire-pulseaudio"
                        "--exclude=wireplumber" )
        fi

        info "Packages: ${packages[*]}"
        yumInstall "${packages[@]}" || return $?
    done
}
