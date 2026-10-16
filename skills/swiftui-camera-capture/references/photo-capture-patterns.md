# Photo capture and delivery

## Settings and dimensions

Create a new `AVCapturePhotoSettings` for every request. Choose a supported processed codec; test RAW support independently. Check `supportedFlashModes` before requesting a flash mode and distinguish flash from the device's continuous torch.

For iOS 16+, choose output `maxPhotoDimensions` from the active format's `supportedMaxPhotoDimensions`, then select a compatible per-shot `maxPhotoDimensions` no larger than the output's setting. These replace the deprecated high-resolution Boolean flags. Configure the output before running because changing dimensions may rebuild the pipeline. Returned images may be smaller than the chosen maximum; inspect resolved settings when exact dimensions matter.

Set output `maxPhotoQualityPrioritization` before requesting per-shot `.quality`. Choose quality/latency to fit the product instead of always maximizing resolution. Check zero-shutter-lag, responsive-capture, and fast-capture support before enabling those features.

## Rotation and coordinates

On iOS 17+, use `AVCaptureDevice.RotationCoordinator` with the current capture device and visible preview layer. Preview and capture angles serve different purposes. Apply the preview angle to the preview connection and pass the capture angle to the capture owner before a shot, checking `isVideoRotationAngleSupported(_:)` first.

The coordinator publishes rotation changes on the main queue. Recreate it when the active camera changes, retain observation tokens, and pass scalar angle values across the isolation boundary. An external camera's angle can differ from the built-in camera's angle. Hardcoding `90` or mapping `UIDevice.orientation` through an arbitrary connected scene is not a general solution.

For a deployment target below iOS 17, keep an availability-gated legacy `videoOrientation` path where needed. Preserve image orientation metadata when exporting or decoding captured file data.

## Request state and completion

Retain per-request state keyed by `settings.uniqueID` until `photoOutput(_:didFinishCaptureFor:error:)`. For a single-flight design, explicitly reject/disable another request while capture is pending; one mutable delegate property is not sufficient for overlapping captures.

`didFinishProcessingPhoto` produces photo data or a processing error. Store the result there. Deliver the request's final completion once from the terminal callback, preferring the terminal error or earlier processing error over a successful result. Do not complete once on a processing error and then complete again in the terminal callback. Remove the retained processor after completion, including failure paths.

Bracketed, RAW+processed, and Live Photo capture can deliver multiple resources. Preserve those resources separately; do not overwrite them in one `photoData` slot. Live Photo delivery also requires handling the movie result and temporary-file cleanup after saving.

## Deferred processing

Opt into auto-deferred delivery only when supported and when the app implements its Photos save flow. A deferred proxy is not the final high-quality photo, and there is no asynchronous `fileDataRepresentation()` operation that completes its processing in your app.

In `photoOutput(_:didFinishCapturingDeferredPhotoProxy:error:)`, obtain proxy file data and submit it to Photos using a `PHAssetCreationRequest` resource of type `.photoProxy`. Photos finishes processing. This needs the appropriate Photos authorization and usage-description key. Handle proxy errors and terminal capture errors, and do not label a proxy preview as the completed final asset.

## Depth, mattes, and formats

Enable depth or portrait-effects-matte delivery only when supported on the output and requested for the shot. Select semantic segmentation matte types from the output's available list, and inspect the types actually returned. Do not assume all cameras or formats provide skin, hair, teeth, or depth data.

A `CGImage` representation and file data have different metadata behavior. Prefer captured file data when preserving orientation/EXIF is required, and deliberately remove location or other metadata when the requested export should exclude it. Keep the original resources for RAW and Live Photos.

## Saving to Photos

Request add-only access when the feature only saves new captures. Include `NSPhotoLibraryAddUsageDescription`. Use `PHPhotoLibrary.performChanges` and `PHAssetCreationRequest.addResource` for full file data/resources; await completion and report errors before promising a save. A `.photo` resource and a `.photoProxy` resource are not interchangeable.

Sources: [photo output](https://developer.apple.com/documentation/avfoundation/avcapturephotooutput), [maximum photo dimensions](https://developer.apple.com/documentation/avfoundation/avcapturephotooutput/maxphotodimensions), [rotation coordinator](https://developer.apple.com/documentation/avfoundation/avcapturedevice/rotationcoordinator), [deferred proxy](https://developer.apple.com/documentation/avfoundation/avcapturedeferredphotoproxy), [Photos resources](https://developer.apple.com/documentation/photokit/phassetresourcetype).
