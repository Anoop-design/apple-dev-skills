---
name: healthkit
description: "Implement or debug HealthKit authorization, queries, background delivery, samples, workout builders and sessions, routes, mirroring, workout zones, and specialized health data. Use for integration with Apple Health and relevant privacy or review requirements; a generic fitness UI without HealthKit does not require this skill."
license: MIT
---

# HealthKit (iOS 27 / watchOS 27 / WWDC 2026)

Reviewed 2026-10-16 against Xcode 27.0 (27A266a), Swift 6.4, and the iOS 27.0 SDK. Check the target platform and deployment version for each API; newer SDK availability does not imply that a consumer service is enabled for every account or region. Code using app stores, routers, or model types is an integration sketch; supply those app-specific dependencies.

HealthKit is the on-device, OS-managed, encrypted store for health and fitness data, accessed through `HKHealthStore`. This skill covers the full picture: authorization, the type system, reading, writing, workouts (off-session and live), watchOS/iPhone live sessions and mirroring, the specialized data domains (mood, medications, sleep, clinical/FHIR), WorkoutKit, and compliance. The core API is stable in iOS/watchOS 27; this guide includes the iOS 27 workout-zones APIs (session 207).

## Five guardrails — get these wrong and the app breaks or gets rejected

These are the HealthKit mistakes that cause real harm. Apply them on every HealthKit task:

1. **You can NEVER detect denied READ access.** `authorizationStatus(for:)` reports write status only; for reads, a denial is deliberately indistinguishable from "no data" (queries don’t reveal denied data, though the app’s own samples may remain readable). So **never gate UI on read permission, never persist your own "has permission" flag, and always handle empty results gracefully.** Treat read results as data, not as a permission-status test.
2. **Always build workouts with the builders.** The `HKWorkout(activityType:start:end:…)` initializers are **deprecated**; use the builders to associate samples and statistics correctly. Use `HKWorkoutBuilder` (off-session) or `HKWorkoutSession` + `HKLiveWorkoutBuilder` (live).
3. **Respect App Review Guideline 5.1.3.** Health data must **not** be used for advertising, marketing, or use-based data mining, or sold to data brokers; you must **not** write false/inaccurate data; **do not upload personal health information to your app’s iCloud storage**; a privacy policy is mandatory.
4. **Request the minimum, contextually.** Ask only for the types a feature needs, when it needs them — not everything upfront. Over-requesting triggers reviewer scrutiny and user distrust.
5. **Test on a real device.** Use seeded Simulator data for query and UI development. Verify background delivery, sensors, live sessions, and Fitness integration on appropriate physical devices.

## What's new in iOS 27 / watchOS 27 (and what isn't)

- **Workout zones (new, session 207)** — an iOS 27 HealthKit addition. Heart-rate and cycling-power zones are first-class: read completed-workout zones from `workout.zoneGroupsByType`, receive live transitions via the new `HKLiveWorkoutBuilderDelegate` method `workoutBuilder(_:didUpdateWorkoutZone:)`, and rely on HealthKit's "preferred zones" or supply a custom `HKWorkoutZoneConfiguration` before `beginCollection`. Details in `references/workouts.md`.

For model-assisted summaries, expose only the minimum authorized data through your app’s own tools. Do not infer developer APIs from consumer Health features or press reporting.

## Setup (every HealthKit app)

1. Add the **HealthKit capability** in Signing & Capabilities (and the `com.apple.developer.healthkit.background-delivery` entitlement if you use background delivery).
2. Add Info.plist usage strings: **`NSHealthShareUsageDescription`** (read) and **`NSHealthUpdateUsageDescription`** (write). Clinical-records readers also enable Clinical Health Records and add `NSHealthClinicalHealthRecordsShareUsageDescription`; a privacy policy is required.
3. Gate everything on `HKHealthStore.isHealthDataAvailable()`. Create **one** `HKHealthStore` and retain it for the app's lifetime (wrap it in an `@MainActor` manager).
4. Request a **minimal** type set:

```swift
import HealthKit

let store = HKHealthStore()
guard HKHealthStore.isHealthDataAvailable() else { /* no HealthKit on this device */ return }

let read: Set<HKObjectType> = [HKQuantityType(.stepCount), HKQuantityType(.heartRate)]
let share: Set<HKSampleType> = [HKQuantityType(.activeEnergyBurned)]
try await store.requestAuthorization(toShare: share, read: read)
// Build UI assuming you CANNOT know whether reads were granted.
```

In SwiftUI prefer the HealthKitUI modifier `healthDataAccessRequest(store:shareTypes:readTypes:trigger:completion:)` to present the system sheet.

## The type system (quick reference)

`HKObjectType` → `HKSampleType` → `HKQuantityType` (numeric: steps, heart rate, energy), `HKCategoryType` (enumerated: sleep, mindful minutes), `HKCorrelationType` (grouped: blood pressure, food), `HKWorkoutType`, `HKSeriesType` (`.workoutRoute()`, heartbeat), `HKClinicalType`, and `HKStateOfMind` (iOS 18+) and medication types (iOS 26+). `HKCharacteristicType` holds immutable traits (biological sex, blood type, DOB) read directly.

