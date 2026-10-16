# Timelines, configuration, and shared data

Checked 2026-10-16 against Xcode 27.0 (27A266a), Swift 6.4, and the iOS 27 SDK. Availability below is per API, not the skill name.

`TimelineEntry` holds renderable data and a date. `TimelineProvider` supplies a fast placeholder, a snapshot (used for more than gallery previews), and a timeline. Call completion once on every success/failure path. Use last-known or explicit empty data when a fetch fails; don't leave a completion hanging.

```swift
import WidgetKit
import SwiftUI

struct CountEntry: TimelineEntry {
    let date: Date
    let value: Int
}

struct CountProvider: TimelineProvider {
    func placeholder(in context: Context) -> CountEntry {
        CountEntry(date: .now, value: 0)
    }
    func getSnapshot(in context: Context, completion: @escaping (CountEntry) -> Void) {
        completion(CountEntry(date: .now, value: 42))
    }
    func getTimeline(in context: Context,
                     completion: @escaping (Timeline<CountEntry>) -> Void) {
        let now = Date()
        let entry = CountEntry(date: now, value: 42) // Replace with persisted app data.
        completion(Timeline(entries: [entry],
                            policy: .after(now.addingTimeInterval(3600))))
    }
}

@available(iOS 17.0, macOS 14.0, *)
struct CountWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CountWidget", provider: CountProvider()) { entry in
            VStack(alignment: .leading) {
                Text("Count").font(.headline)
                Text(entry.value, format: .number)
                    .font(.title).monospacedDigit()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Count")
        .description("Shows the saved count.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
```

Add the widget to the project's existing `WidgetBundle`. Don't add a second `@main` to a target that already has one.

## Reloads

`.atEnd` requests a new timeline after the final entry; `.after(date)` specifies an earliest reload date; `.never` leaves refresh requests to other triggers. Neither timeline entries nor refresh policies promise an exact execution time. WidgetKit allocates a dynamic per-instance budget. Apple's typical 40–70 daily refreshes for frequently viewed widgets is an example, not a guaranteed allowance.

After committing shared data, request `WidgetCenter.shared.reloadTimelines(ofKind:)` for the affected kind. Foreground-app and intent-triggered reloads have special budgeting behavior, but a manual reload isn't universally unbudgeted or immediate. Use system timer text for ticking displays instead of minute/second timeline reloads.

## Configuration and actions

On iOS 17+, pair `WidgetConfigurationIntent` with `AppIntentTimelineProvider` and `AppIntentConfiguration`. Use the supplied configuration in snapshot/timeline methods. Resolve missing/deleted entities explicitly, and ensure query implementations can run in their actual process.

`Button(intent:)` and `Toggle(isOn:intent:)` support actions on compatible widgets and Live Activities; ordinary gesture/state handlers don't execute as normal app UI. `Link` and `widgetURL` navigate to the app. Small widgets may contain intent buttons; the default whole-widget link doesn't mean every small widget is restricted to one interaction.

Commit the operation before the intent returns so the subsequent reload reads the new value. A read-increment-write sequence in shared `UserDefaults` can lose concurrent writes across app and extension; use appropriate transactional storage for counters or other contested mutations. Don't assume changing an execution target repairs persistence bugs.

## Shared storage and links

App and extension need the same App Group entitlement for shared defaults/files. Validate group access; avoid force-unwrapping a missing container. Write complete files atomically or use a store designed for concurrent readers/writers. Keep widget-facing snapshots small, and don't copy credentials into display data.

Use `widgetURL` for default navigation and `Link` for supported additional destinations. Parse incoming URLs safely in the app and revalidate current access to the entity. A deep link shouldn't perform an unconfirmed destructive action.

Official sources: [Keeping a widget up to date](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date), [Timeline](https://developer.apple.com/documentation/widgetkit/timeline), [Adding interactivity to widgets and Live Activities](https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities), [Making a configurable widget](https://developer.apple.com/documentation/widgetkit/making-a-configurable-widget).
