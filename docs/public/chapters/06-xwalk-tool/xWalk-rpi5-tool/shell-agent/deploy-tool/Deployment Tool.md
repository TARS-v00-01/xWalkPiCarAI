<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [6. xWalk tool](../../../index.md) / Deployment Tool

**6. xWalk tool &middot; Module 14**

<!-- xwalk-page-header:end -->

# Deployment Tool

`deploy-tool` contains the reviewed Raspberry Pi provisioning, cross-build audit, package-installation,
service, udev, tmpfiles, and host-test assets for xWalk. Run commands from the integrated repository root.

> [!IMPORTANT]
> `/usr/bin/xwalk-picarx-control` and its Doctor command are temporarily unavailable after deletion of the former
> Platform composition. Command examples are historical until the replacement Control Service is implemented.
> Configuration and provisioning steps remain applicable. Existing systemd assets are not a replacement runtime.

## 1. Overview

Hardware operations are opt-in. Do not run `--apply` or `provision-hardware.sh` until the exact Raspberry Pi,
Robot HAT revision, wiring, power state, GPIO controller, I2C bus, SPI device, and safe actuator state have been
confirmed.

## 2. Source location

`xWalk-rpi5-tool/shell-agent/deploy-tool` -
source directory

## 3. Directory layout

```text
xWalk-rpi5-tool/shell-agent/deploy-tool/
    install-dependencies-common.sh   Shared catalog selection and APT verification for the installers
    setup-rpi.sh                     Assess, validate, preview, or apply Raspberry Pi host provisioning
    provision-hardware.sh            Records a verified Robot HAT and exact device identities in a configuration
    setup-rpi-local.sh               Builds pinned camera and Ollama runtimes below the user's ${HOME}/.local
    configure-rpi-runtime.sh         Generates build-local configuration, starts user Ollama, lists local models
    generate-rpi-runtime.sh          Generates ignored build-local Raspberry Pi configuration
    rpi-defaults.conf                Shared CMake and deployment-script Raspberry Pi defaults
    rpi-guarded-build.sh             Power- and thermal-guarded single-job native build
    aarch64-dependency-audit.sh      Validates an ARM64 sysroot and dependency architecture
    debian/conffiles                 Debian package configuration-file list
    systemd/                         xwalk, xwalk-jarvis, xwalk-searxng, and user ollama units; service defaults
    searxng/                         Optional loopback-only SearXNG compose file and JSON settings
    udev/99-xwalk-picarx.rules.in    Device-access rule template
    tmpfiles/xwalk.conf              Runtime-directory configuration
    test/                            Host-safe tests and fixtures; no physical hardware is accessed
```

The two catalog installers `install-host-dependencies.sh` and `install-rpi5-dependencies.sh` live at the
`xWalk-rpi5-tool` root and source `install-dependencies-common.sh`. The `ARM64_CROSS_BUILD` and
`HARDWARE_INDEPENDENT_READINESS` pages are kept beside this note.

## 4. Child modules

- [SearXNG Deployment](searxng/SearXNG%20Deployment.md) - optional loopback-only SearXNG search service.

## 5. Public interface

### Inspect the Raspberry Pi plan

Show the supported options:

```bash
xWalk-rpi5-tool/shell-agent/deploy-tool/setup-rpi.sh --help
```

The script defaults to Robot HAT v4, runtime user `xwalk`, `/dev/gpiochip4`,
`/dev/i2c-1`, `/dev/spidev0.0`, CSI camera, and dry-run mode. It still requires
a real supported Raspberry Pi identity and an existing runtime user. Preview
the default plan:

```bash
xWalk-rpi5-tool/shell-agent/deploy-tool/setup-rpi.sh --dry-run
```

Use `--check` to validate the target without changing it. `--apply` may install
packages, update boot configuration, install service and access-control assets,
and change the target configuration. Review the complete dry-run output before
authorization. Explicit options continue to select Robot HAT v5, alternate
devices, USB cameras, or another runtime user:

```bash
xWalk-rpi5-tool/shell-agent/deploy-tool/setup-rpi.sh --profile robot_hat_v5 --runtime-user operator --gpio-device /dev/gpiochip0 --camera usb --check
```

