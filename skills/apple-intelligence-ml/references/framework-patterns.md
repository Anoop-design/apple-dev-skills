# Apple ML framework patterns

Checked 2026-10-16 against Xcode 27.0 (27A266a), Swift 6.4, and the iOS 27 SDK. Availability below is per API, not the skill name.

## Core ML and Create ML

Load a compiled `.mlmodelc` using `MLModel(contentsOf:configuration:)` or a model-specific generated wrapper. Generated input/output types depend on the model asset; don't invent them. Inspect names, shapes, pixel formats, and normalization in the model description. For a source model downloaded at runtime, compile it with `MLModel.compileModel(at:)`, then load the compiled result.

Use the async prediction overload when available (iOS 17+). Merely putting synchronous prediction inside an `async` function doesn't move it off the caller's actor. Retain and reuse loaded models with deliberate concurrency ownership.

`CreateML` model training APIs such as `MLImageClassifier` are **macOS development APIs**, not generic iPhone on-device training. For supported in-app training use the relevant `CreateMLComponents` APIs or an updatable Core ML model with `MLUpdateTask`, after checking the model and platform requirements. Do not migrate an inference feature to training without a product need.

## Vision

Use `VNImageRequestHandler` with an accurate image orientation and a request such as `VNClassifyImageRequest`, `VNRecognizeTextRequest`, or `VNDetectFaceRectanglesRequest`. For custom object detection, load a suitable model into `VNCoreMLModel` and use `VNCoreMLRequest`. There is no general `VNRecognizeObjectsRequest` in the checked SDK. Specify `imageCropAndScaleOption` to match training preprocessing.

The older `VN` request API is synchronous. Run it on an appropriate worker context and propagate errors; wrapping it in an async continuation doesn't create background execution and can accidentally resume twice. The newer Swift Vision request APIs offer async workflows; check target availability before adopting them. See [Vision recipes](vision-recipes.md).

## Natural Language

Use the same string for `NLTagger.string` and the index passed to `tag(at:unit:scheme:)`:

```swift
import NaturalLanguage

func sentiment(of text: String) -> Double? {
    guard !text.isEmpty else { return nil }
    let tagger = NLTagger(tagSchemes: [.sentimentScore])
    tagger.string = text
    let (tag, _) = tagger.tag(at: text.startIndex,
                             unit: .paragraph, scheme: .sentimentScore)
    return tag.flatMap { Double($0.rawValue) }
}
```

Language recognition, named-entity tagging, and embeddings depend on supported languages and assets. An embedding distance is a model-dependent measure, not a calibrated probability. Inspect nil/unknown results instead of assuming English assets are always available.

## Speech

`SFSpeechRecognizer` can require a network service. If the feature requires offline recognition, check `supportsOnDeviceRecognition` and set `requiresOnDeviceRecognition` on the request, then handle unsupported devices/languages. Obtain speech authorization and the relevant microphone permission before live capture. Keep usage-description keys aligned with the actual app path.

Retain the recognition task, stop the engine and remove its tap when finished, call `endAudio()` appropriately, and handle final results/errors/cancellation exactly once. Configure the audio session for the actual app. Don't continuously append buffers after cancellation. For newer `SpeechAnalyzer`/`SpeechTranscriber` integrations, check their available locales, assets, and API availability instead of assuming equivalence with `SFSpeechRecognizer`.

On-device ML does not make an entire app automatically privacy-safe. Actual network calls, analytics, permissions, retention, and training-data collection determine its data flow. Keep this skill's scope to the requested feature.

Official sources: [Core ML](https://developer.apple.com/documentation/coreml), [Create ML](https://developer.apple.com/documentation/createml), [Vision](https://developer.apple.com/documentation/vision), [Natural Language](https://developer.apple.com/documentation/naturallanguage), [Speech](https://developer.apple.com/documentation/speech).
