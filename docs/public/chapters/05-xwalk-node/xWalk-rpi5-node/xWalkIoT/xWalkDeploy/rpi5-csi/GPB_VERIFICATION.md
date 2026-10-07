<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [5. xWalk node](../../../../index.md) / Future Raspberry Pi GPB
verification

**5. xWalk node &middot; Module 04**

<!-- xwalk-page-header:end -->

# Future Raspberry Pi GPB verification

This checklist has **not** been run for these changes. It requires a connected, reviewed Pi 5 / Robot HAT setup,
a clear motion area, verified MQTT TLS configuration, and explicit operator permission. Use the existing native
xWalk publisher/subscriber only. Preserve the original deployment configuration and calibration; use private
request/configuration copies for testing. Do not publish synthetic CFM/REJ messages.

The 2026-09-13 run exercised 38 request families, with cancelled/partial cases and timeouts. It was not a complete
functional pass and did not independently exercise all 76 response encodings. SPI zero bytes did not establish
external-peripheral correctness. Do not infer full autonomous, vision, voice, or external-app verification.

## 1. Preparation and classification

Rebuild native xWalk, refresh the supported runtime launcher through explicit deployment generation, validate
the selected Piper model/JSON, and verify the actual libcamera/GStreamer paths on the Pi. Review a preserved
older launcher against the current template. Set `RUN` to that launcher and `SAMPLES` to the native build's staged
config directory. The sample paths in the commands below must be target-local.

Prepare private JSON copies using the shipped samples. Keep every original request's correlation identity
unique. Use another identity for each STOP, consistently updating nested and outer `clientAddress` fields.
Prepare `active.json` and `stopped.json` from LifeMoveReq with targets `XWALK_LIFE_STATE_ACTIVE` and
`XWALK_LIFE_STATE_STOPPED`. Prepare `voice-stop.json` from VoiceChatReq with action
`XWALK_LIFECYCLE_ACTION_STOP`. Prepare a TreasureHunt STOP from its existing action schema. Preserve broker
credentials outside these files. A publisher timeout does not cancel the remote operation.

```bash
RUN=/path/to/runtime/run-xwalk
SAMPLES=/path/to/native-build/config
REQUESTS=/path/to/private-test-requests
"$RUN" subscribe --function all
```

Leave this single subscriber running in Terminal 1. Use separate publisher terminals for an active session and
its STOP. Do not start a second hardware-owning subscriber. Record request/response signals, both identities,
CFM/REJ text and codes, UTC timestamps, lifecycle state, and actual device shutdown for every case.

| Outcome | Evidence required |
| --- | --- |
| One-shot success | Matching CFM after the requested work and cleanup, with observable device result |
| Continuous session | Work observed, then original cancellation REJ and separately correlated STOP CFM |
| Expected rejection | Invalid/unknown/busy/duplicate or commissioning-limit REJ with the requesting identity |
| Genuine failure | Diagnostic REJ retaining provider or cleanup category, even when STOP overlaps |
| Timeout | Publisher exit 124 and no matching result by deadline; investigate, never count as success |

## 2. One-shot and commissioning checks

After confirming the safe setup, explicitly activate through lifecycle GPB:

```bash
"$RUN" publish --function service --signal XWALK_LIFE_MOVE_REQ --file "$REQUESTS/active.json"
"$RUN" publish --function service --signal XWALK_HEALTH_REQ
"$RUN" publish --function service --signal XWALK_VERSION_REQ
"$RUN" publish --function voice --signal XWALK_CNTRL_SOUND_REQ --file "$SAMPLES/request/voice/xWalkMqttSoundReq.json"
"$RUN" publish --function vehicle --signal XWALK_CNTRL_MOVE_REQ --file "$SAMPLES/request/vehicle/xWalkMqttMoveReq.json"
```

Verify actual PCM16 playback at 20% and the bounded 15% / 250 ms movement. A separate private movement request
above the configured uncommissioned limit must still be rejected. Never raise the cap or mark calibration
verified to pass the test. Recheck CSI recording through the existing recording request: inspect the resulting
artifact, frame count, duration, and dimensions; a CFM or plugin discovery alone is insufficient.

## 3. STOP during active inference and speech

Start voice chat in Terminal 2 with its unique private request. Speak a prompt and observe recognition complete
and HTTP inference actually begin. While inference is still active, send the session STOP in Terminal 3:

```bash
"$RUN" publish --function voice --signal XWALK_CNTRL_VOICE_CHAT_REQ --file "$REQUESTS/voice-start.json" --timeout-ms 45000
"$RUN" publish --function voice --signal XWALK_CNTRL_VOICE_CHAT_REQ --file "$REQUESTS/voice-stop.json" --timeout-ms 30000
```

These commands run in separate terminals. Preserve the original configured model timeout; do not shorten it or
increase publisher timeouts to hide a blocking provider. Measure from Controller STOP admission to STOP CFM and
confirm that required device cleanup precedes the CFM. Expect exactly one original cancellation REJ and one
separately correlated STOP CFM. No optional farewell should start after cancellation. The proposed target is two
seconds for the cancellable provider paths; host fixtures meet it, but Pi measurements must be recorded honestly.

Repeat with STOP while Piper synthesis is running, then while playback is audibly active. Verify only the owned
speech processes stop, no child is left unreaped, and unrelated services continue. Repeat with LifeMove STOPPED
instead of session STOP. Only accepted lifecycle STOPPED closes the vehicle and changes lifecycle state to
STOPPED; session STOP retains the current lifecycle state and requires normal reactivation rules for motion.

```bash
"$RUN" publish --function service --signal XWALK_LIFE_MOVE_REQ --file "$REQUESTS/stopped.json" --timeout-ms 30000
"$RUN" publish --function service --signal XWALK_HEALTH_REQ
```

Repeat Treasure Hunt STOP during startup. Confirm cancellation is distinct from failed camera startup and no
optional goodbye delays cleanup. Rerun VoicePromptCar and StorytellingRobot using the validated installed voice;
the original run did not retest those cases with Alan. A provider failure remains a diagnostic REJ, not success.

## 4. Duplicate, shutdown, and recovery checks

- While one STOP is pending, send a separately identified duplicate. Expect its existing rejection and no
  duplicate completion for the accepted STOP. A rejected lifecycle STOP must not close the vehicle.
- Send idle STOP, then activate as required and start another operation. Check for no stale cancellation.
- Repeat a successful one-shot operation after each cancelled session; verify fresh identity and response count.
- During active voice work, stop the owning subscriber with Ctrl+C. Observe orderly safety shutdown and no user
  STOP confirmation, since none was submitted. Restart the same existing subscriber and recheck admission.
- Exercise terminal EOF/callback cancellation only in a mode that expects terminal input; distinguish expected
  interruption from provider errors. Do not count a cancelled continuous session as a one-shot functional pass.
- If cleanup fails, expect STOP REJ and investigate device state. Never treat a received response alone as proof
  of safe cleanup. Record any provider, resolver, camera, or kernel boundary exceeding the proposed bound.

Finish with an accepted lifecycle STOPPED request, verify motors and speech are stopped, terminate test
subscribers, and restore the original deployment overrides. Keep artifacts and results separate from source.

---

[Previous page](Raspberry%20Pi%205%20CSI%20Camera%20Deployment.md) · [Chapter index](../../../../index.md) · [Next page](../../xWalkMqttClient/xWalkMqttClient.md)