### Record verified hardware

The hardware provisioner validates the detected HAT identity and GPIO metadata,
then atomically updates an existing writable configuration while preserving its
owner, group, and mode. Root may preserve any existing ownership; a non-root
caller must own the configuration and retain permission to use its group:

```bash
xWalk-rpi5-tool/shell-agent/deploy-tool/provision-hardware.sh --profile robot_hat_v5 --config /var/lib/xwalk/picar-x.conf --gpio-device /dev/gpiochip0 --i2c-device /dev/i2c-1 --spi-device /dev/spidev0.0
```

After provisioning, run `--diagnose --no-hardware`, then the bounded `doctor`
preflight before any separately authorized calibration or actuator test. Doctor
pulses only the configured MCU reset GPIO and reports that activation explicitly.
For an explicit v4 profile, Doctor verifies the recorded GPIO identity and
successful MCU firmware and battery transactions without claiming that an
absent v5 UUID alone identifies v4.

### Install the validated user-local runtime

Preview the pinned Raspberry Pi 5 camera and Ollama workflow without changing
the host:

```bash
xWalk-rpi5-tool/shell-agent/deploy-tool/setup-rpi-local.sh --dry-run
```

On the target Pi, apply it as the non-root runtime user. It builds the official
Raspberry Pi libcamera fork and rpicam-apps into `${HOME}/.local` by default, installs an
Ollama user service and `llama3.2:3b`, adds the runtime user to `video` and
`render`, and generates ignored files below `build-rpi`. It never installs an
xWalk package or camera build under `/usr` or `/usr/local`:

```bash
xWalk-rpi5-tool/shell-agent/deploy-tool/setup-rpi-local.sh --apply
```

Use `--local-prefix /absolute/prefix` when the camera stack is installed outside
`${HOME}/.local`. The Raspberry Pi CMake configure records the same prefix in
`XWALK_RPI_LOCAL_PREFIX` and validates the CSI plugin and its matching
libraries. CMake compiles the required GStreamer plugin directory into the
Raspberry Pi executable. The plugin's validated runpath selects the matching
libraries, so users do not export camera environment variables manually.

Log out and back in or reboot after group changes. Camera discovery may be checked with
`${HOME}/.local/bin/rpicam-still --list-cameras`. No Controller diagnostic executable is currently provided.

To regenerate the runtime configuration later and ensure the existing Ollama
user service is enabled and running, use the following command. This target-side
check records one second of microphone input to `/dev/null`, verifies the
configured PulseAudio mixer element, and checks the Vosk and Piper assets
without moving the vehicle:

```bash
xWalk-rpi5-tool/shell-agent/deploy-tool/configure-rpi-runtime.sh
```

The tracked service binds Ollama only to `127.0.0.1:11434`, restarts after an
unexpected failure with a three-second delay, and reuses an installed
`llama3.2:3b` model. Inspect it without exposing the service publicly:

```bash
systemctl --user daemon-reload
systemctl --user enable --now ollama
systemctl --user status ollama --no-pager
journalctl --user -u ollama --no-pager
curl http://127.0.0.1:11434/api/tags
ollama list
```

For a service-managed Jarvis session, stop any separately configured system
controller instance, then enable the user service. Its `Requires=` and `After=`
ordering starts the same user manager's Ollama unit first:

```bash
systemctl --user enable --now xwalk-jarvis
systemctl --user status xwalk-jarvis --no-pager
journalctl --user -u xwalk-jarvis --no-pager
systemctl --user stop xwalk-jarvis
```

### Audit an ARM64 sysroot

Point the audit at an explicit absolute sysroot. It validates headers,
pkg-config metadata, library search paths, and AArch64 library identities
without operating hardware:

```bash
XWALK_AARCH64_SYSROOT=/absolute/aarch64/sysroot xWalk-rpi5-tool/shell-agent/deploy-tool/aarch64-dependency-audit.sh
```

See [ARM64_CROSS_BUILD](ARM64_CROSS_BUILD.md) and
[HARDWARE_INDEPENDENT_READINESS](HARDWARE_INDEPENDENT_READINESS.md) for the
complete cross-build and readiness requirements.

### Guard native builds against power and thermal warnings

