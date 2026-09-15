# xWalk Raspberry Pi 5 PiCar-X

xWalk is a C++17 control and automation workspace for the SunFounder PiCar-X on Raspberry Pi 5. The repository
contains the complete product integration, host-safe simulation and tests, deployment configuration, documentation,
and development tooling.

Normal host builds use simulated or software backends and do not actuate physical hardware.

## Clone from GitHub

The integration repository uses explicit GitHub HTTPS URLs for all ten submodules. The component repositories
are private: your GitHub account must have read access to each one, even though the integration repository is public.
Authenticate Git before cloning. With GitHub CLI:

```bash
gh auth login --hostname github.com --git-protocol https
gh auth setup-git
git clone --recurse-submodules https://github.com/TARS-v00-01/xWalkPiCarAI.git
```

For an existing clone, after fetching and checking out the integration revision containing these URLs, replace
old local submodule URL overrides and initialize the exact pinned component revisions:

```bash
git submodule sync --recursive
git submodule update --init --recursive
git submodule status --recursive
```

Each status entry should begin with a space. A leading `-` means uninitialized; `+` means the checkout differs
from the pinned revision. Do not use `--remote` for a reproducible integration checkout.

Cloning requires no Gerrit connection or Git environment script. Contributors source
`xWalk-rpi5-tool/shell-agent/env-tool/git.sh` separately to
configure Gerrit review uploads. GitHub component remotes support fetching; source changes still go through Gerrit.
The managed GitHub Actions checkout continues to use its runner's Gerrit credentials independently of developer clones.

## Repository layout

```text
MyPiCarX/
├── xWalk-rpi5-hw/             Integrated Raspberry Pi 5 product
│   ├── CMakeLists.txt         Product build entry point
│   ├── CMakePresets.json      Supported host and Raspberry Pi build presets
│   ├── xWalkDriver/            Product behavior and feature agents
│   ├── xWalkAudioResources/   Versioned sound and music resources
│   ├── xWalkController/       CLI and application composition
│   ├── xWalkHal/              Hardware abstraction and simulation backends
│   ├── xWalkLibrary/          Shared libraries and external dependencies
│   └── cmake/                 Shared CMake modules and toolchains
├── devloper-note/             Developer documentation components
│   ├── gerrit-note/           Gerrit administration and CI documentation
│   └── xwalk-rpi5-note/       C++ architecture, build, and deployment documentation
├── xWalk-rpi5-iw/             Interface schemas and generated bindings
├── xWalk-rpi5-node/           Reserved Raspberry Pi node component
├── xWalk-rpi5-tool/           CI, Gerrit, deployment, quality, and maintenance tools
└── xWalk-rpi5-trace/           Shared tracing implementation
```

## Prerequisites

The supported host workflow requires Linux, CMake 3.25 or newer, Ninja, a C++17 compiler, Python 3, and the
development libraries used by the complete product.

On Ubuntu or Debian, run the [dependency installation script](setup.sh). Run it with sudo to
update the package index and install each native dependency separately:

```bash
sudo ./setup.sh
```

The script requires root privileges and stops if an installation command fails. It detects host or Pi
and reads the full shared package catalog, including MQTT/TLS, generators, tests, and quality tools.
Use `sudo ./setup.sh --target host` or `sudo ./setup.sh --target rpi` to select the target explicitly.
Pi setup requires Raspberry Pi 5 ARM64 and includes CSI camera packages. Initialize the tooling submodule first.
For complete source and Raspberry Pi setup, use [install.sh](install.sh) instead.

For a manual installation of the core host subset, run:

```bash
sudo apt-get update
sudo apt-get install build-essential
sudo apt-get install cmake
sudo apt-get install ninja-build
sudo apt-get install pkg-config
sudo apt-get install python3
sudo apt-get install libasound2-dev
sudo apt-get install libcurl4-openssl-dev
sudo apt-get install libprotobuf-dev
sudo apt-get install libgrpc++-dev
sudo apt-get install libgtest-dev
sudo apt-get install libjson-c-dev
sudo apt-get install libtinyxml2-dev
sudo apt-get install libyaml-cpp-dev
```

