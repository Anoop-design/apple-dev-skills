# Session setup and ownership

## Isolation and lifecycle

A camera pipeline has a session owner, a main-actor presentation model, and a preview surface. `startRunning()` and configuration can block. Apple's AVCam sample uses an actor to isolate capture operations from UI work. An existing serial dispatch queue is also valid if every session-graph mutation and start/stop operation uses it consistently.

An actor serializes synchronous access, but an `await` allows reentrancy. Do not suspend inside a begin/commit configuration transaction. Avoid detached tasks that can start or stop the session concurrently with configuration. Publish value results such as `Data`, status, and error descriptions to the main actor. `@Observable` by itself does not provide main-actor isolation. Do not add `@unchecked Sendable` solely to silence diagnostics.

A preview must connect to the session through a deliberately designed boundary. Follow AVCam's capture-source/preview architecture for the SDK in use; do not casually expose all mutable AVFoundation state across actors. UIKit layout and preview-layer geometry belong on the main actor.

## Authorization and start order

Add `NSCameraUsageDescription` before camera access. Missing required usage descriptions can terminate the app. Request microphone authorization and `NSMicrophoneUsageDescription` only when recording audio. Saving to Photos has a separate authorization/usage-description path.

The lifecycle sequence is: inspect/request authorization, recheck cancellation and whether capture is still wanted, configure if needed, then start. Stop when the active feature no longer owns the capture session. Coordinate rapid disappear/reappear events so a stale task cannot start after navigation or stop a newer session. Use the existing coordinator's generation/token or state-machine approach instead of forcing view identity changes.

Handle `.authorized`, `.notDetermined`, `.denied`, and `.restricted` separately. A restriction may be managed by the system and may not be resolvable in Settings. Repeated permission requests do not override denial.

## Configure atomically

1. Discover a supported device. Prefer a device type appropriate for the requested feature rather than assuming every device has a triple camera.
2. Create the input and check session preset/input/output support.
3. Call `beginConfiguration()`, make graph changes, and guarantee `commitConfiguration()` with `defer`.
4. If adding an output fails after adding an input, remove that input or otherwise restore the last valid graph. Set a configured flag only after success.
5. Choose supported photo dimensions and feature flags before starting. `maxPhotoQualityPrioritization` must permit the per-shot setting.

For switching cameras, retain the old input until a replacement is available, restore it if the new graph cannot be committed, then update controls, dimensions, and rotation tracking for the new active device. Multi-camera capture requires `AVCaptureMultiCamSession` support, explicit connections, and attention to hardware/system-pressure costs; it is a separate feature, not a default setup.

## Preview layout

A `UIView` whose backing layer is an `AVCaptureVideoPreviewLayer` naturally follows the view's bounds:

```swift
@MainActor
final class CameraPreviewSurface: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
```

Use `UIViewRepresentable` to host it. A separately added sublayer also works if its frame is updated in layout. Keep coordinator callbacks current in `updateUIView`; a coordinator retaining the initial representable value can otherwise invoke stale closures. Decide `.resizeAspect` versus `.resizeAspectFill` deliberately and account for cropping during tap-to-focus conversion.

## Device controls

Read device/output state and apply controls in the capture owner's isolation domain. Acquire `lockForConfiguration()` with `try`, and use `defer` to unlock. Check both the point-of-interest support flag and the desired focus/exposure mode. A supported focus point does not imply every focus mode is supported.

Convert taps with the actual preview layer's `captureDevicePointConverted(fromLayerPoint:)` on the UI side, then pass the resulting point to the capture owner. Clamp zoom to the current device's `minAvailableVideoZoomFactor` and `maxAvailableVideoZoomFactor`; do not assume the minimum is 1.0. Use supported frame-duration ranges when selecting a format or reducing load.

## Interruptions and pressure

Observe session interruption, interruption-ended, runtime-error, and running-state changes. On interruption end, verify whether capture is still requested, whether the app may capture, and whether the session is running before deciding to restart. Do not promise automatic recovery for every interruption.

Observe `AVCaptureDevice.systemPressureState` with KVO. `subjectAreaDidChangeNotification` reports subject-area changes and is not a pressure notification. Retain/invalidate observation tokens and move reactions onto the capture owner. Under pressure, reduce supported frame rate or processing load rather than continuously trying to restart a shut-down session.

Shutdown should run asynchronously on the owner without blocking the main actor or synchronously dispatching onto a queue already executing the caller. Remove observers and release completed capture state. Strong captures in finite queue operations are not inherently memory leaks; look for actual ownership cycles or operations that never finish.

Sources: [AVCam](https://developer.apple.com/documentation/avfoundation/avcam-building-a-camera-app), [AVCaptureSession](https://developer.apple.com/documentation/avfoundation/avcapturesession), [system pressure](https://developer.apple.com/documentation/avfoundation/avcapturedevice/systempressurestate-swift.class).
