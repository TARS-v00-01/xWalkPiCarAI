<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [5. xWalk node](../../../index.md) / xWalkModel

**5. xWalk node &middot; Module 24**

<!-- xwalk-page-header:end -->

# xWalkModel

`xWalkModel` runs native crosswalk-risk inference: YOLO detection through OpenCV DNN (ONNX) or the opt-in
Raspberry Pi 5 Hailo-8 backend, six-feature extraction, and exported scikit-learn Random Forest classification. It
also writes the optional risk-coloured detection preview.

## 1. Overview

`Model::predict` letterboxes a BGR frame, runs the CMake-selected `Detector`, extracts the original app's six
features and averages the forest's leaf distributions into a `TrafficObservation` with a risk label of 0 (safe),
1 (moderate) or 2 (high). It optionally returns the same detections used for feature extraction, including
confidence scores for both ONNX and Hailo backends.

The detector's five-class order must be bicycle, bus, car, motorbike, person. Feature extraction preserves the
original app's six columns and the image-relative crosswalk rectangle from 25-75% width and 55-95% height.
Integer original-image boxes determine counts, occupancy, nearest center distance divided by image diagonal, and
largest vehicle area divided by image area. Generic COCO models are not interchangeable with the trained
five-class model.

Pi builds with Hailo enabled use the C++ HailoRT backend in `hardware/` and require a trained Hailo-8 HEF. Host
builds use OpenCV ONNX with automatic CUDA/OpenCL GPU selection and CPU fallback; Pi builds without Hailo use the
same ONNX path on the CPU.

## 2. Source location

`xWalk-rpi5-node/xWalkTrafCtrl/xWalkModel` -
source directory

## 3. Directory layout

```text
xWalkModel/
    CMakeLists.txt                          Library, backend source selection and GoogleTest registration
    include/xWalkModel.h                    Model, Forest, Detector, features, decoders and host backend selection
    include/xWalkOnnxDetector.h             OpenCV DNN ONNX detector
    include/xWalkDetectionPreview.h         Atomic JPEG preview writer
    src/xWalkModel.cpp                      Letterboxing, YOLO decoding, features and forest inference
    src/xWalkOnnxDetector.cpp               ONNX backend (Hailo disabled)
    src/xWalkHostBackend.cpp                CUDA, OpenCL and CPU target selection; TRAFCTRL.004
    src/xWalkHailoOutput.cpp                Hailo NMS-by-class output decoding (all builds, tested on host)
    src/xWalkDetectionPreview.cpp           Preview drawing and JPEG risk metadata
    hardware/include/xWalkHailoDetector.h   HailoRT detector (Hailo enabled only)
    hardware/src/xWalkHailoDetector.cpp     HEF validation, VDevice and stream setup
    hardware/src/xWalkHailoBackend.cpp      Hailo detector factory
    test/src/xWalkModelTest.cpp             Host GoogleTests
```

## 4. Public interface

Declared in `xWalkModel.h` in
namespace `xwalk::traffic`:

| Symbol | Contract |
| --- | --- |
| `HostBackend`, `selectHostBackend`, `configureHostDetector` | Auto selects CUDA, then OpenCL GPU, then CPU |
| `Detection`, `Detections` | Label, original-image box and confidence |
| `extractFeatures(detections, width, height)` | Six image-relative features |
| `decodeDetections(...)` | Raw YOLOv8/YOLO11 five-class decoding with class-aware NMS |
| `decodeHailoDetections(...)` | Hailo float32 NMS-by-class decoding |
| `Forest` | Loads the forest JSON; `predict` averages normalized leaf distributions |
| `Detector`, `createDetector(settings)` | Abstract backend and CMake-selected factory |
| `Model` | Owns detector and forest; `predict(frame, detections)` classifies one frame |
| `DetectionPreview` | Atomically publishes a risk-coloured JPEG of the inferred frame |

### ONNX detector contract

