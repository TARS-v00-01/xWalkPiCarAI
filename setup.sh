#!/usr/bin/env bash
# Install native host or Raspberry Pi dependencies from the shared package catalog.
# Author: Joxy John
set -Eeuo pipefail
trap 'printf "Dependency installation failed at line %s. Resolve the error above and rerun.\n" "$LINENO" >&2' ERR

usage() {
    printf 'Usage: sudo ./setup.sh [--target auto|host|rpi]\n'
    printf 'Installs build, generator, test and quality packages, one at a time.\n'
    printf 'The default detects Raspberry Pi locally and includes its CSI camera packages.\n'
}
target=auto
while (( $# )); do
    case "$1" in
        --target)
            if (( $# < 2 )); then usage >&2; exit 2; fi
            target="$2"
            shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done
if [[ ! "$target" =~ ^(auto|host|rpi)$ ]]; then usage >&2; exit 2; fi
if (( EUID != 0 )); then
    printf 'Run this script with sudo: sudo ./setup.sh\n' >&2
    exit 2
fi

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
common="$root/xWalk-rpi5-tool/shell-agent/deploy-tool/install-dependencies-common.sh"
if [[ ! -r "$common" ]]; then
    printf 'Initialize the xWalk-rpi5-tool submodule before running setup.sh.\n' >&2
    exit 2
fi
if [[ "$target" == auto ]]; then
    target=host
    if [[ -r /proc/device-tree/model ]]; then
        model="$(tr -d '\000' < /proc/device-tree/model)"
        [[ "$model" != *'Raspberry Pi'* ]] || target=rpi
    fi
fi
# Keep package selection, OS validation and existing-camera checks in one implementation.
# shellcheck source-path=SCRIPTDIR
# shellcheck source=xWalk-rpi5-tool/shell-agent/deploy-tool/install-dependencies-common.sh
. "$common"
XWALK_DEPENDENCY_INSTALL_ONE_BY_ONE=true xwalk_install_dependencies "$target"