See the [dependency guide](devloper-note/xwalk-rpi5-note/Doc/note/Dependency%20Installer%20Guide.md) for optional
quality tools, generators, Raspberry Pi packages, and dependency troubleshooting.

## Prepare a fresh Linux machine

[install.sh](install.sh) prepares a fresh Linux machine to build the xWalk source. It installs native
dependencies, initializes the pinned source submodules, and configures CMake. On Raspberry Pi it also prepares
boot settings and device permissions for the selected Robot HAT.

### Requirements

- Ubuntu 24.04 or newer, or Debian/Raspberry Pi OS 12 or newer, with APT.
- A normal user account with sudo access. Run the script without `sudo`; it elevates system operations itself.
- Internet access to package repositories and authenticated read access to every private Git submodule.
- For native Pi setup: Raspberry Pi 5 with a 64-bit ARM64 operating system and an identified Robot HAT revision.

Install the operating system and configure networking first. The script does not flash an SD card or firmware.
For Git authentication and recursive cloning, follow [Clone from GitHub](#clone-from-github).
If Git is missing before cloning, install it through your operating system's package manager first.

The commands below run from the directory containing `install.sh`. The script also works when invoked by its
absolute path from another directory.

### Linux workstation

Install dependencies and configure the host build:

```bash
./install.sh --target host
```

To compile as part of setup:

```bash
./install.sh --target host --build --jobs 2
```

To build later and run host tests:

```bash
cmake --build build-host/cmake --parallel 2
ctest --test-dir build-host/cmake --output-on-failure --no-tests=error
```

Host setup uses the `host-debug` preset and writes build files under `build-host/cmake`.

### Raspberry Pi 5

Identify the physical HAT revision before selecting its profile. CSI camera dependencies are selected by this
installer. The runtime account defaults to the account running the script.

#### Robot HAT v4

```bash
./install.sh --target rpi --profile robot_hat_v4 --build
```

There is no verified v4 overlay in this repository. This profile enables I2C/SPI and prepares device access,
but retains the installed audio overlay. Board-specific v4 audio setup remains separate. The Servo HAT+ file
is not installed as a v4 substitute.

#### Robot HAT v5

```bash
./install.sh --target rpi --profile robot_hat_v5 --build
```

The supported v5 UUID must already be visible in the local Device Tree. The installer checks the bundled
`sunfounder-robothat5.dtbo` checksum before installing it into the boot overlay directory and enabling it.
If board identification fails, installation stops; selecting v4 is not a workaround for an unidentified v5 board.

#### Select the runtime user and GPIO controller

For an existing account named `xwalk` and a board whose intended GPIO controller is `/dev/gpiochip0`:

```bash
./install.sh --target rpi --profile robot_hat_v4 --runtime-user xwalk --gpio-device /dev/gpiochip0
```

Replace these example values with the actual account and device. The script does not create a runtime user.
The GPIO default comes from the deployment defaults file, currently `/dev/gpiochip4`.

Pi setup uses the `rpi-release` preset and writes build files under `build-rpi/cmake`. To compile later:

```bash
cmake --build build-rpi/cmake --parallel 2
```

After setup, review the boot configuration and its backup, then reboot manually to activate boot settings
and new group memberships. Hardware acceptance is separate. To list hardware tests without running them:

```bash
ctest --test-dir build-rpi/cmake -N -L hardware
```

### What setup changes

| Area | Action |
| --- | --- |
| Source | Synchronizes submodule URLs and initializes exact pinned revisions recursively. |
| Packages | Installs catalog-selected build, generator, audio, test, quality, and packaging dependencies. |
| Build | Configures the selected CMake preset; compiles only with `--build`. |
| Pi camera | Installs CSI camera dependencies, including GStreamer components. |
| Pi boot | Enables I2C/SPI in an `[all]` section and arranges for `i2c-dev` to load at boot. |
| Pi HAT v5 | Installs and selects the checksum-verified Robot HAT v5 overlay. |
| Pi access | Adds device groups, runtime-user memberships, and rules for the selected device nodes. |
| Pi configuration | Initializes writable configuration under `/var/lib/xwalk` from repository templates. |

Boot configuration backups use the `.xwalk-backup` suffix alongside `config.txt`. A different existing v5
blob is also backed up before replacement. Existing backups are preserved on reruns. The setup locates
`/boot/firmware/config.txt` or the supported legacy `/boot/config.txt` layout.

Setup does not start the robot, automatically reboot, or run hardware tests. Optional Ollama/Piper models,
provider credentials, and board-specific audio configuration require separate runtime setup.

### Options

| Option | Meaning |
| --- | --- |
| `--apply` | Optional compatibility alias; installation is already the default. |
| `--target auto\|host\|rpi` | Select the target; `auto` detects Raspberry Pi from the local Device Tree. |
| `--profile robot_hat_v4\|robot_hat_v5` | Explicit physical HAT profile, required for Pi setup. |
| `--runtime-user USER` | Existing Pi runtime account; defaults to the invoking user. |
| `--gpio-device /dev/gpiochipN` | Select the Pi GPIO controller used by provisioning and CMake. |
| `--build` | Compile after successful setup and CMake configuration. |
| `--jobs N` | Positive build parallelism, default 2 to limit memory use. |
| `--skip-submodules` | Keep current revisions; skip submodule synchronization and initialization. |
| `--help` | Display command-line help. |

Running `./install.sh` starts installation immediately and detects the target automatically.
Pi setup must run on the Raspberry Pi with an explicit HAT profile.

### Troubleshooting

#### Private submodule clone fails

Verify your Git authentication and read access to every component repository. Re-run after access is fixed.
See the [clone instructions](#clone-from-github).

#### Submodule revisions differ from their pins

The installer stops before changing an existing checkout with different revisions. If you deliberately want
to build those revisions, use `--skip-submodules`. Missing source modules must still be initialized.

#### Missing sudo or root invocation

Use a normal build account with sudo access. The installer rejects execution as root so Git and CMake
outputs remain owned by the build account.

#### No APT candidate for rpicam-apps

Some Ubuntu repositories do not provide this package. The dependency installer can accept a validated existing
`rpicam-still`; otherwise it reports the separate user-local camera setup workflow. Read the
[deployment tooling README](xWalk-rpi5-tool/shell-agent/deploy-tool/README.md) before using that workflow:
`setup-rpi-local.sh` also installs Ollama and downloads a model. Re-run installation after resolving the camera
prerequisite. This root installer does not change APT sources automatically.

#### Boot conflict or unidentified HAT

Review the reported disabled interface or overlapping overlay in the actual boot configuration. Verify the
physical board and Device Tree identity. Correct the configuration for that board before rerunning.

#### Package, provisioning, or CMake failure

The script returns a nonzero status and stops. Earlier completed steps may remain applied; this is not a
transactional rollback. Resolve the reported error and rerun the same command. Package checks skip installed
packages, and boot additions preserve backups and avoid duplicating the settings they manage.

## Build the complete repository

Run all commands from the repository root. The `sanity` preset enables the complete Debug host build, tests,
compile commands, and strict compiler warnings. The preset is loaded from the `xWalk-rpi5-hw` product source tree.

```bash
cmake --fresh -S xWalk-rpi5-hw --preset sanity
cmake --build build-host/sanity --parallel
ctest --test-dir build-host/sanity --output-on-failure --no-tests=error
```

The generated files are written below `build-host/sanity`.

## VS Code symbol navigation

Open the `MyPiCarX` repository root in VS Code and install the recommended
CMake Tools and C/C++ extensions. The workspace combines the host product and
independent server compilation databases, while the fallback symbol browser
indexes project-owned hardware, simulation, test, interface, tool, trace, and
server source trees. Ctrl+click, **Go to Definition**, **Go to Declaration**,
and **Find All References** therefore work across module boundaries.

After changing CMake source lists or moving files, run the VS Code task
`xWalk: Refresh all C++ navigation`. The equivalent terminal commands are:

```bash
cmake --preset host-debug -S xWalk-rpi5-hw
```

If VS Code retains stale symbols after a large relocation, run **C/C++: Reset
IntelliSense Database** once and then execute the refresh task again.

For an optimized host build:

```bash
cmake --fresh -S xWalk-rpi5-hw --preset host-release
cmake --build build-host/release --parallel
ctest --test-dir build-host/release --output-on-failure --no-tests=error
```

## Controller configuration

The Controller component currently retains deployment configuration only. It does not build an executable while
the replacement CBB-style execution architecture is being designed.

## Installation

Create and test a staged Release installation without modifying the host system:

```bash
cmake --fresh -S xWalk-rpi5-hw --preset host-release
cmake --build build-host/release --parallel
DESTDIR="$PWD/build-host/deploy" cmake --install build-host/release
```

The staged filesystem is created under `build-host/deploy`. After reviewing that layout, an administrator may
install the same build into the configured `/usr` prefix:

```bash
sudo cmake --install build-host/release
```

System installation does not authorize hardware tests or actuator operation. Raspberry Pi setup, permissions,
services, configuration, and rollback are documented in the
[deployment guide](devloper-note/xwalk-rpi5-note/Doc/note/Deployment%20Guide.md).

## Raspberry Pi build

On a compatible Raspberry Pi build host, configure and compile the product with:

```bash
cmake --fresh -S xWalk-rpi5-hw --preset rpi-release
cmake --build build-rpi/cmake --parallel
ctest --test-dir build-rpi/cmake -N -L hardware
```

The RPi preset uses Robot HAT v4, runtime user `xwalk`, `/dev/gpiochip4`,
`/dev/i2c-1`, `/dev/spidev0.0`, and a CSI camera unless explicitly overridden
with the corresponding `XWALK_RPI_*` CMake cache value.

The final command lists hardware tests; it does not execute them. Run hardware-labelled tests only after explicitly
confirming the Raspberry Pi model, Robot HAT revision, wiring, power, clear movement area, and emergency-stop plan.

## Issue tracking

Create and manage defects, features, stories, and tasks in the
[TARS Jira project](https://student-team-xwalk-rpi5.atlassian.net/jira/software/projects/TARS/boards/3).
GitHub Issues is intentionally disabled so Jira remains the single issue-tracking system. Source changes continue
through Gerrit and should reference the applicable Jira work item.

## Additional documentation

- [Open the published xWalk Developer Notes wiki](https://jochuuu.github.io/xWalkPiCarAI/)
- [C++ documentation index](devloper-note/xwalk-rpi5-note/index.md)
- [Build and open the developer-note wiki](devloper-note/README.md)
- [Build and installation guide](devloper-note/xwalk-rpi5-note/Doc/note/Installation.md)
- [Controller and CLI overview](xWalk-rpi5-hw/xWalkController/README.md)
- [Development and maintenance tools](xWalk-rpi5-tool/README.md)
- [Repository instructions](AGENTS.md)

## Run Gerrit and Gerrit CI

### Start the local Gerrit server

Load [git.sh](xWalk-rpi5-tool/shell-agent/env-tool/git.sh) once in each integrated checkout
as your normal user. It configures the
repository-local Gerrit push transport so an ordinary `git push` starts the
Gerrit stack installed on the current machine before opening the Gerrit SSH
connection:

```bash
source xWalk-rpi5-tool/shell-agent/env-tool/git.sh
```

On a personal workstation this starts its local Gerrit profile. On the college
host it starts that machine's managed Gerrit profile. A client without a local
Gerrit installation connects to its configured remote server without attempting
to manage that server. Set `XWALK_GIT_AUTO_START=false` in the machine-local Git
environment override to disable push-triggered startup.

Assess the local host before the first installation:

```bash
xWalk-rpi5-tool/py-agent/gerrit-tool/local-linux/gerrit-local.sh assess
```

Install and start a local Gerrit instance when it has not been installed previously:

```bash
xWalk-rpi5-tool/py-agent/gerrit-tool/local-linux/gerrit-local.sh install
```

Start an existing local Gerrit instance after a reboot or shutdown:

```bash
xWalk-rpi5-tool/py-agent/gerrit-tool/local-linux/gerrit-local.sh start
```

After installation, use the generated management commands to inspect and control the server:

```bash
"$HOME/bin/gerrit-status"
"$HOME/bin/gerrit-check"
"$HOME/bin/gerrit-logs"
"$HOME/bin/gerrit-stop"
"$HOME/bin/gerrit-start"
```

Print the configured browser URL:

```bash
git config --file "$HOME/gerrit-site/etc/gerrit.config" --get gerrit.canonicalWebUrl
```

The local profile normally exposes Gerrit SSH on port `29419`. Installation details and troubleshooting are in the
[local Gerrit guide](xWalk-rpi5-tool/py-agent/gerrit-tool/local-linux/README.md). Administrators operating the managed
server profile should use the separate [Gerrit administration guide](xWalk-rpi5-tool/py-agent/gerrit-tool/README.md).

### Run Gerrit Host Quality CI

The current local Gerrit integration uses the repository-owned Python event worker. It listens to Gerrit's SSH
event stream, checks each active patch set in an isolated checkout, runs the module-oriented Host Quality graph,
serves the existing `/ci/changes/<change>/<patch-set>` results page, and reports `Verified +1` or `Verified -1`.
Gerrit does not execute the GitHub Actions workflow.

Starting Gerrit does not start this worker. Start and inspect it separately:

```bash
"$HOME/bin/gerrit-ci-control" start
"$HOME/bin/gerrit-ci-control" status
"$HOME/bin/gerrit-ci-logs"
```

Verify the server-rendered dashboard health without exposing credentials:

```bash
curl --fail --show-error --silent --cacert "$HOME/gerrit-site/etc/gerrit-self-signed.crt" "https://192.168.1.158:18443/ci/health"
```

The worker configuration and least-privilege `xwalk-ci` SSH identity are administrator-owned. See the
[Gerrit CI configuration guide](devloper-note/gerrit-note/Doc/note/Gerrit%20CI%20Configuration.md)
for installation, module mapping, dashboard routes, `Verified` calculation, and restart instructions. The retained
`.zuul.yaml` is usable only if an administrator deliberately deploys Zuul; repository YAML does not install or
activate Zuul, and two CI backends must never vote on the same project.

After Gerrit and the selected CI worker are online, create a signed-off commit and upload an active patch set. The
upload triggers Host Quality automatically:

```bash
git add <files>
git commit -s
git push gerrit HEAD:refs/for/master
```

Upload work in progress without triggering CI by adding `%wip`:

```bash
git push gerrit HEAD:refs/for/master%wip
```

Selecting **Mark As Active** in Gerrit triggers CI for the current WIP patch set. CI does not submit a change.

Run representative repository-owned checks locally before uploading:

```bash
xWalk-rpi5-tool/shell-agent/gerrit-tool/run-host-ci-job.sh preparation
xWalk-rpi5-tool/shell-agent/gerrit-tool/run-host-ci-job.sh developer-note-wiki
xWalk-rpi5-tool/shell-agent/gerrit-tool/run-host-ci-job.sh deployment-scripts
xWalk-rpi5-tool/shell-agent/gerrit-tool/run-host-ci-job.sh build-and-test gcc Debug
```

These checks are host-safe and do not authorize physical hardware tests.

## License

See [LICENSE](LICENSE) for the repository license terms.