The host ONNX detector must be exported with fixed batch 1, RGB input `[1,3,S,S]`, `S = input_size` (default
640), float32 values normalized to `[0,1]`, and raw YOLOv8/YOLO11-compatible `[1,9,N]` output without embedded
NMS. The nine rows are center-x, center-y, width, height and five class probabilities in exactly the order
bicycle, bus, car, motorbike, person. Pixel boxes use letterboxed input coordinates. The native path applies
centered 114-value letterboxing, class-aware NMS with IoU 0.7, and restores and clips original-image coordinates.
Other layouts, including end-to-end `[1,N,6]` exports, are not supported. The ONNX factory rejects a Hailo
artifact.

### Hailo-8 detector contract

`best.hef` must be compiled from the trained five-class detector using Hailo's Dataflow Compiler. `export-cpp`
produces the ONNX and forest inputs; it does not produce a HEF. Compilation requires representative calibration
images and the trained architecture's Hailo parser and NMS configuration. Use Hailo-8 (not Hailo-8L), exactly one
network group and an RGB square input matching `model.input_size`. Compile preprocessing for RGB pixels in 0..255
with the training normalization included in the HEF. The backend letterboxes with 114, converts BGR to RGB and
passes unquantized float32 pixel values to HailoRT, which applies the HEF quantization. Do not compile a model
that expects already-normalized 0..1 input.

The HEF requires one NMS-by-class output with exactly five classes in the training order; raw multi-head HEFs and
generic COCO HEFs are rejected. The runtime checks architecture, shapes, class count, buffer sizes and statuses,
and sets an NMS IoU threshold of 0.7. Class names cannot be recovered from this tensor contract; preserve the
training label order during compilation. Hailo NMS output contains per-class counts and normalized
`y_min,x_min,y_max,x_max,score` boxes; the decoder restores original frame coordinates before feature extraction.

The `hailo` configuration defaults to a round-robin scheduled VDevice with `multi_process_service: true`,
`group_id: "xwalk"` and `timeout_ms: 10000`. Enable the installed HailoRT service on the Pi. Other processes using
the accelerator must also use that service and matching group ID to share it; direct exclusive users can still
conflict. Set `multi_process_service: false` only where this process is the sole Hailo owner.

