# Reading Health Data

Every way to read from HealthKit, weighted toward the modern async/await query descriptors (the recommended style for new code). The legacy `HK*Query` classes still work and are noted for context.

## Table of Contents
- [Modern descriptors vs legacy queries](#modern-descriptors-vs-legacy-queries)
- [Predicates and sorting](#predicates-and-sorting)
- [Sample queries](#sample-queries)
- [Statistics (cumulative vs discrete)](#statistics-cumulative-vs-discrete)
- [Statistics collections (charts)](#statistics-collections-charts)
- [Anchored queries (sync)](#anchored-queries-sync)
- [Observer queries and background delivery](#observer-queries-and-background-delivery)
- [Workout routes and Activity Rings](#workout-routes-and-activity-rings)
- [Performance](#performance)

## Modern descriptors vs legacy queries

Use **descriptors** (iOS 15.4+) for all new code — they're async/await-native and composable:
`HKSampleQueryDescriptor`, `HKStatisticsQueryDescriptor`, `HKStatisticsCollectionQueryDescriptor`, `HKAnchoredObjectQueryDescriptor`, `HKQuantitySeriesSampleQueryDescriptor`, `HKWorkoutRouteQueryDescriptor`, `HKHeartbeatSeriesQueryDescriptor`, `HKActivitySummaryQueryDescriptor`, `HKSourceQueryDescriptor`. Descriptors conform to the relevant async query protocol: some expose `result(for:)`, some stream `results(for:)`, and some support both. Check each descriptor; for example, a sample query is one-shot and an anchored query can stream changes.

The **legacy classes** still ship and remain valid: `HKSampleQuery`, `HKStatisticsQuery`, `HKStatisticsCollectionQuery`, `HKAnchoredObjectQuery`, `HKObserverQuery`, `HKActivitySummaryQuery`, `HKSourceQuery`, `HKWorkoutRouteQuery`. Reserve `HKObserverQuery` for background delivery (no descriptor equivalent for that role).

## Predicates and sorting

```swift
let predicate = HKQuery.predicateForSamples(withStart: start, end: end,
                                            options: [.strictStartDate])
// source filtering:
let fromApp = HKQuery.predicateForObjects(from: [sourceRevision])
```
For descriptors, wrap in a typed predicate, e.g. `HKSamplePredicate.quantitySample(type:predicate:)`. Sort with `SortDescriptor(\HKSample.startDate)` (descriptors) or `HKSortIdentifierStartDate`/`endDate` (legacy).

## Sample queries

Raw samples with a predicate, sort, and limit:
```swift
let descriptor = HKSampleQueryDescriptor(
    predicates: [.quantitySample(type: HKQuantityType(.heartRate), predicate: predicate)],
    sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)],
    limit: 100)
let samples = try await descriptor.result(for: store)
for s in samples {
    let bpm = s.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
}
```

## Statistics (cumulative vs discrete)

Pick the statistics option that matches the type — using the wrong one throws:
- **Cumulative** (step count, active/basal energy, distance): `.cumulativeSum` → read `sumQuantity()`.
- **Discrete** (heart rate, body mass, VO2 max): `.discreteAverage` / `.discreteMin` / `.discreteMax` / `.mostRecent` → read `averageQuantity()` etc.

```swift
let stats = try await HKStatisticsQueryDescriptor(
    predicate: .quantitySample(type: HKQuantityType(.stepCount), predicate: predicate),
    options: .cumulativeSum).result(for: store)
let steps = stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0
```
Add `.separateBySource` to break results out per writing app/device.

## Statistics collections (charts)

The workhorse for time-series UI — repeated aggregates over fixed intervals anchored to a date:
```swift
let daily = DateComponents(day: 1)
let anchor = Calendar.current.startOfDay(for: .now)
let descriptor = HKStatisticsCollectionQueryDescriptor(
    predicate: .quantitySample(type: HKQuantityType(.stepCount), predicate: predicate),
    options: .cumulativeSum,
    anchorDate: anchor,
    intervalComponents: daily)
let collection = try await descriptor.result(for: store)
collection.enumerateStatistics(from: start, to: .now) { stat, _ in
    let value = stat.sumQuantity()?.doubleValue(for: .count()) ?? 0
    // append to chart data
}
```
For live-updating charts use `results(for:)` and consume the `AsyncSequence`.

## Anchored queries (sync)

For incremental sync — fetch only what's new/deleted since last time:
```swift
var anchor: HKQueryAnchor? = loadSavedAnchor()
let descriptor = HKAnchoredObjectQueryDescriptor(
    predicates: [.sample(type: HKQuantityType(.bodyMass), predicate: nil)],
    anchor: anchor)
let result = try await descriptor.result(for: store)
process(added: result.addedSamples, deleted: result.deletedObjects)
save(result.newAnchor)   // Persist only after durably applying both additions and deletions.
```
**Persist the anchor with the associated local data and query definition.** Reset it when the local cache or predicate changes; saving a new anchor before committing samples/deletions can permanently skip updates after a crash. Use `results(for:)` for a long-running stream of updates.

## Observer queries and background delivery

To wake your app when data changes (the only path for background updates):
```swift
let query = HKObserverQuery(sampleType: HKQuantityType(.stepCount), predicate: nil) {
    _, completionHandler, error in
    // fetch new data (e.g., run an anchored query), then:
    completionHandler()   // REQUIRED — or iOS throttles future deliveries
}
store.execute(query)
store.enableBackgroundDelivery(for: HKQuantityType(.stepCount), frequency: .immediate) { _, _ in }
```
- Hold the **background-delivery entitlement**.
- **Re-register `enableBackgroundDelivery` on every launch** (in the launch path).
- **Always call the completion handler** in the observer block.
- Background delivery must be tested on a physical device. A foreground observer query and background wake-up are different behaviors; delivery frequency is a hint, not a real-time guarantee. Fetch changes on foreground as well.

## Workout routes and Activity Rings

- **Routes:** read an `HKWorkoutRoute` series with `HKWorkoutRouteQueryDescriptor`, which streams `[CLLocation]`. (Building routes → `references/workouts.md`.)
- **Activity Rings:** `HKActivitySummaryQueryDescriptor` returns `HKActivitySummary` (active energy, exercise minutes, stand hours); render with `HKActivityRingView` (HealthKitUI) via `setActivitySummary(_:animated:)`.

## Performance

- Prefer **statistics collection** descriptors over fetching raw samples when you only need aggregates — far less data.
- **Bound predicates by date**; don't fetch unbounded history.
- Use **anchored queries** for sync, with persisted anchors.
- Async descriptors can be awaited from a main-actor model without blocking UI. Move expensive synchronous processing off the main actor; use `async let` only for independent fetches.

Reviewed 2026-10-16 with Xcode 27.0 / iOS 27.0 SDK. Primary reference: [Reading HealthKit data](https://developer.apple.com/documentation/healthkit/reading-data-from-healthkit). Availability and runtime behavior must be checked for the app’s actual platforms.
