#!/usr/bin/env bash
# Prepare a native xWalk build from a fresh Debian/Ubuntu/Raspberry Pi OS installation.
# Author: Joxy John
set -Eeuo pipefail
trap 'printf "Installation stopped at line %s. Resolve the error above and re-run.\n" "$LINENO" >&2' ERR

usage() {
    cat <<'HELP'
Usage: ./install.sh [--target auto|host|rpi]
                    [--profile robot_hat_v4|robot_hat_v5] [--runtime-user USER]
                    [--gpio-device /dev/gpiochipN] [--build] [--jobs N]
                    [--skip-submodules]

Installs dependencies and configures CMake when run. --apply is an optional alias.
Supports Ubuntu 24.04+ and Debian/Raspberry Pi OS 12+; Pi requires Pi 5 ARM64.
Run as your normal build user; sudo is used only for system changes.
On Pi, explicitly select the physically identified HAT profile. CSI is used.
--build additionally compiles the product; --jobs defaults to 2 to limit memory.
--skip-submodules preserves an intentionally modified component checkout.
No reboot, application startup, or hardware tests are performed.
HELP
}
fail() { printf 'install.sh: %s\n' "$*" >&2; exit 2; }
run() {
    printf ' +'; printf ' %q' "$@"; printf '\n'
    "$@"
}
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
target=auto
profile=''
runtime_user="$(id -un)"
gpio_device=''
build=false
jobs=2
submodules=true
while (( $# )); do
    case "$1" in
        --apply) shift ;;
        --build) build=true; shift ;;
        --skip-submodules) submodules=false; shift ;;
        --target|--profile|--runtime-user|--gpio-device|--jobs)
            if (( $# < 2 )); then fail "Missing value for $1"; fi
            [[ -n "$2" && "$2" != --* ]] || fail "Missing value for $1"
            case "$1" in
                --target) target="$2" ;;
                --profile) profile="$2" ;;
                --runtime-user) runtime_user="$2" ;;
                --gpio-device) gpio_device="$2" ;;
                --jobs) jobs="$2" ;;
            esac
            shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) fail "Unknown option: $1 (see --help)" ;;
    esac
done
[[ "$target" =~ ^(auto|host|rpi)$ ]] || fail 'Invalid --target'
[[ -z "$profile" || "$profile" =~ ^robot_hat_v[45]$ ]] || fail 'Invalid --profile'
[[ "$jobs" =~ ^[1-9][0-9]*$ ]] || fail '--jobs must be a positive integer'
[[ -z "$gpio_device" || "$gpio_device" =~ ^/dev/gpiochip[0-9]+$ ]] || fail 'Invalid --gpio-device'
[[ "$(uname -s)" == Linux ]] || fail 'Linux is required'
[[ -r /etc/os-release ]] || fail 'Missing /etc/os-release'
# shellcheck disable=SC1091
. /etc/os-release
if ! command -v apt-get >/dev/null || ! command -v dpkg >/dev/null; then
    fail 'APT and dpkg are required'
fi
case "${ID:-}" in
    ubuntu) minimum=24.04 ;;
    debian|raspbian) minimum=12 ;;
    *) fail 'Use Ubuntu 24.04+ or Debian/Raspberry Pi OS 12+' ;;
esac
dpkg --compare-versions "${VERSION_ID:-0}" ge "$minimum" || fail 'Operating system is too old'
model=''
if [[ -r /proc/device-tree/model ]]; then model="$(tr -d '\000' < /proc/device-tree/model)"; fi
if [[ "$target" == auto ]]; then
    target=host
    [[ "$model" != *'Raspberry Pi'* ]] || target=rpi
fi
if [[ "$target" == rpi ]]; then
    [[ -n "$profile" ]] || fail 'Select the attached HAT with --profile robot_hat_v4 or robot_hat_v5'
    [[ "$model" == *'Raspberry Pi 5'* && "$(dpkg --print-architecture)" == arm64 ]] ||
        fail 'Pi installation requires a locally connected Raspberry Pi 5 with a 64-bit OS'
    id "$runtime_user" >/dev/null 2>&1 || fail 'The runtime user must already exist'
elif [[ -n "$profile" || -n "$gpio_device" ]]; then
    fail '--profile and --gpio-device require --target rpi'
fi
if [[ "$EUID" == 0 ]]; then
    fail 'Run as your normal build user, without sudo; the script elevates system operations itself'
fi
printf 'xWalk installation: target=%s root=%s\n' "$target" "$root"
command -v sudo >/dev/null || fail 'Install sudo and grant your build user sudo access first'
sudo -v
if ! command -v git >/dev/null || ! command -v python3 >/dev/null; then
    run sudo apt-get update
    run sudo apt-get install --yes git ca-certificates python3
fi
if [[ "$submodules" == true && -f "$root/.gitmodules" ]]; then
    status="$(git -C "$root" submodule status --recursive)"
    if [[ "$status" =~ (^|$'\n')[+U] ]]; then
        fail 'Submodule revisions differ from their pins; preserve them with --skip-submodules'
    fi
    run git -C "$root" submodule sync --recursive
    run git -C "$root" submodule update --init --recursive
