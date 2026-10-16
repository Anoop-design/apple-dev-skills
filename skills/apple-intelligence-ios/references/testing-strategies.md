# System AI UI verification

Checked 2026-10-16 against Xcode 27.0 (27A266a), Swift 6.4, and the iOS 27 SDK. Availability below is per API, not the skill name.

Verify the requested integration on a supported device with the feature enabled and on an unavailable configuration. API availability, device eligibility, language, region, settings, and downloaded assets are separate conditions; query the framework rather than hardcoding model names.

For Image Playground, test presentation, cancellation, completion, file-copy failure, and reopening a saved image. A temporary completion URL is not durable storage. Test supported styles/options with the shipped SDK. The iOS 27 SDK deprecates programmatic `ImageCreator` generation; test migrations through the system sheet/controller when that is the requested change.

For Writing Tools, test accepting/rejecting replacements, undo/redo, selection preservation, app autosave, and incoming sync edits. A UI that looks correct while the text model loses data is not complete. Standard controls should retain their built-in accessibility and edit behavior.

For adaptive image glyphs, round-trip through the app's real document or database format, paste/copy, and sync if affected. Check alternate descriptions with VoiceOver and the behavior of plain-text export.

Simulator support depends on runtime and host configuration. Use deterministic UI tests for your own state transitions and a supported physical-device check for actual system generation; don't claim runtime verification from a compiler probe.

Official sources: [Image Playground](https://developer.apple.com/documentation/imageplayground), [Writing Tools](https://developer.apple.com/documentation/uikit/writing-tools), [Apple Intelligence requirements](https://support.apple.com/en-us/121115).
