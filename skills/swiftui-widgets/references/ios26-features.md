# Version 26 widget capabilities

Checked 2026-10-16 against Xcode 27.0 (27A266a), Swift 6.4, and the iOS 27 SDK. Availability below is per API, not the skill name.

## WidgetKit push notifications

Widget pushes supplement timelines. They are **budgeted and opportunistic**, not unlimited real-time refreshes or a guarantee of simultaneous cross-device updates. `WidgetPushHandler` receives token/configuration changes; it does **not** define `handlePush(for:)`.

```swift
import WidgetKit

@available(iOS 26.0, macOS 26.0, *)
struct WidgetTokenHandler: WidgetPushHandler {
    func pushTokenDidChange(_ pushInfo: WidgetPushInfo, widgets: [WidgetInfo]) {
        // Persist/forward pushInfo.token and widget subscriptions to the app's server.
        // Use the app's existing bounded, authenticated registration workflow.
    }
}
```

Register with `.pushHandler(WidgetTokenHandler.self)` on the widget configuration. Implement the app-owned registration work before shipping; the skeleton above intentionally has no server endpoint. The system reloads timelines when an accepted push arrives, so fetching belongs in the provider's data path.

Use the documented Push Notifications capabilities and server setup. APNs needs `apns-push-type: widgets`, topic `<bundleID>.push-type.widgets`, and payload `{"aps":{"content-changed":true}}`. A standard background `content-available` payload is not the widget payload. Widget pushes do not use ActivityKit broadcast channels. [Apple's push guide](https://developer.apple.com/documentation/widgetkit/updating-widgets-with-widgetkit-push-notifications) defines the complete setup.

## Appearance and additional surfaces

Accented/tinted rendering existed before version 26. Read `widgetRenderingMode` to adapt foreground groups/images; don't equate `.accented` exclusively with glass. Standard background semantics let the system adapt to clear and other appearances.

CarPlay uses supported small-widget content. Verify background removal, quick readability, actual available interaction, and the relevant host/device settings. Adding `.supplementalActivityFamilies([.small])` is a Live Activity presentation choice, not a guarantee that a widget or activity appears in every car.

For visionOS widgets, inspect `supportedMountingStyles`, `widgetTexture`, and `levelOfDetail` availability and cases. Keep spatial code behind platform/runtime guards as needed. Use the actual enum values; don't invent a `.canvas` texture or `.full` level-of-detail case. A family or modifier being declared on iOS may enable configuration for mirroring rather than a spatial iPhone rendering surface.

## watchOS relevance

The actual `RelevanceEntriesProvider` requires `placeholder(context:)`, `entry(configuration:context:)`, and `relevance()`. `RelevanceEntry` is a protocol, not a generic initializer taking an arbitrary entry and location. Use `WidgetRelevance` and the documented relevance-context APIs. They supply hints; they do not force immediate display whenever a condition matches.

Official sources: [WidgetPushHandler](https://developer.apple.com/documentation/widgetkit/widgetpushhandler), [Preparing widgets for additional platforms](https://developer.apple.com/documentation/widgetkit/preparing-widgets-for-additional-platforms-contexts-and-appearances), [Increasing visibility in Smart Stacks](https://developer.apple.com/documentation/widgetkit/widget-suggestions-in-smart-stacks), [RelevanceEntriesProvider](https://developer.apple.com/documentation/widgetkit/relevanceentriesprovider).
