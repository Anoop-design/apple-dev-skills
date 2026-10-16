# Authorization, Setup & Platform Availability

The HealthKit authorization model is unusual and getting it wrong is the #1 source of HealthKit bugs. This file covers it in depth, plus entitlements, platform availability, and the manager pattern.

## Table of Contents
- [The read-authorization asymmetry](#the-read-authorization-asymmetry)
- [Requesting authorization](#requesting-authorization)
- [Checking status correctly](#checking-status-correctly)
- [The empty-data UX](#the-empty-data-ux)
- [Entitlements and Info.plist](#entitlements-and-infoplist)
- [Platform availability](#platform-availability)
- [The manager pattern](#the-manager-pattern)

## The read-authorization asymmetry

This is the single most important thing to internalize:

- **WRITE (share) status is detectable.** `authorizationStatus(for:)` returns `.notDetermined`, `.sharingDenied`, or `.sharingAuthorized` — accurate for types you write.
- **READ status is NOT detectable, by design.** For reading, Apple makes a denial **indistinguishable from "the user has no such data"**: queries don’t reveal the denied data; samples written by the app itself may remain readable. There is no API that tells you "the user granted read access to heart rate."

The distinction protects the user’s choice not to disclose health information. Query results are not a complete read-authorization status signal.

**Consequences for your code:**
- **Never gate UI on read permission.** Don't show/hide features based on a read-permission check — there isn't one.
- **Never persist your own "has permission" flag.** Permission can be revoked anytime in Settings → Health → Data Access & Devices. A cached flag goes stale silently.
- **Always handle empty results gracefully** — "no data" and "denied" look the same; design the UI for both (e.g., an empty state with a "connect Health" affordance).

## Requesting authorization

```swift
let read: Set<HKObjectType> = [HKQuantityType(.stepCount), HKQuantityType(.heartRate)]
let share: Set<HKSampleType> = [HKQuantityType(.activeEnergyBurned)]

// async
try await store.requestAuthorization(toShare: share, read: read)
// or completion-based requestAuthorization(toShare:read:completion:)
```

The system shows a per-type toggle sheet **only for types it hasn't prompted for before**. Re-requesting an already-decided type shows nothing. The call succeeding means the sheet was handled, **not** that anything was granted.

In SwiftUI, prefer the HealthKitUI modifier:
```swift
.healthDataAccessRequest(store: store, shareTypes: share, readTypes: read,
                         trigger: requestTrigger) { result in /* handle */ }
```
driven by an `Equatable` trigger value.

## Checking status correctly

- `authorizationStatus(for:)` — **write only**. Don't interpret it for read types.
- `getRequestStatusForAuthorization(toShare:read:)` → `.shouldRequest` / `.unnecessary` / `.unknown`. This tells you whether **prompting would show UI**, not whether access was granted. **`.unnecessary` does NOT mean "granted"** — it means "nothing new to prompt for." A common bug is treating `.unnecessary` as success.

## The empty-data UX

Because you can't detect read access, apps use one of these patterns:
1. **Attempt the read and handle empty.** Simplest and most honest — query, and if results are empty, show an empty/connect state. Don't assume denial.
2. **Keep read and write UI independent.** Request write access only for a real writing feature; never use write status as a proxy for read access.
3. **Re-present the request and direct users to Settings** if they expect data and see none, with copy like "If you've connected Health and still see nothing, check Settings → Health → Data Access."

## Entitlements and Info.plist

- **HealthKit capability** — add in Signing & Capabilities (adds `com.apple.developer.healthkit`).
- **Background delivery** — add the `com.apple.developer.healthkit.background-delivery` entitlement if you call `enableBackgroundDelivery`.
- **Info.plist usage strings (required, app won't pass review without the relevant one):**
  - `NSHealthShareUsageDescription` — why you **read** health data.
  - `NSHealthUpdateUsageDescription` — why you **write** health data.
- **Clinical records** readers enable the Clinical Health Records capability, add `NSHealthClinicalHealthRecordsShareUsageDescription`, and provide a privacy policy. They present a separate, more detailed consent sheet (see `references/specialized-data.md`).

## Platform availability

- **iPhone** — full HealthKit.
- **Apple Watch** — supports HealthKit and live workout sessions; available sensors depend on device and workout type.
- **iPad** — HealthKit and the Health app are supported from iPadOS 17; live workout APIs require newer releases. Check the specific API and device.
- **Apple Vision Pro** — HealthKit available, but authorization sheets aren't shown to **Guest Users**, so `healthDataAccessRequest` fails for guests — defer requests and handle write failures.
- **Mac** — the framework exposes macOS/Catalyst declarations for compatibility, which do not guarantee a usable health store. Gate on `isHealthDataAvailable()` instead of treating successful compilation as runtime support.

Always branch on `HKHealthStore.isHealthDataAvailable()` before any HealthKit call.

## The manager pattern

Wrap the store in a single `@MainActor` observable manager retained for the app's lifetime:

```swift
@MainActor @Observable
final class HealthManager {
    let store = HKHealthStore()
    let shareTypes: Set<HKSampleType> = []
    let readTypes: Set<HKObjectType> = [HKQuantityType(.stepCount)]
    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization() async throws {
        guard isAvailable else { return }
        try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
    }
}
```

One store instance avoids subtle issues with multiple stores and observer registration. Await async descriptors from the manager, and move expensive synchronous processing off the main actor. Publish UI state on `@MainActor`.

Reviewed 2026-10-16 with Xcode 27.0 / iOS 27.0 SDK. Primary reference: [HealthKit authorization](https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data). Availability and runtime behavior must be checked for the app’s actual platforms.
