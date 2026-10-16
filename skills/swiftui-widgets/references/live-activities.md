# Live Activities and Dynamic Island

Checked 2026-10-16 against Xcode 27.0 (27A266a), Swift 6.4, and the iOS 27 SDK. Availability below is per API, not the skill name.

Live Activities use ActivityKit state and WidgetKit presentation for an ongoing event. They don't grant unlimited background execution or network access to the widget's view. Check `ActivityAuthorizationInfo().areActivitiesEnabled`, configure `NSSupportsLiveActivities`, and include the attributes type in the required app/extension targets.

Separate static `ActivityAttributes` from `ContentState: Codable, Hashable`. Keep content compact; avoid embedded images and large model payloads. Verify current platform/system limits for the activity type instead of relying on a refresh budget to sustain a permanent dashboard.

```swift
import ActivityKit

struct DeliveryAttributes: ActivityAttributes {
    let orderID: String
    struct ContentState: Codable, Hashable {
        var status: String
        var estimatedArrival: Date
    }
}

@available(iOS 16.2, *)
func startDelivery(orderID: String) throws -> Activity<DeliveryAttributes>? {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return nil }
    let eta = Date().addingTimeInterval(1800)
    return try Activity.request(
        attributes: DeliveryAttributes(orderID: orderID),
        content: ActivityContent(
            state: .init(status: "Preparing", estimatedArrival: eta),
            staleDate: Date().addingTimeInterval(900)),
        pushType: nil)
}

@available(iOS 16.2, *)
func finishDelivery(_ activity: Activity<DeliveryAttributes>) async {
    let final = DeliveryAttributes.ContentState(status: "Delivered", estimatedArrival: .now)
    await activity.end(ActivityContent(state: final, staleDate: nil),
                       dismissalPolicy: .default)
}
```

These use the `ActivityContent` overloads introduced in iOS 16.2. Live Activities and remote updates existed in iOS 16.1; don't confuse a newer overload with the feature's introduction. Explicitly end completed activities and manage the tasks that observe state/token streams.

## Presentation and interaction

`ActivityConfiguration` provides Lock Screen/banner content and Dynamic Island expanded, compact-leading, compact-trailing, and minimal views. Keep compact content short; apply tabular digits and a realistic stable timer width. Use `context.isStale` to convey old information when appropriate. A stale date marks freshness; it doesn't schedule a network request.

From iOS 17, supported Live Activity surfaces can contain `Button`/`Toggle` actions using `LiveActivityIntent`. The old blanket claim that Live Activities cannot be interactive is incorrect. Match actual supported presentation and execution behavior. End an activity with `activity.end(...dismissalPolicy:)`; an app sample's `dismissPolicy` parameter isn't a new `IntentResult` API.

An iPhone Live Activity may be mirrored to supported Apple Watch, Mac, or CarPlay surfaces depending on OS/device settings. That does not imply native ActivityKit is generally available on those platforms or guarantee propagation to every device. `.supplementalActivityFamilies([.small])` (iOS 18+) lets the iPhone extension supply a compact layout; branch on `activityFamily` where appropriate.

## Remote updates

Use `.token` when server updates are part of the design. Observe token changes, update the server registration, and stop sending to invalid/ended activities. Do not log full tokens in ordinary production logs.

APNs activity updates use `apns-push-type: liveactivity` and the corresponding bundle topic. Payload fields include a current UNIX `timestamp`, `event`, and a `content-state` that matches the exact Codable schema. **Dates inside content-state must match your Swift decoding strategy**; default Codable `Date` seconds use the reference date, while APNs envelope timestamps use UNIX time. Don't paste the same integer into both blindly. Test JSON decoding before sending a push.

Push-to-start, activity update tokens, and broadcast channels are distinct mechanisms with different availability and setup. Use current Apple documentation for the requested one; avoid guessing channel constructors, quotas, or entitlements. Delivery and update timing remain system-controlled.

Official sources: [Displaying live data with Live Activities](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities), [Starting and updating Live Activities with ActivityKit push notifications](https://developer.apple.com/documentation/activitykit/starting-and-updating-live-activities-with-activitykit-push-notifications), [Adding interactivity](https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities), [ActivityKit](https://developer.apple.com/documentation/activitykit).