**Cumulative vs discrete is the trap:** cumulative quantity types (step count, active energy, distance) support `.cumulativeSum`; discrete types (heart rate, body mass) support `.discreteAverage`/`.discreteMin`/`.discreteMax`/`.mostRecent`. Using the wrong statistics option throws. `HKQuantity` always carries an `HKUnit` — read it back with a compatible unit (bpm = `HKUnit.count().unitDivided(by: .minute())`); unit mismatches are a top bug source.

## Reading (default to async/await descriptors)

For new code use the modern query **descriptors** (iOS 15.4+), not the legacy `HK*Query` classes:

```swift
// One-shot statistic (e.g., today's steps)
let calendar = Calendar.current
let start = calendar.startOfDay(for: .now)
let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)
let descriptor = HKStatisticsQueryDescriptor(
    predicate: .quantitySample(type: HKQuantityType(.stepCount), predicate: predicate),
    options: .cumulativeSum)
let steps = try await descriptor.result(for: store)?
    .sumQuantity()?.doubleValue(for: .count())
```

Use `HKStatisticsCollectionQueryDescriptor` for charts (fixed daily/weekly intervals), `HKAnchoredObjectQueryDescriptor` for incremental sync (persist the `HKQueryAnchor`), and `HKObserverQuery` + `enableBackgroundDelivery` for background updates (always call the completion handler or iOS throttles you). Full query catalog, predicates, background-delivery setup, routes, and Activity Rings → `references/reading.md`.

## Writing

Construct `HKQuantitySample` / `HKCategorySample` / `HKCorrelation`, attach an accurate device and metadata for provenance (do not label an imported measurement as measured by `.local()`), and `try await store.save(_:)` (batch related samples in one call). You can only delete data your app wrote. Never write false data (guardrail 3). Details → `references/writing.md`.

## Workouts

Two paths, both via builders (never the deprecated `HKWorkout` init):
- **Off-session** (import/GPX, iPhone summaries): `HKWorkoutBuilder` + optional `HKWorkoutRouteBuilder`.
- **Live** (Apple Watch, and iPhone on iOS 26+): `HKWorkoutSession` + `HKLiveWorkoutBuilder` + `HKLiveWorkoutDataSource`, with mirroring to iPhone via `startMirroringToCompanionDevice()`. Plus the iOS 27 **workout-zones** API.

Full builder/session lifecycle, the live flow, mirroring, iPhone crash recovery, and zones → `references/workouts.md`.

## When to read each reference

- **`references/authorization-and-setup.md`** — the authorization model in depth (the read asymmetry, `authorizationStatus`, `getRequestStatus`, write detection, the empty-data UX), entitlements, platform availability (iPhone/Watch/iPad/Vision Pro), and the `@MainActor` manager pattern. Read before wiring up permissions.
- **`references/reading.md`** — every query type (legacy classes + modern descriptors), predicates and sorting, statistics (cumulative vs discrete), anchored sync, observer queries + background delivery, workout routes, Activity Rings, and performance. Read for any data fetch.
- **`references/writing.md`** — saving quantity/category/correlation samples, metadata/`HKDevice`/source provenance, batching, deleting, and saving workouts. Read for any write.
- **`references/workouts.md`** — `HKWorkoutBuilder`, `HKWorkoutRouteBuilder`, multi-activity, the watchOS live flow (`HKWorkoutSession` lifecycle + delegates), iPhone workouts + crash recovery, mirroring, the iOS 27 workout-zones API, and WorkoutKit (planned workouts). Read for anything workout-related.
- **`references/specialized-data.md`** — State of Mind (mood), the Medications API, sleep stages, reproductive health, clinical records / FHIR, HealthKitUI, and using Foundation Models with HealthKit. Read for those specific domains.
- **`references/privacy-and-review.md`** — Guideline 5.1.3 in full, the medical-vs-wellness line, medical-device declarations and current submission requirements, data minimization, and the common pitfalls list. Read before submission and when wording medical claims.

## Critical gotchas

- **Never gate UI on read permission** — you can't detect denial; handle empty results (guardrail 1).
- **Never use `HKWorkout(...)` initializers** — use the builders for new code (guardrail 2).
- **Always call the `HKObserverQuery` completion handler**, and re-register `enableBackgroundDelivery` on every launch — or background updates stop.
- **Persist `HKQueryAnchor`s** for synced data, or you re-fetch everything each time.
- **Match units and statistics options to the type** (cumulative vs discrete) — mismatches throw or return wrong numbers.
- **Marshal delegate callbacks to `@MainActor`** — workout-session/builder delegates fire on background queues.
- **Use tabular numerals** (`.monospacedDigit()`) for health measurements, timers, workout durations, dates, and counts; reserve stable widths for changing values.
- **Verify SDK availability** separately for stored data, live workout sessions, and system UI. For example, medication queries require iOS 26 and workout zones require iOS 27.

## Primary references

- [Setting up HealthKit](https://developer.apple.com/documentation/healthkit/setting-up-healthkit)
- [Authorizing health-data access](https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data)
- [Reading data](https://developer.apple.com/documentation/healthkit/reading-data-from-healthkit)
- [Workout zones](https://developer.apple.com/documentation/healthkit/hkworkoutzoneconfiguration)
- [Health and health research review requirements](https://developer.apple.com/app-store/review/guidelines/#health-and-health-research)
