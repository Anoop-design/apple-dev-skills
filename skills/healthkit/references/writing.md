# Writing Health Data

Saving data to HealthKit: building samples, attaching provenance, batching, deleting, and saving workouts. The cardinal rule: never write false or inaccurate data (App Review Guideline 5.1.3).

## Table of Contents
- [Saving quantity samples](#saving-quantity-samples)
- [Saving category samples](#saving-category-samples)
- [Correlations (grouped samples)](#correlations-grouped-samples)
- [Provenance: HKDevice, source, metadata](#provenance-hkdevice-source-metadata)
- [Batching](#batching)
- [Deleting](#deleting)
- [Saving workouts](#saving-workouts)

## Saving quantity samples

```swift
let energy = HKQuantity(unit: .kilocalorie(), doubleValue: 240)
let sample = HKQuantitySample(
    type: HKQuantityType(.activeEnergyBurned),
    quantity: energy,
    start: start, end: end,
    device: nil, // manually entered; do not claim this device measured it
    metadata: [HKMetadataKeyWasUserEntered: true])
try await store.save(sample)
```
The unit must be compatible with the type. `HKCumulativeQuantitySample` / `HKDiscreteQuantitySample` are specializations you can use when the distinction matters.

## Saving category samples

```swift
let mindful = HKCategorySample(
    type: HKCategoryType(.mindfulSession),
    value: HKCategoryValue.notApplicable.rawValue,
    start: start, end: end)
try await store.save(mindful)
```
For typed categories (e.g., sleep) use the type's value enum: `HKCategoryValueSleepAnalysis.asleepDeep.rawValue` (see `references/specialized-data.md`).

## Correlations (grouped samples)

Blood pressure and food are correlations — multiple samples saved as one logical entry:
```swift
let systolic = HKQuantitySample(type: HKQuantityType(.bloodPressureSystolic),
    quantity: HKQuantity(unit: .millimeterOfMercury(), doubleValue: 120), start: t, end: t)
let diastolic = HKQuantitySample(type: HKQuantityType(.bloodPressureDiastolic),
    quantity: HKQuantity(unit: .millimeterOfMercury(), doubleValue: 80), start: t, end: t)
let bp = HKCorrelation(type: HKCorrelationType(.bloodPressure),
    start: t, end: t, objects: [systolic, diastolic])
try await store.save(bp)
```

## Provenance: HKDevice, source, metadata

- **`HKDevice`** — use `.local()` only when the local device produced the measurement, or a constructed `HKDevice(name:manufacturer:model:…)` for an external sensor. Records *what produced* the reading.
- **`HKSourceRevision`** — HealthKit automatically records the writing app + version; read it back via `sample.sourceRevision`.
- **Metadata** — `HKMetadataKeyWasUserEntered` (manual vs measured), `HKMetadataKeyDeviceSerialNumber`, custom keys, and domain keys (e.g., swimming stroke style). Provenance matters: record enough that a *transcribed* reading (e.g., a value transcribed from a photograph) is distinguishable from a *measured* one — they aren't the same evidentiary object.

## Batching

Save related samples in **one** `save([...])` call rather than many — it reduces request overhead; handle save errors before updating your own state:
```swift
try await store.save([sample1, sample2, sample3])
```

## Deleting

You can only delete data **your app wrote**:
```swift
try await store.delete(sample)
try await store.deleteObjects(of: HKQuantityType(.stepCount), predicate: predicate)
```
Attempting to delete another source's data fails.

## Saving workouts

**Never use the deprecated `HKWorkout(activityType:start:end:…)` initializers** for new code. Prefer `HKWorkoutBuilder` (off-session) or `HKWorkoutSession` + `HKLiveWorkoutBuilder` (live). Minimal off-session save:
```swift
let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
try await builder.beginCollection(at: start)
try await builder.addSamples([energySample, distanceSample])
try await builder.endCollection(at: end)
let workout = try await builder.finishWorkout()
```
Full builder/session detail, routes, multi-activity, live sessions, mirroring, and the iOS 27 workout-zones API are in `references/workouts.md`.

Reviewed 2026-10-16 with Xcode 27.0 / iOS 27.0 SDK. Primary reference: [Saving HealthKit data](https://developer.apple.com/documentation/healthkit/saving-data-to-healthkit). Availability and runtime behavior must be checked for the app’s actual platforms.
