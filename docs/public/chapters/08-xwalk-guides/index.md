[xWalk documentation](../index.md) / Chapter 8

# 8. Guides

## 1. Section overview

Hardware reference material and detailed task walkthroughs.

## 2. Coverage

- 45 module and guide pages, listed below.
- Source locations, interfaces, build and configuration information, testing, and safety constraints.

## 3. Prerequisites

- Read the relevant module note first. Hardware operation requires a confirmed safe setup.
- Private component access is needed for source builds; no account is needed to read these notes.

**Start here:** [API ADC](Doc/note/API%20ADC.md).

## 4. Modules and guides

- [`XWalkAdc`](Doc/note/API%20ADC.md): `XWalkAdc` acquires raw samples from one MCU ADC channel and converts samples to volts. The caller creates and retains the referenced `XWalkI2c` object.
- [`XWalkConfigStore` and `XWalkConfig`](Doc/note/API%20Filedb.md): `XWalkConfigStore` provides flat key-value persistence. `XWalkConfig` provides section-aware configuration persistence. Both are defined by the `xWalkConfig` module.
- [`XWalkGpio`](Doc/note/API%20Pin.md): `XWalkGpio` provides digital mode, pull, polarity, value, and edge operations. `XWalkGpioLinux` is the optional Linux resource-owning backend.
- [`XWalkI2c`](Doc/note/API%20I2C.md): `XWalkI2c` is the hardware-independent callback-driven bus abstraction. `XWalkI2cLinux` optionally owns a Linux I2C file descriptor.
- [`XWalkMotor` and `XWalkMotors`](Doc/note/API%20Motor.md): `XWalkMotor` controls one motor using the PWM and direction dependencies selected for the board mode. `XWalkMotors` coordinates two non-owning motor pointers.
- [`XWalkMusic`](Doc/note/API%20Music.md): `XWalkMusic` provides music-theory conversion, PCM tone generation, and injected audio operations. It does not own an ALSA device or launch a platform process.
- [`XWalkPwm` and `XWalkPwmTimerState`](Doc/note/API%20PWM.md): `XWalkPwm` controls one MCU PWM channel. `XWalkPwmTimerState` coordinates the frequency and period shared by channels assigned to one hardware timer.
- [`XWalkRobot`](Doc/note/API%20Robot.md): `XWalkRobot` coordinates caller-created servo objects, named positions, and multi-servo action frames. Persistent configuration remains in `XWalkConfig`.
- [`XWalkServo`](Doc/note/API%20Servo.md): `XWalkServo` translates angle and pulse-duration commands into a caller-created `XWalkPwm` output.
- [`XWalkTrace`](Doc/note/API%20Basic%20Class.md): `XWalkTrace` provides filtered diagnostic output through an append-only log file and an injected callback. It replaces implicit console logging with explicit, testable sinks.
- [About the battery](Doc/note/Battery.md): The documented Robot HAT battery input accepts a balanced two-cell lithium-ion pack in the 6.0-to-8.4-volt range through an XH2.54 three-pin connector.
- [Build and installation](Doc/note/Installation.md): xWalk HAL uses CMake 3.16 or newer and requires a C++17 compiler. The root project builds all modules together and exposes separate host and Raspberry Pi hardware configurations.
- [C++ API reference](Doc/note/API.md): The public C++ headers are authoritative. This index groups the xWalk HAL modules by responsibility.
- [C++ line-following car](Doc/note/Project%20DIY%20Car.md): Create three `XWalkAdc` objects, `XWalkGrayscaleModule`, `XWalkLineTracker`, two `XWalkMotor` objects, and one `XWalkMotors` coordinator.
- [C++ plant monitor](Doc/note/Project%20Plant%20Monitor.md): Use separate `XWalkAdc` objects for light and moisture, `XWalkUserButton` for the user action, and `XWalkGpio` or a suitable motor driver for pump control.
- [C++ project examples](Doc/note/Projects.md): The project pages describe safe C++ composition rather than complete board-side applications. Create all dependencies in `main()`, validate configuration before hardware mutation, and stop outputs before dependencies.
- [C++ security-system composition](Doc/note/Project%20Security.md): Use `XWalkGpio` to report PIR state or edges. Schedule camera capture and face recognition outside the GPIO callback. Use `XWalkTextToSpeech` or `XWalkVoiceAssistant` only from an application execution context.
- [C++ speech interfaces](Doc/note/API%20TTS.md): `XWalkTextToSpeech` coordinates text synthesis through an injected backend. `XWalkSpeechToText` coordinates recognition through an injected backend. Both classes belong to `xWalkGPT`.
- [C++ utility interfaces](Doc/note/API%20Utils.md): The `xWalkUtils` module contains:
- [Clean Build Script Guide](Doc/note/Clean%20Build%20Script%20Guide.md): `clean-build.sh` discovers generated CMake and Python output throughout the MyPiCarX workspace and optionally removes it. Use it when a clean configure is needed, stale CMake caches must be discarded, or Python.
- [CMake Dependency Guide](Doc/note/Dependency%20Installer%20Guide.md): This guide documents the dependencies that CMake needs to configure and build the xWalk C++ workspace. It describes external development packages, project-target relationships, build-mode differences, and common.
- [Community C++ adaptations](Doc/note/Community%20Tutorials.md): External tutorials can target different Robot HAT revisions, operating systems, or APIs. Before adapting one to xWalk Firmware:
- [Configure I2S for the speaker](Doc/note/Install%20I2S%20for%20Speaker.md): I2S and ALSA configuration belongs to target deployment, not to xWalk HAL production code. Configure the operating-system audio overlay and routing using the deployment procedure approved for the target image.
- [Control servos and motors](Doc/note/Project%20Control%20Motor%20Servo.md): Create the I2C backend, I2C interface, PWM timer states, PWM channels, servos, and motors in that order. Coordinated servo motion belongs to `XWalkRobot`; paired motor validation belongs to `XWalkMotors`.
- [Controller command flow](Doc/note/Controller%20Command%20Flow.md): The previous Controller command flow has been removed. No Controller executable or handler chain is currently available.
- [Controller execution architecture](Doc/note/CLI%20Architecture.md): The previous Controller command-line and handler architecture has been removed. The component currently retains configuration only.
- [Dependency Installer Script Flags](Doc/note/Dependency%20Installer%20Script%20Flags.md): This reference documents every command-line flag accepted by dependency installer. The separate CMake Dependency Guide explains the workspace's CMake configure-time and link-time dependency requirements.
- [Device Tree Overlay Assets Guide](Doc/note/Device%20Tree%20Overlay%20Assets%20Guide.md): > [!IMPORTANT] > `/usr/bin/xwalk-picarx-control` and its Doctor command are temporarily unavailable after deletion of the former > Platform composition. Command examples are historical until the replacement Control.
- [Features](Doc/note/Features.md): xWalk Firmware provides C++17 hardware-abstraction components for Robot HAT boards. The current implementation includes:
- [Hardware introduction](Doc/note/Hardware%20Introduction.md): Module layout, interfaces, build, configuration, and verification.
- [Hardware Provisioning Script Guide](Doc/note/Hardware%20Provisioning%20Script%20Guide.md): > [!IMPORTANT] > `/usr/bin/xwalk-picarx-control` and its Doctor command are temporarily unavailable after deletion of the former > Platform composition. Command examples are historical until the replacement Control.
- [Host Coverage Script Guide](Doc/note/Host%20Coverage%20Script%20Guide.md): host coverage script configures, builds, tests, and reports host coverage in the foreground. It does not create a detached process, install packages, request privileges, or access Raspberry Pi hardware.
- [Onboard MCU](Doc/note/Onboard%20MCU.md): The Robot HAT uses an onboard microcontroller for ADC and PWM operations. xWalk communicates through `XWalkI2c`; the normal 7-bit MCU address is `0x14`.
- [PiCar-X Controller command reference](Doc/note/PiCar-X%20Controller%20Command%20Reference.md): The previous Controller executable and its commands have been retired. The retained files below `xWalk-rpi5-hw/xWalkController/xWalkConfig` are configuration inputs for a future execution architecture; they do not.
- [Produce speech](Doc/note/Project%20Say%20Something.md): Create the platform synthesis backend, `XWalkBoardControl`, and `XWalkTextToSpeech` in `main()`. Enable speaker power only after target audio configuration is valid, then pass bounded text to the injected synthesis.
- [Raspberry Pi Deployment Guide](Doc/note/Deployment%20Guide.md): > [!IMPORTANT] > `/usr/bin/xwalk-picarx-control` and its Doctor command are temporarily unavailable after deletion of the former > Platform composition. Command examples are historical until the replacement Control.
- [Raspberry Pi Setup Script Guide](Doc/note/Raspberry%20Pi%20Setup%20Script%20Guide.md): > [!IMPORTANT] > `/usr/bin/xwalk-picarx-control` and its Doctor command are temporarily unavailable after deletion of the former > Platform composition. Command examples are historical until the replacement Control.
- [Read a photoresistor](Doc/note/Project%20Photoresistor.md): Connect the sensor to a valid ADC input and create one `XWalkAdc` object from the shared `XWalkI2c` dependency.
- [Read ultrasonic distance](Doc/note/Project%20Ultrasonic.md): Create separate trigger and echo `XWalkGpio` objects and pass them to `XWalkUltrasonic`.
- [Safety and troubleshooting](Doc/note/FAQ.md): Module layout, interfaces, build, configuration, and verification.
- [Sensors and actuators](Doc/note/API%20Modules.md): Module layout, interfaces, build, configuration, and verification.
- [xWalk Firmware Robot HAT documentation](Doc/note/Index.md): This directory is the workspace-level C++ documentation set for the xWalk HAL. It follows the page structure of the Robot HAT source documentation while describing only the current C++ implementation.
- [xWalk HAL hardware and backend architecture](Doc/note/HAL%20Hardware%20Architecture.md): **Project:** xWalk Firmware
- [xWalk high-level architecture](Doc/note/HAL%20Arcithure.md): **Project:** xWalk Firmware
- [xWalk-rpi5-tool Overview](Doc/note/xWalk-rpi5-tool%20Overview.md): `xWalk-rpi5-tool` contains repository-maintenance, host-verification, Raspberry Pi provisioning, interface-generation, and Device Tree assets. It is tooling around the xWalk firmware workspace, not a HAL or Agent.

## 5. Table of contents

- [Section overview](#1-section-overview)
- [Coverage](#2-coverage)
- [Prerequisites](#3-prerequisites)
- [Modules and guides](#4-modules-and-guides)

---

[Previous chapter](../07-xwalk-trace/index.md) · [Next chapter](../index.md)

[Previous page](../07-xwalk-trace/index.md) · [Chapter index](index.md) · [Next page](Doc/note/API%20ADC.md)
