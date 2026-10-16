# WidgetKit version 27 adoption

Checked 2026-10-16 against Xcode 27.0 (27A266a), Swift 6.4, and the iOS 27 SDK. Availability below is per API, not the skill name.

This reference covers the requested newer behavior. Ordinary provider, shared-storage, configuration, rendering, and ActivityKit patterns are unchanged foundations; do not migrate every widget merely to use a newer SDK.

## Verified additions

| Symbol | Checked SDK availability |
|---|---|
| `WidgetFamily.systemExtraLargePortrait` | iOS/macOS 27, visionOS 26; unavailable on watchOS/tvOS |
| `EnvironmentValues.isDynamicIslandLimitedInWidth` | iOS 27; unavailable on macOS/watchOS/tvOS/visionOS |
| `supplementalActivityFamilies(_:)` | iOS 18+, **not new in 27** |
| `activityFamily` | iOS 18+, **not new in 27** |
| `WidgetPushHandler` / `pushHandler(_:)` | iOS/macOS/visionOS/watchOS 26+, **not new in 27** |

## Larger portrait widgets

Gate `.systemExtraLargePortrait` when supporting earlier iOS/macOS versions. Build content for its larger area using the actual display size and margins. Don't encode a fixed point-size/device table or assume a specific Home Screen grid arrangement. Verify configuration, empty/stale content, localization, and resizing in the surface the app supports.

## Narrow Dynamic Island layouts

For iOS 27 compact/minimal content, read `isDynamicIslandLimitedInWidth` and switch to an appropriately short glyph/value when space is constrained. Keep the view or property access inside an availability-guarded implementation for older targets. Test landscape and portrait on a device/runtime that exposes the feature, including timer transitions and accessibility. A limited-width environment does not imply a particular hardware model.

## App Intents used by widgets

Inspect App Intents' actual `ExecutionTargets`, `LongRunningIntent`, and `@UnionValue` API when a task requires them; these are framework capabilities, not a blanket widget migration checklist. Routing to the main app does not make an in-memory value persistent or repair an App Group entitlement. Long-running work still needs correct lifecycle, cancellation, and resource behavior.

For Live Activity completion use `Activity.end(_:dismissalPolicy:)`. An app-defined `dismissPolicy:` argument seen in a session sample isn't a new system `IntentResult` signature. Use `LiveActivityIntent` for supported interactive actions.

Treat refresh timing, mirrored surfaces, and visibility as system-managed. Test the actual user configuration; don't promise instantaneous reloads or universal Watch/Mac/CarPlay propagation. Do not claim “no new API anywhere” merely because a feature wasn't mentioned in one presentation.

Official sources: [WidgetFamily.systemExtraLargePortrait](https://developer.apple.com/documentation/widgetkit/widgetfamily/systemextralargeportrait), [isDynamicIslandLimitedInWidth](https://developer.apple.com/documentation/swiftui/environmentvalues/isdynamicislandlimitedinwidth), [WidgetKit](https://developer.apple.com/documentation/widgetkit), [App Intents](https://developer.apple.com/documentation/appintents).
