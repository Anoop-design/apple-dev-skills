# Workouts: Builders, Live Sessions, Mirroring & Zones

The full workout story: off-session building, the watchOS/iPhone live flow, mirroring between devices, the iOS 27 workout-zones API, and how WorkoutKit relates. Always use the builders — the `HKWorkout(...)` initializers are deprecated; use the builders for new code.

## Table of Contents
- [HKWorkoutBuilder (off-session)](#hkworkoutbuilder-off-session)
- [HKWorkoutRouteBuilder](#hkworkoutroutebuilder)
- [Multi-activity workouts](#multi-activity-workouts)
- [HKWorkoutConfiguration](#hkworkoutconfiguration)
- [The watchOS live flow](#the-watchos-live-flow)
- [Session lifecycle and delegate](#session-lifecycle-and-delegate)
- [iPhone workouts and crash recovery](#iphone-workouts-and-crash-recovery)
- [Mirroring between Watch and iPhone](#mirroring-between-watch-and-iphone)
- [Workout zones (iOS 27, new)](#workout-zones-ios-27-new)
- [WorkoutKit (planned workouts)](#workoutkit-planned-workouts)

## HKWorkoutBuilder (off-session)

For building a workout incrementally without a live session — importing third-party/GPX data, or summarizing an iPhone-tracked activity:
```swift
let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
try await builder.beginCollection(at: start)
try await builder.addSamples([energySample])        // quantity samples
try await builder.addWorkoutEvents([pauseEvent])    // pauses, markers, segments
try await builder.addMetadata([HKMetadataKeyIndoorWorkout: true])
try await builder.endCollection(at: end)
let workout = try await builder.finishWorkout()
```

## HKWorkoutRouteBuilder

Records GPS as an `HKWorkoutRoute` series tied to the workout:
```swift
guard let routeBuilder = builder.seriesBuilder(for: .workoutRoute())
    as? HKWorkoutRouteBuilder else { return }
try await routeBuilder.insertRouteData(locations) // before finishing the workout
// For a route builder obtained from a workout builder, finishing the workout
// also saves the route. Do not call finishRoute(with:) on this attached builder.
let workout = try await builder.finishWorkout()
```
For a separately constructed `HKWorkoutRouteBuilder`, finish the saved route with a non-nil saved `HKWorkout`. Request route and location permissions, collect useful route points, and validate display on a physical device.

## Multi-activity workouts

`HKWorkoutActivity` models multi-sport/interval sessions (triathlon, circuit):
- Off-session: create `HKWorkoutActivity(workoutConfiguration:start:end:metadata:)` and `addWorkoutActivity(_:)`.
- Live on Watch: `session.beginNewActivity(configuration:date:metadata:)` / `session.endCurrentActivity(on:)`; delegate fires `didBeginActivityWith:`/`didEndActivityWith:`.

## HKWorkoutConfiguration

```swift
let config = HKWorkoutConfiguration()
config.activityType = .running                 // HKWorkoutActivityType
config.locationType = .outdoor                 // .indoor / .outdoor / .unknown
// swimming adds:
config.swimmingLocationType = .pool
config.lapLength = HKQuantity(unit: .meter(), doubleValue: 25)
```

## The watchOS live flow

The canonical live workout on Apple Watch:
```swift
let session = try HKWorkoutSession(healthStore: store, configuration: config)
let builder = session.associatedWorkoutBuilder()
builder.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: config)
session.delegate = self
builder.delegate = self

let start = Date()
session.startActivity(with: start)
try await builder.beginCollection(at: start)
```
`HKLiveWorkoutDataSource` auto-collects the "generated" types for the activity (heart rate, active energy, distance). The builder delegate `workoutBuilder(_:didCollectDataOf:)` fires as new statistics arrive — read them with `builder.statistics(for:)`.

**End sequence (order matters):**
```swift
session.stopActivity(with: Date())
// In the delegate when state becomes .stopped, use its transition date:
try await builder.endCollection(at: transitionDate)
let workout = try await builder.finishWorkout()
session.end()
```

## Session lifecycle and delegate

`HKWorkoutSessionState` raw values: `.notStarted` (1), `.running` (2), `.ended` (3, **terminal — cannot restart**), `.paused` (4), `.prepared` (5, sensors warm but activity not started), `.stopped` (6, transient before finishing). Methods: `prepare()`, `startActivity(with:)`, `pause()`/`resume()`, `stopActivity(with:)`, `end()`.

`HKWorkoutSessionDelegate` — two **required** methods:
- `workoutSession(_:didChangeTo:from:date:)`
- `workoutSession(_:didFailWithError:)` — when an error drives a transition, this fires **before** the state-change callback.

Optional: `workoutSession(_:didGenerate:)` (events), `didBeginActivityWith:`/`didEndActivityWith:` (multi-activity), `didReceiveDataFromRemoteWorkoutSession:` (mirroring). **Delegate callbacks arrive on an anonymous background queue — marshal UI/state updates to `@MainActor`.**

## iPhone workouts and crash recovery

From iOS/iPadOS 26 (WWDC25 session 322), `HKWorkoutSession` + `HKLiveWorkoutBuilder` + `HKLiveWorkoutDataSource` run on **iPhone/iPad** — the same Watch code with minimal change. iPhone has **no heart-rate sensor**, so pair an external HR monitor for that metric.

**Crash recovery** uses a scene-connection flow:
```swift
// in application(_:configurationForConnecting:options:)
if options.shouldHandleActiveWorkoutRecovery {
    store.recoverActiveWorkoutSession { session, error in
        // rebuild only the data source on the recovered session
    }
}
```
The recovery property and API require iOS 26. Reattach the recovered session and builder delegates, restore the UI, and reconcile saved state; do not start a second session. See [building a workout app for iPhone and iPad](https://developer.apple.com/videos/play/wwdc2025/322/).

## Mirroring between Watch and iPhone

watchOS 10 / iOS 17+. The **Watch is primary** (it has the sensors); the iPhone session is **mirrored**:
- On Watch: `session.startMirroringToCompanionDevice()`.
- iPhone app is launched and notified via `HKHealthStore.workoutSessionMirroringStartHandler`.
- Exchange data: `sendToRemoteWorkoutSession(data:)`; receive via the delegate's `didReceiveDataFromRemoteWorkoutSession`.

Use mirroring for an active workout and attach delegates before exchanging data. Handle errors and disconnection, bound any retry loop, and keep UI responsive while awaiting sends. WatchConnectivity can still serve unrelated app synchronization.

## Workout zones (iOS 27, new)

An iOS 27 HealthKit addition (session 207). Heart-rate and cycling-power zones are first-class.

**Post-workout (read):**
```swift
let groups = workout.zoneGroupsByType?[HKQuantityType(.heartRate)]
// each group exposes its configuration (boundaries) and per-zone durations
```

**Live (during a session):** implement the new `HKLiveWorkoutBuilderDelegate` method:
```swift
func workoutBuilder(_ builder: HKLiveWorkoutBuilder,
                    didUpdateWorkoutZone update: HKLiveWorkoutZoneUpdate) {
    // the user just transitioned zones — update coaching UI
}
```

**Configuration:** either rely on HealthKit's **preferred zones** (computed from the user's metrics in Health Settings and synced across devices — await `try await builder.zoneConfiguration(for:)`) or supply a **custom `HKWorkoutZoneConfiguration`**. Per session 207: **3–9 zones are required**, the zone boundary units must match and be compatible with the configuration's quantity type, and **custom zones must be added to the builder before calling `beginCollection`**.

## WorkoutKit (planned workouts)

A **separate framework** for *creating/scheduling* planned workouts that appear in the Apple Watch Workout app — distinct from HealthKit, which *records* what happened.
- `CustomWorkout` with `IntervalBlock`/`IntervalStep` (`.warmup`/`.work`/`.recovery`/`.cooldown`), goals (energy/time/distance), and alerts (`HeartRateRangeAlert`, `PaceRangeAlert`, `PowerRangeAlert`, `CadenceRangeAlert`).
- `WorkoutPlan` wraps a composition; `WorkoutScheduler` (after `requestAuthorization`) syncs scheduled workouts to the Watch, branded with your app's icon.
- `presentPreview()` shows an "Add to Watch" sheet on iOS / launches the Workout app on watchOS.
Remember: **WorkoutKit plans it, HealthKit records it.** The iOS 27 workout-zones API is HealthKit, not WorkoutKit. Check the supported alert and scheduling behavior for the target watchOS release.

Reviewed 2026-10-16 with Xcode 27.0 / iOS 27.0 SDK. Primary reference: [Workout route builder](https://developer.apple.com/documentation/healthkit/hkworkoutroutebuilder). Availability and runtime behavior must be checked for the app’s actual platforms.