References: [official HailoRT 4.23 inference
API](https://github.com/hailo-ai/hailort/blob/v4.23.0/hailort/libhailort/include/hailo/inference_pipeline.hpp) and
[NMS buffer contract](https://github.com/hailo-ai/hailort/blob/v4.23.0/hailort/libhailort/include/hailo/hailort.h).
The hardware source was syntax-checked against those official headers; chip execution and accuracy require the
Pi and the compiled trained HEF and have not been verified.

### Forest JSON export

Export the actual trained `crosswalk-safety.pkl` bundle in its training environment. This component reads JSON,
not pickle. The required document shape is:

```json
{
  "schema_version": 1,
  "classes": [0, 1, 2],
  "feature_columns": [
    "num_persons", "num_vehicles", "person_in_crosswalk", "vehicle_in_crosswalk",
    "min_ped_vehicle_dist_norm", "largest_vehicle_area_norm"
  ],
  "trees": [
    [
      {"feature": 4, "threshold": 0.12, "left": 1, "right": 2},
      {"probabilities": [0, 0, 10]},
      {"probabilities": [10, 0, 0]}
    ]
  ]
}
```

This example is only a test-shaped format illustration, not a trained model. For each estimator in the trained
forest's `estimators_`, retain every node index from `tree_`. Internal nodes copy `feature`, `threshold`,
`children_left` and `children_right` into `feature`, `threshold`, `left` and `right`. Leaves copy
`tree_.value[node][0]` in the forest's `classes_` order into `probabilities`. Preserve all estimators; do not round
thresholds or leaf weights. The loader requires exactly classes `[0,1,2]` and the feature order above.

Children must have larger indices than their parent (as in sklearn trees), which rejects cycles. Each leaf must
have three finite nonnegative weights with a positive sum. Leaves are normalized before averaging across trees;
first-class order breaks ties. Input values are converted to float32 before split comparison, matching sklearn
inference. Files are capped at 64 MiB, 10000 trees and 100000 nodes per tree. No model exporter or Python runner
lives in this module. Validate exported predictions against the original trained bundle before deploying real
announcements.

### Detection preview

`DetectionPreview` draws bicycle, bus, car, motorbike and person boxes on a copy of the original inferred frame
and atomically publishes a JPEG. Empty detection sets publish a clean frame. The forest's frame risk colours every
box: safe green, moderate amber, high red. A JPEG COM segment immediately after the SOI marker contains the 12-byte
`xwalk-risk=N` value (0, 1 or 2); its segment length is 14. This keeps HUD risk status and pixels in one atomic
file without mismatched sidecar metadata. The traffic runtime enables this output only when
`XWALK_TRAFFIC_PREVIEW_FILE` is set by the desktop owner. Frames older than three seconds are discarded and output
timestamps preserve capture age. Preview failures do not stop inference or safety processing. Startup and normal
shutdown remove old preview files.

## 5. Build

Built as part of [xWalkTrafCtrl](../xWalkTrafCtrl.md). With `XWALK_TRAFCTRL_ENABLE_HAILO=OFF` CMake compiles
`src/xWalkOnnxDetector.cpp`; with ON it compiles the `hardware/` sources, requires `find_package(HailoRT 4.23)`
and links `HailoRT::libhailort` privately. The library links publicly to `xWalkProtocol` and `opencv_dnn`, and
privately to `opencv_imgproc` and `opencv_imgcodecs`.

## 6. Testing

```bash
ctest --test-dir build-host -L xWalkModel --output-on-failure
```

`xWalkModelGoogleTest` (labels `host;gtest;xWalkModel`) covers crosswalk feature geometry, raw YOLO decoding and
wrong-shape rejection, preview publication, containment and risk metadata, exported-tree thresholds and
probabilities, missing artifacts, Hailo NMS letterbox restoration and malformed output rejection, host GPU
selection and CPU fallback, a real small network forward pass on the available backend, and ONNX rejection of
a HEF.

Set `XWALK_TRAFCTRL_TEST_MODEL_DIRECTORY` to a directory containing `best.onnx` and `crosswalk-safety.json` to add
the deployment-export regression; configuration fails if either file is missing:

```bash
cmake --preset host -DXWALK_TRAFCTRL_TEST_MODEL_DIRECTORY=/absolute/path/to/xWalkNetworkWeights
```

The regression catches importer and forward-pass incompatibilities on a blank image; it does not measure
accuracy. No test needs a Hailo device, service or trained HEF.

## 7. Dependencies

- [xWalkProtocol](../xWalkProtocol/xWalkProtocol.md) for `TrafficObservation`.
- OpenCV 4.10 or newer (`dnn`, `imgproc`, `imgcodecs`) for ONNX builds; see
  [xWalkTrafCtrl Host Dependencies](../cmake/host-dependencies/xWalkTrafCtrl%20Host%20Dependencies.md).
- HailoRT 4.23 C++ development package, driver and firmware for Hailo builds only.

## 8. Safety and constraints

- There is no automatic CPU fallback after a Hailo failure, and model loading or inference errors are not silently
  retried on another backend.
- There is no added hard timeout around inference.
- Real-model agreement and accuracy have not been verified without the trained exports.

## 9. Related notes

- [xWalkRuntime](../xWalkRuntime/xWalkRuntime.md)
- [xWalkTrafCtrl](../xWalkTrafCtrl.md)

---

[Previous page](../xWalkInput/xWalkInput.md) · [Chapter index](../../../index.md) · [Next page](../xWalkPathVision/xWalkPathVision.md)
