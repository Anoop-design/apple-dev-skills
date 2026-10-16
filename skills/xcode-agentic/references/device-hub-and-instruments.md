# Devices, profiling, previews, and CI

Checked 2026-10-16 against Xcode 27.0 (27A266a), Swift 6.4, and the iOS 27 SDK. Availability below is per API, not the skill name.

Use the installed tool's help and the actual available destinations. Xcode 27 introduces Device Hub, but automation support differs between physical devices, simulators, and connected tool versions. Don't infer a command's arguments from its UI name.

```sh
xcrun devicectl --help
xcrun simctl help
xcrun xctrace help
```

`devicectl` documents versioned JSON output for automation; its human-readable output is not a stable parsing API. Inspect the particular subcommand before choosing devices, installing, launching, copying files, or changing settings. Use explicit destination identifiers from a current inventory.

## Profiling

Instruments can be used through its UI **or** `xcrun xctrace` for supported capture/export workflows. Don't claim profiling must always be handed back to a developer. Discover available templates/instruments and choose those relevant to the symptom: CPU work, SwiftUI updates, hitches, memory, concurrency, or model inference.

Record a representative scenario and compare the same workload after a fix. Processor trace availability and overhead depend on hardware and configuration; don't promise a universal one-percent overhead or instruction coverage. Keep traces and exported results scoped to the task and avoid exposing private app data.

## Previews and real execution

Use a preview for layout feedback. Device/simulator execution establishes interaction and lifecycle behavior that previews cannot. A successful render does not establish all Dynamic Type, orientation, localization, or widget states; verify the states affected by the change.

## CI

Use the project's normal `xcodebuild` or SwiftPM commands, selected Xcode, available SDKs, signing setup, and destination. `mcpbridge` is a bridge to a running IDE service, so it isn't a substitute for a configured headless build runner. A cloud CI service is optional; do not configure one merely because it is mentioned here.

Do not promise fixed build-speed improvements, a particular future Swift feature, or a global build-engine migration based on a marketing summary. Check actual compiler flags and the project's supported toolchain before changing them.

Official sources: [Xcode 27 release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes), [Instruments](https://developer.apple.com/documentation/xcode/improving-your-app-s-performance), [Xcode Cloud](https://developer.apple.com/xcode-cloud/), and the installed CLI help.
