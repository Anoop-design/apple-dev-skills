# Vision request patterns

Checked 2026-10-16 against Xcode 27.0 (27A266a), Swift 6.4, and the iOS 27 SDK. Availability below is per API, not the skill name.

## Request execution and orientation

The `VN` API is synchronous. Call the following on a worker queue or isolated worker appropriate to the app; an `async` function alone doesn't guarantee that. Supply the actual orientation from the image/capture pipeline instead of assuming `.up` for every photo.

```swift
import Vision
import ImageIO

func recognizedText(in image: CGImage,
                    orientation: CGImagePropertyOrientation) throws -> [String] {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    try VNImageRequestHandler(cgImage: image, orientation: orientation)
        .perform([request])
    return (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
}

func detectedObjects(in image: CGImage,
                     orientation: CGImagePropertyOrientation,
                     model: VNCoreMLModel) throws -> [VNRecognizedObjectObservation] {
    let request = VNCoreMLRequest(model: model)
    request.imageCropAndScaleOption = .scaleFit // Match your model's training pipeline.
    try VNImageRequestHandler(cgImage: image, orientation: orientation)
        .perform([request])
    return request.results as? [VNRecognizedObjectObservation] ?? []
}
```

Inspect the custom model's output contract: a classifier or feature model won't produce detected-object observations. There is no `VNRecognizeObjectsRequest` shortcut. For multiple compatible requests, `perform([requestA, requestB])` avoids repeating your own setup; measure rather than assuming all computation is shared.

## Coordinates and extraction

Vision bounding boxes use normalized image coordinates with a lower-left origin. Conversion to a UIKit/SwiftUI overlay also needs the image's oriented size, aspect-fit/fill scaling, crop, mirroring, and the displayed image rectangle. Multiplying by the entire view's bounds is correct only when the image exactly fills those bounds without crop or letterboxing.

OCR's `topCandidates(1).first` covers a recognized text observation. Calling `boundingBox(for:)` with its entire string range gives that text range's box, not one box per word. Tokenize the candidate string and ask for each valid range if the task requires word boxes.

For face pose, convert optional numbers with `face.pitch.map { CGFloat($0.doubleValue) }`, likewise yaw and roll. Gate recognized body/hand points by confidence and preserve nil for unavailable joints. A few coordinate comparisons are only a gesture heuristic; validate the gesture definition across orientations, hands, and occlusions.

## Document boundaries

`VNDetectDocumentSegmentationRequest` produces rectangle observations; don't read a nonexistent `pixelBuffer` mask from its result. For perspective correction use the observed corners with Core Image's `CIPerspectiveCorrection`, after converting normalized coordinates to the image extent. Foreground-instance-mask APIs are a separate workflow. Don't label a blend-with-mask filter “perspective correction.”

## Feature prints

Use `VNGenerateImageFeaturePrintRequest` and `VNFeaturePrintObservation.computeDistance(_:to:)`. A lower distance indicates more similar feature prints for a compatible revision; it is not inherently in `[0, 1]`. Preserve the distance and calibrate a task-specific threshold on known matching/nonmatching pairs. `max(0, 1 - distance)` invents a probability scale and should not be used as confidence.

## Video

Reuse capture configuration and throttle analysis to a useful rate. Set `alwaysDiscardsLateVideoFrames` when appropriate and avoid overlapping work that accumulates latency. Check `canAddInput`/`canAddOutput`, run session setup/start on the capture queue, handle permission/session interruptions, and perform UI updates on the main actor. Camera integration needs its full lifecycle; don't paste a partial capture class into production.

Official sources: [VNImageRequestHandler](https://developer.apple.com/documentation/vision/vnimagerequesthandler), [VNCoreMLRequest](https://developer.apple.com/documentation/vision/vncoremlrequest), [VNDetectDocumentSegmentationRequest](https://developer.apple.com/documentation/vision/vndetectdocumentsegmentationrequest), [Analyzing image similarity with feature print](https://developer.apple.com/documentation/vision/analyzing-image-similarity-with-feature-print).
