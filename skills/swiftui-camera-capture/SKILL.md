---
name: swiftui-camera-capture
description: Build or debug custom camera capture in SwiftUI with AVFoundation, including preview bridging, authorization, session lifecycle, rotation, focus, and photo delivery.
license: MIT
---

# SwiftUI Camera Capture

Use this skill for a custom live camera or capture flow. For selecting existing photos, use PhotosUI. A system camera picker may be sufficient for a simple capture task; do not impose an AVFoundation architecture unless custom control is needed.

Preserve the project's deployment target and concurrency settings. The guidance below was reviewed against Xcode 27.0 (27A266a), Swift 6.4, and the iOS 27 SDK on October 16, 2026. APIs described as iOS 16/17 features need availability checks when supporting older systems.

## Choose the relevant guide

- [Session setup](references/avfoundation-setup.md): isolation, authorization, lifecycle, preview connection, focus, switching cameras, and system pressure.
- [Photo capture](references/photo-capture-patterns.md): settings, resolution, rotation, per-request delegates, deferred delivery, and Photos persistence.
- [Troubleshooting](references/troubleshooting.md): diagnose the observed failure and choose representative device checks.

## Working rules

1. Keep blocking session configuration and start/stop work off the main actor, in one serialized ownership domain. An actor or an existing serial-queue design can work. Do not mix uncoordinated tasks and queues around the same session. Keep UIKit/SwiftUI state and preview-layer layout on the main actor.
2. Await authorization before configuring or starting. Preserve cancellation and the current view/scene's intent across that suspension. Do not launch an independent `onAppear` start alongside a permission-requesting `.task`.
3. Make configuration idempotent and rollback partial changes on failure. Do not suspend or call `startRunning()` between `beginConfiguration()` and `commitConfiguration()`.
4. Use fresh photo settings per capture. Retain per-request processing state through the terminal capture callback, handle errors exactly once, and release it afterward.
5. Use the initiating preview and device to derive focus coordinates and rotation. Avoid global first-window selection and hardcoded portrait angles. Update the rotation coordinator after switching cameras.
6. Check device/output capabilities before setting flash, resolution, quality, depth, RAW, or deferred delivery. Match `maxPhotoDimensions` to the active format; the `.photo` preset alone is not a resolution guarantee.
7. Verify real camera behavior on a physical device. A compiler probe, mock, or Simulator placeholder establishes only its own scope.

## Sources

- [AVCam sample and architecture](https://developer.apple.com/documentation/avfoundation/avcam-building-a-camera-app)
- [Capture session](https://developer.apple.com/documentation/avfoundation/avcapturesession)
- [Photo output](https://developer.apple.com/documentation/avfoundation/avcapturephotooutput)