After correcting a power-supply or cooling fault, `rpi-guarded-build.sh BUILD_DIRECTORY` runs one CMake
build with one compiler job. It refuses current or historical firmware voltage/throttling flags and
a starting temperature of 65°C or higher. A private per-user lock prevents overlapping guarded builds,
even across different build directories. The compiler runs at nice priority 10. Every second, the guard
checks telemetry, pauses its own process group at 65°C and resumes only at 55°C or lower. It aborts at
75°C, on any power/throttling flag or unreadable telemetry, or after 120 seconds without cooling recovery.
Cleanup resumes a paused group only to deliver termination, then reaps its processes. Compiler failures
propagate. It does not change firmware limits, disable low-voltage detection, or stop other services.

```bash
xWalk-rpi5-tool/shell-agent/deploy-tool/rpi-guarded-build.sh --check
xWalk-rpi5-tool/shell-agent/deploy-tool/rpi-guarded-build.sh xWalk-rpi5-node/build-rpi5-native
python3 xWalk-rpi5-tool/shell-agent/deploy-tool/test/rpi-guarded-build-test.py
```

This is a best-effort build mitigation, not a power-supply repair or a guarantee against a sudden brownout.
A clean idle check does not establish stability under load. Correct the supply/cable/HAT power path before
resuming camera, accelerator, or motor tests; reboot after correction to clear historical firmware flags.
Do not run concurrent independent builds alongside this wrapper. The host test mocks firmware and CMake;
it neither contacts a Pi nor accesses hardware. Runtime applications remain native C++.

## 6. Build

### Root setup commands

For native dependencies only, run this from the integrated repository root:

```bash
sudo ./setup.sh
```

For complete host setup, including source submodules and CMake configuration:

```bash
./install.sh --target host
```

For Raspberry Pi 5 with a physically identified Robot HAT v4:

```bash
./install.sh --target rpi --profile robot_hat_v4 --build
```

