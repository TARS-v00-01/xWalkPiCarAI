<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [2. xWalk hardware](../../../index.md) / Boot module ownership

**2. xWalk hardware &middot; Module 05**

<!-- xwalk-page-header:end -->

# Boot module ownership

Boot owns the following production objects. Abstract interfaces, temporary RAII guards, static factories,
examples and tests are not independent global instances. Linux providers are selected by the RPi5 build;
host device operations use the Robot HAT simulator.

| Class | Header |
|---|---|
| XWalkGrayscaleCalibration | `xWalkDriver/xWalkCalibration/xWalkGrayscaleCalibration/include/xAgent_Rpi5CarGrayscaleCalibration.h` |
| XWalkServoMotorCalibration | `xWalkDriver/xWalkCalibration/xWalkServoMotorCalibration/include/xAgent_Rpi5CarServoMotorCalibration.h` |
| XWalkServoZeroing | `xWalkDriver/xWalkCalibration/xWalkServoZeroing/include/xAgent_Rpi5CarServoZeroing.h` |
| XWalkAppControl | `xWalkDriver/xWalkConnectivity/xWalkAppControl/include/xAgent_Rpi5CarAppControl.h` |
| XWalkSpiTransfer | `xWalkDriver/xWalkConnectivity/xWalkSpiTransfer/include/xAgent_Rpi5CarSpiTransfer.h` |
| XWalkSoundBackgroundMusic | `xWalkDriver/xWalkMedia/xWalkSoundBackgroundMusic/include/xAgent_Rpi5CarSoundBackgroundMusic.h` |
| XWalkCliffDetection | `xWalkDriver/xWalkVehicle/xWalkCliffDetection/include/xAgent_Rpi5CarCliffDetection.h` |
| XWalkKeyboardControl | `xWalkDriver/xWalkVehicle/xWalkKeyboardControl/include/xAgent_Rpi5CarKeyboardControl.h` |
| XWalkLineTracking | `xWalkDriver/xWalkVehicle/xWalkLineTracking/include/xAgent_Rpi5CarLineTracking.h` |
| XWalkMoveExample | `xWalkDriver/xWalkVehicle/xWalkMoveExample/include/xAgent_Rpi5CarMoveExample.h` |
| XWalkObstacleAvoidance | `xWalkDriver/xWalkVehicle/xWalkObstacleAvoidance/include/xAgent_Rpi5CarObstacleAvoidance.h` |
| XWalkPicarx | `xWalkDriver/xWalkVehicle/xWalkPicarx/include/xAgent_Rpi5CarPicarx.h` |
| XWalkSelfDrive | `xWalkDriver/xWalkVehicle/xWalkSelfDrive/include/xAgent_Rpi5CarSelfDrive.h` |
| XWalkBullFight | `xWalkDriver/xWalkVision/xWalkBullFight/include/xAgent_Rpi5CarBullFight.h` |
| XWalkCameraCapture | `xWalkDriver/xWalkVision/xWalkCameraCapture/include/xAgent_Rpi5CarCameraCapture.h` |
| XWalkComputerVision | `xWalkDriver/xWalkVision/xWalkComputerVision/include/xAgent_Rpi5CarComputerVision.h` |
| XWalkFaceTracking | `xWalkDriver/xWalkVision/xWalkFaceTracking/include/xAgent_Rpi5CarFaceTracking.h` |
| XWalkRoadUserSafety | `xWalkDriver/xWalkVision/xWalkRoadUserSafety/include/xAgent_Rpi5CarRoadUserSafety.h` |
| XWalkTreasureHunt | `xWalkDriver/xWalkVision/xWalkTreasureHunt/include/xAgent_Rpi5CarTreasureHunt.h` |
| XWalkVideoCar | `xWalkDriver/xWalkVision/xWalkVideoCar/include/xAgent_Rpi5CarVideoCar.h` |
| XWalkVideoRecording | `xWalkDriver/xWalkVision/xWalkVideoRecording/include/xAgent_Rpi5CarVideoRecording.h` |
| XWalkVideoStreaming | `xWalkDriver/xWalkVision/xWalkVideoStreaming/include/xAgent_Rpi5CarVideoStreaming.h` |
| XWalkGptCar | `xWalkDriver/xWalkVoice/xWalkGptCar/include/xAgent_Rpi5CarGptCar.h` |
| XWalkLocalVoiceChatbot | `xWalkDriver/xWalkVoice/xWalkLocalVoiceChatbot/include/xAgent_Rpi5CarLocalVoiceChatbot.h` |
| XWalkOnlineLlmTest | `xWalkDriver/xWalkVoice/xWalkOnlineLlmTest/include/xAgent_Rpi5CarOnlineLlmTest.h` |
| XWalkStorytellingRobot | `xWalkDriver/xWalkVoice/xWalkStorytellingRobot/include/xAgent_Rpi5CarStorytellingRobot.h` |
| XWalkTextVisionTalk | `xWalkDriver/xWalkVoice/xWalkTextVisionTalk/include/xAgent_Rpi5CarTextVisionTalk.h` |
| XWalkVoiceActiveCar | `xWalkDriver/xWalkVoice/xWalkVoiceActiveCar/include/xAgent_Rpi5CarVoiceActiveCar.h` |
| XWalkVoiceControlledCar | `xWalkDriver/xWalkVoice/xWalkVoiceControlledCar/include/xAgent_Rpi5CarVoiceControlledCar.h` |
| XWalkVoicePromptCar | `xWalkDriver/xWalkVoice/xWalkVoicePromptCar/include/xAgent_Rpi5CarVoicePromptCar.h` |
| XWalkAdc | `xWalkHal/device/xWalkAdc/include/xHal_Rpi5CarAdc.h` |
| XWalkAdxl345 | `xWalkHal/device/xWalkAdxl345/include/xHal_Rpi5CarAdxl345.h` |
| XWalkCamera | `xWalkHal/device/xWalkCamera/core/include/xHal_Rpi5CarCamera.h` |
| XWalkCameraStream | `xWalkHal/device/xWalkCamera/core/include/xHal_Rpi5CarCameraStream.h` |
| XWalkPwm | `xWalkHal/device/xWalkPwm/include/xHal_Rpi5CarPwm.h` |
| XWalkPwmTimerState | `xWalkHal/device/xWalkPwm/include/xHal_Rpi5CarPwmTimerState.h` |
| XWalkServo | `xWalkHal/device/xWalkServo/include/xHal_Rpi5CarServo.h` |
| XWalkUltrasonic | `xWalkHal/device/xWalkUltrasonic/include/xHal_Rpi5CarUltrasonic.h` |
| XWalkUserButton | `xWalkHal/device/xWalkUserButton/include/xHal_Rpi5CarUserButton.h` |
| XWalkConfig | `xWalkHal/interface/xWalkConfig/include/xHal_Rpi5CarConfig.h` |
| XWalkConfigStore | `xWalkHal/interface/xWalkConfig/include/xHal_Rpi5CarConfigStore.h` |
| XWalkGpio | `xWalkHal/interface/xWalkGpio/core/include/xHal_Rpi5CarGpio.h` |
| XWalkI2c | `xWalkHal/interface/xWalkI2c/core/include/xHal_Rpi5CarI2c.h` |
| XWalkLanguageModel | `xWalkHal/interface/xWalkLanguageModel/include/xHal_Rpi5CarLanguageModel.h` |
| XWalkSpi | `xWalkHal/interface/xWalkSpi/core/include/xHal_Rpi5CarSpi.h` |
| XWalkUtils | `xWalkHal/interface/xWalkUtils/include/xHal_Rpi5CarUtils.h` |
| XWalkWebSearch | `xWalkHal/interface/xWalkWebSearch/include/xHal_Rpi5CarWebSearch.h` |
| XWalkBoardControl | `xWalkHal/layer1/xWalkBoardControl/include/xHal_Rpi5CarBoardControl.h` |
| XWalkDevice | `xWalkHal/layer1/xWalkBoardControl/include/xHal_Rpi5CarDevice.h` |
| XWalkFirmwareInfo | `xWalkHal/layer1/xWalkBoardControl/include/xHal_Rpi5CarFirmwareInfo.h` |
| XWalkSpeechToText | `xWalkHal/layer1/xWalkGPT/include/xHal_Rpi5CarSpeechToText.h` |
| XWalkTextToSpeech | `xWalkHal/layer1/xWalkGPT/include/xHal_Rpi5CarTextToSpeech.h` |
| XWalkMusic | `xWalkHal/layer1/xWalkMusic/include/xHal_Rpi5CarMusic.h` |
| XWalkRobot | `xWalkHal/layer1/xWalkRobot/include/xHal_Rpi5CarRobot.h` |
| XWalkSpeaker | `xWalkHal/layer1/xWalkSpeaker/include/xHal_Rpi5CarSpeaker.h` |
| XWalkVoiceAssistant | `xWalkHal/layer1/xWalkVoiceAssistant/include/xHal_Rpi5CarVoiceAssistant.h` |
| XWalkBuzzer | `xWalkHal/sensor/xWalkBuzzer/include/xHal_Rpi5CarBuzzer.h` |
| XWalkLed | `xWalkHal/sensor/xWalkLed/include/xHal_Rpi5CarLed.h` |
| XWalkRgbLed | `xWalkHal/sensor/xWalkLed/include/xHal_Rpi5CarRgbLed.h` |
| XWalkGrayscaleModule | `xWalkHal/sensor/xWalkLineTracker/include/xHal_Rpi5CarGrayscaleModule.h` |
| XWalkLineTracker | `xWalkHal/sensor/xWalkLineTracker/include/xHal_Rpi5CarLineTracker.h` |
| XWalkMotor | `xWalkHal/sensor/xWalkMotor/include/xHal_Rpi5CarMotor.h` |
| XWalkMotors | `xWalkHal/sensor/xWalkMotor/include/xHal_Rpi5CarMotors.h` |

---

[Previous page](xWalkBoot.md) · [Chapter index](../../../index.md) · [Next page](../xWalkStandAlone/xWalkStandAlone.md)