fi
tool="$root/xWalk-rpi5-tool"
deploy="$tool/shell-agent/deploy-tool"
[[ -r "$deploy/rpi-defaults.conf" ]] || fail 'Missing tool submodule; initialize the private submodules'
if [[ "$target" == host ]]; then
    run sudo bash "$root/setup.sh" --target host
    preset=host-debug
    binary="$root/build-host/cmake"
    configure=()
else
    # Defaults stay owned by the existing deployment component.
    if [[ -r "$deploy/rpi-defaults.conf" ]]; then
        # shellcheck disable=SC1091
        . "$deploy/rpi-defaults.conf"
        gpio_device="${gpio_device:-$XWALK_DEFAULT_RPI_GPIO_DEVICE}"
    else
        gpio_device="${gpio_device:-/dev/gpiochip4}"
    fi
    templates="$root/xWalk-rpi5-hw/xWalkController/xWalkConfig"
    setup=(bash "$deploy/setup-rpi.sh" --profile "$profile" --runtime-user "$runtime_user"
        --gpio-device "$gpio_device" --template-config "$templates/picar-x.conf"
        --template-fragments "$templates/picar-x.d")
    # Validate board identity, boot conflicts and source configuration before package/boot changes.
    if ! preflight="$("${setup[@]}" --dry-run 2>&1)"; then
        printf '%s\n' "$preflight" >&2
        fail 'Raspberry Pi preflight failed'
    fi
    run sudo bash "$root/setup.sh" --target rpi
    printf 'Boot plan: back up config.txt; enable I2C/SPI in [all]; load i2c-dev at boot.\n'
    if [[ "$profile" == robot_hat_v5 ]]; then
        printf 'Install checksum-verified sunfounder-robothat5.dtbo using the repository boot installer.\n'
    else
        printf 'Robot HAT v4: no matching bundled overlay; retain the installed audio overlay.\n'
    fi
    python3 - "$root" "$profile" <<'PY_BOOT'
import pathlib
import runpy
import subprocess
import sys

root = pathlib.Path(sys.argv[1])
profile = sys.argv[2]
installer = root / 'xWalk-rpi5-tool/py-agent/dev-tool/xHal_Rpi5CarDependencyInstaller'
api = runpy.run_path(str(installer))
if profile == 'robot_hat_v5':
    rows = api['configure_raspberry_pi_boot']('install', profile, api['select_platform']('auto'), root)
    api['print_table'](rows)
    if not all(row.installed for row in rows):
        raise SystemExit('Robot HAT boot configuration failed')
else:
    config, overlays = api['locate_boot_configuration']()
    if config is None:
        raise SystemExit('No Raspberry Pi boot config.txt and overlays directory found')
    text = config.read_text()
    active = api['active_boot_lines'](text)
    if any(api['has_setting'](active, key, 'off') for key in ('i2c_arm', 'spi')):
        raise SystemExit('Resolve disabled I2C/SPI settings before installation')
    if any(api['has_overlay'](active, name) for name in ('sunfounder-robothat5', 'sunfounder-servohat+')):
        raise SystemExit('Existing HAT overlay conflicts with the selected v4 profile')
    global_lines = api['global_boot_lines'](text)
    additions = [f'dtparam={key}=on' for key in ('i2c_arm', 'spi')
                 if not api['has_setting'](global_lines, key, 'on')]
    if additions:
        backup = config.with_name(config.name + '.xwalk-backup')
        if not backup.exists():
            subprocess.run(['sudo', 'cp', '--archive', '--', str(config), str(backup)], check=True)
        subprocess.run(['sudo', 'tee', '--append', str(config)], check=True,
                       input='\n[all]\n# xWalk interfaces\n' + '\n'.join(additions) + '\n', text=True)
subprocess.run(['sudo', 'install', '-d', '-m', '0755', '/etc/modules-load.d'], check=True)
subprocess.run(['sudo', 'tee', '/etc/modules-load.d/xwalk-i2c.conf'],
               check=True, input='i2c-dev\n', text=True)
PY_BOOT
    run "${setup[@]}" --apply
    preset=rpi-release
    binary="$root/build-rpi/cmake"
    configure=(-DXWALK_RPI_PROFILE="$profile" -DXWALK_RPI_RUNTIME_USER="$runtime_user"
        -DXWALK_RPI_GPIO_DEVICE="$gpio_device" -DXWALK_PICARX_CONFIG_FILE=/var/lib/xwalk/picar-x.conf)
fi
run cmake -S "$root/xWalk-rpi5-hw" --preset "$preset" "${configure[@]}"
if [[ "$build" == true ]]; then run cmake --build "$binary" --parallel "$jobs"; fi
printf '\nBuild configured. Build command: cmake --build %q --parallel %q\n' "$binary" "$jobs"
if [[ "$target" == rpi ]]; then
    printf 'Review boot changes and reboot manually to activate interfaces and group membership.\n'
fi