Select `robot_hat_v5` for matching v5 hardware. The root `install.sh` installs immediately and invokes sudo for
system changes; run it as your normal user. See the
[xWalkPiCarAI](../../../../01-xwalk-workspace/xWalkPiCarAI.md#6-prepare-a-fresh-linux-machine) for boot backups, overlay limitations, and
runtime prerequisites. The lower-level tools below retain their own command-line options.

### Install native build dependencies

The root `setup.sh` prepares the APT packages for the full native C++ workspace:
HAL, Driver, Controller, IW generation, trace, IoT MQTT, host tests, and quality tools.
It uses the shared `apt-packages.txt` catalog. Run from the integrated repository root:

```bash
sudo ./setup.sh --target host
```

On the Raspberry Pi 5 itself, with a 64-bit OS:

```bash
sudo ./setup.sh --target rpi
```

Supported systems are Ubuntu 24.04 or newer and Debian/Raspberry Pi OS 12 or newer.
Bash and the OS APT tools must already exist. Run as your normal account; the scripts
use `sudo` for package installation when needed. Repeated runs install only missing
packages. A failed package operation stops setup, and a final check requires CMake 3.25+.

Both commands install immediately with sudo. The Pi target includes CSI
camera packages (`rpicam-apps` and GStreamer) and requires a locally detected Raspberry
Pi 5 with ARM64 userspace. The host installer prepares native host dependencies; it
does not create an ARM64 cross-compilation sysroot.

The Pi installer accepts an existing `rpicam-still` from the invoking user's `~/.local/bin`
or `PATH` in place of the `rpicam-apps` APT package. It checks executable availability and
successful, recognizable `--version` output with a ten-second timeout, without camera discovery
or capture. Under sudo, it resolves the invoking account's home and runs the version probe as
that user. Prefer running the installer directly as your normal account.

When this alternative is validated, only `rpicam-apps` is omitted from APT installation and
dpkg verification. All other catalog dependencies, including the CSI GStreamer tools, base plugins,
and development packages, remain required. No minimum camera version is imposed by this check.
If no existing executable validates, the installer refreshes APT metadata and installs `rpicam-apps`
when a candidate is available.

Ubuntu 24.04 Noble sources may not provide `rpicam-apps`. If neither alternative is available, setup fails with a
pointer to `setup-rpi-local.sh`, the
explicit user-local camera workflow. That workflow also
installs Ollama, its user service, and the `llama3.2:3b` model; review its documented plan before choosing to
apply it. The dependency installer never runs it automatically, builds camera sources, installs Ollama, changes
CSI to USB, or adds APT repositories.

Version reporting confirms executable startup, not camera readiness. The runtime still needs matching
libcamera libraries, the correct GStreamer `libcamerasrc` plugin and search paths, device permissions,
and working sensor discovery/capture. Validate those separately on the safely connected Pi using the
user-local setup documentation. A working `rpicam-still` alone does not validate the GStreamer backend.

The configured APT sources must provide all remaining selected packages. For example,
`libttspico-utils` may require Debian's non-free component. The installer reports APT failures;
it does not rewrite package sources or silently skip unavailable dependencies.

After host setup, build and test from the repository root:

```bash
cmake -S xWalk-rpi5-hw --preset host-debug
cmake --build build-host/cmake --parallel 4
ctest --test-dir build-host/cmake --output-on-failure
cmake -S xWalk-rpi5-node/xWalkIoT --preset host-debug
cmake --build xWalk-rpi5-node/build-host --parallel 4
ctest --test-dir xWalk-rpi5-node/build-host --output-on-failure
```

For the native Pi IoT executable:

```bash
cmake -S xWalk-rpi5-node/xWalkIoT --preset rpi5-native
cmake --build xWalk-rpi5-node/build-rpi5-native --parallel 4
./xWalk-rpi5-node/build-rpi5-native/xwalk --help
```

Successful installation confirms OS package availability. Runtime preparation also requires initialized private
component checkouts, HiveMQ credentials, and the configured Vosk libraries/models or Ollama provider/models for
voice features. Use the [xWalkIoT](../../../../05-xwalk-node/xWalk-rpi5-node/xWalkIoT/xWalkIoT.md) note for broker configuration
and the provisioning sections below for hardware backends. These scripts do not modify boot settings, provision a
HAT, start xWalk or a broker, create credentials, or run hardware tests. Optional wiki, Jira, and Gerrit server
environments retain their separate documented setup flows.

## 7. Configuration

### Generated runtime defaults and deployment overrides

`generate-rpi-runtime.sh` refreshes only the marked `runtime/generated` tree. It creates `runtime/picar-x.conf`
only when absent, with an include of `generated/picar-x.conf`. Put deployment overrides after that include.
Existing primary files, legacy `picar-x.d` fragments, calibration, and executables remain untouched, including
with `--initialize-only`. Legacy layouts require the reviewed manual migration in the
[xWalkController](../../../../02-xwalk-hardware/xWalk-rpi5-hw/xWalkController/xWalkController.md) note to adopt refreshed defaults.
Native Node selects this same primary file.

Generation retains the schema's packaged Vosk library/model paths. Override them in the primary file for a
different installation. The optional configure/provision workflow remains opt-in and performs hardware/service
operations; ordinary CMake configure invokes only generation. `configure-rpi-runtime.sh` reads the layered
primary file when validating its selected settings, including deployment overrides.

### Native launcher and Piper selection

`generate-rpi-runtime.sh` seeds the existing Node `runtime/run-xwalk` template once and refreshes only its
`runtime/generated/launcher.env` defaults. Existing launchers, the primary configuration, calibration,
and `runtime/environment` stay operator-owned. The launcher preserves library/plugin entries and prepends the
configured local-prefix AArch64 directories, rejecting missing CSI directories before execution. HOST CMake
configuration does not generate or activate this native environment.

Select a provisioned voice with `--piper-model /absolute/voice.onnx`; the same selection is generated for shared
voice and feature configuration. The default deployment profile names `en_GB-alan-medium.onnx` under
`/usr/share/xwalk/models/piper`. That is a provisioning choice, not a claim that Alan is installed everywhere.
The package dependency installer does not provision voice model assets. Supply the
chosen model and its companion JSON using the installation's existing asset provisioning procedure, then run:

```bash
xWalk-rpi5-tool/shell-agent/deploy-tool/configure-rpi-runtime.sh --build-directory /path/to/native-build --runtime-user operator --local-prefix /path/to/operator/.local --piper-model /path/to/voice.onnx --validate-model-only
```

This reuses the existing effective-configuration reader and model validation before any device/service step.
An explicit runtime override wins over generated selection. Missing or invalid assets are diagnosed without
choosing another voice. `--generate-only` needs no model assets. The full configure command still performs its
existing target-only device/service checks and must not be run on a hardware-free host.

`--native-binary` and `--configuration-file` on both runtime tools support CMake's retained runtime layout;
defaults are the selected build directory's `xwalk` and `runtime/picar-x.conf`. CMake passes its exact
binary/config paths. Use `XWALK_NATIVE_BINARY`, `XWALK_LOCAL_PREFIX`, and `XWALK_PICARX_CONFIG_FILE` or
`runtime/environment` for explicit operator overrides. A custom launcher is never automatically rewritten.

For the retained Node CMake layout, the runtime parent is `xWalk-rpi5-node`, the binary is
`xWalk-rpi5-node/build-rpi5-native/xwalk`, and the configuration is `xWalk-rpi5-node/runtime/picar-x.conf`.
Pass those absolute paths explicitly when running the configure tool against that layout; model validation
then reads the same selected configuration as the launcher. For a deployment with `xwalk` directly under the
selected build directory, the default paths already match.

## 8. Testing

These checks use fixtures or temporary directories and do not actuate hardware:

```bash
bash xWalk-rpi5-tool/shell-agent/deploy-tool/test/setup-rpi-test.sh
bash xWalk-rpi5-tool/shell-agent/deploy-tool/test/aarch64-dependency-audit-test.sh
bash xWalk-rpi5-tool/shell-agent/deploy-tool/test/environment-loader-test.sh
bash xWalk-rpi5-tool/shell-agent/deploy-tool/test/language-model-config-test.sh
bash xWalk-rpi5-tool/shell-agent/deploy-tool/test/rpi-local-runtime-test.sh
python3 xWalk-rpi5-tool/shell-agent/deploy-tool/test/dependency-installer-test.py
```

Run ShellCheck over the deployment scripts before review:

```bash
xWalk-rpi5-tool/shell-agent/quality-tool/run-host-shellcheck.sh
```

Run the installers' host-safe tests with package operations mocked:

```bash
python3 xWalk-rpi5-tool/shell-agent/deploy-tool/test/install-dependencies-test.py
```

`rpi-guarded-build-test.py`, `rpi-runtime-contract-test.py`, and `rpi-provision-cmake-test.sh` in the same
`test` directory cover the guarded build, runtime contract, and CMake provisioning wiring with mocked
dependencies. Hardware tests are opt-in; discover them with `ctest -N -L hardware` and run them only with
explicit approval and a confirmed safe Raspberry Pi and Robot HAT setup.

## 9. Dependencies

- Bash, APT, and `sudo` for package installation; CMake 3.25 or newer for the native build.
- `gpiodetect` for hardware provisioning; libcamera, `rpicam-apps`, and GStreamer for the CSI camera path.
- Ollama, Vosk, and Piper assets for voice and language features on the target.

## 10. Safety and constraints

- `setup-rpi.sh --apply`, `setup-rpi-local.sh --apply`, `provision-hardware.sh`, and
  `configure-rpi-runtime.sh` change the target and must not run on a hardware-free host or in CI.
- Services bind Ollama and SearXNG to loopback only.
- Preserve operator-owned configuration, calibration, launchers, and `runtime/environment`; the generators
  never overwrite them.

## 11. Related notes

- Shell Agent
- [Deployment Guide](../../../../08-xwalk-guides/Doc/note/Deployment%20Guide.md)
- [Raspberry Pi Setup Script Guide](../../../../08-xwalk-guides/Doc/note/Raspberry%20Pi%20Setup%20Script%20Guide.md)
- [Hardware Provisioning Script Guide](../../../../08-xwalk-guides/Doc/note/Hardware%20Provisioning%20Script%20Guide.md)

---

[Previous page](../../py-agent/dev-tool/styler-tool/Styler%20Tool.md) · [Chapter index](../../../index.md) · [Next page](searxng/SearXNG%20Deployment.md)
