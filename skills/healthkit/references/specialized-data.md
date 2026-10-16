# Specialized Data Domains

The HealthKit domains beyond steps-and-workouts: mood, medications, sleep, reproductive health, clinical records/FHIR, the HealthKitUI components, and pairing HealthKit with Foundation Models.

## Table of Contents
- [State of Mind (mood)](#state-of-mind-mood)
- [Medications API](#medications-api)
- [Sleep stages](#sleep-stages)
- [Reproductive health](#reproductive-health)
- [Clinical records and FHIR](#clinical-records-and-fhir)
- [HealthKitUI](#healthkitui)
- [Foundation Models + HealthKit](#foundation-models--healthkit)

## State of Mind (mood)

`HKStateOfMind` (iOS 18 / watchOS 11) represents mood/emotion with four parameters:
- **`kind`** — `.momentaryEmotion` (a feeling now) or `.dailyMood` (overall day).
- **`valence`** — continuous −1.0 (very unpleasant) … +1.0 (very pleasant).
- **`labels`** — e.g. `.happy`, `.anxious`, `.content`, `.angry`.
- **`associations`** — contexts the feeling is about (e.g. `.work`, `.health`, `.family`).

Save with `store.save(_:)`; query with `HKSampleQueryDescriptor` and the State of Mind predicate. WWDC24 session 10109 ("Explore wellbeing APIs in HealthKit") also introduced Depression-Risk and Anxiety-Risk assessment types. Note: the user's **free-text note** attached to a Health mood entry is **not** exposed to third-party apps.

When you build mood features, route them through the wellbeing guidance — this is sensitive data; minimize what you read and never use it for advertising (Guideline 5.1.3).

## Medications API

iOS 26 / watchOS 26 (WWDC25 session 321). **Read-only** access to the user's medications:
- **`HKUserAnnotatedMedication`** — a medication the user tracks (properties incl. `isArchived`, `hasSchedule`, nickname, the underlying medication concept).
- **`HKMedicationDoseEvent`** — a dose sample with status (`.taken`, `.skipped`, …) and dose quantity. (Early SDKs had an inaccessible initializer — it's read-only.)
- **Queries:** `HKUserAnnotatedMedicationQueryDescriptor` / `HKUserAnnotatedMedicationQuery`; filter with `predicateForUserAnnotatedMedications(isArchived:)` / `(hasSchedule:)`.
- Authorization is **per-object read authorization**; Health helps manage authorization of newly added medications via anchored queries.

Treat medications as highly sensitive — read only what a feature needs.

## Sleep stages

Since iOS 16, `sleepAnalysis` is a category type with stage values mapped to AASM scoring:
- `.inBed`, `.awake`, `.asleepCore`, `.asleepDeep`, `.asleepREM` (and legacy `.asleepUnspecified`).

Save **one sample per contiguous stage period** (don't collapse a night into a single sample). Read with a sample-query descriptor over `HKCategoryType(.sleepAnalysis)`.

## Reproductive health

Menstrual flow, ovulation test result, cervical mucus quality, basal body temperature, etc., as category/quantity types. Treat reproductive data with the same minimization and no-advertising discipline.

## Clinical records and FHIR

**iOS only**, and **read-only**. Lets apps read the user's medical records imported into Health from providers.
- Types via `HKObjectType.clinicalType(forIdentifier:)`: `.allergyRecord`, `.conditionRecord`, `.immunizationRecord`, `.labResultRecord`, `.medicationRecord`, `.procedureRecord`, `.vitalSignRecord` (all iOS 12), `.coverageRecord` (iOS 14).
- **`HKClinicalRecord`** (an `HKSample`) exposes `fhirResource` — an **`HKFHIRResource`** with `identifier`, `resourceType`, `sourceURL`, `FHIRVersion` (`HKFHIRVersion`), and `data` (raw FHIR JSON you parse).
- FHIR releases: `HKFHIRRelease.dstu2` (iOS 11.3) and `.r4` (iOS 14). Apple does **not** auto-convert between them — handle the version you get.
- **Never request share authorization for clinical types** — it throws `NSInvalidArgumentException`. HealthKit presents clinical types in a **separate, more detailed consent sheet**; authorization is per record type; query with `HKSampleQuery`/descriptor and cast results to `[HKClinicalRecord]`. Clinical-records apps also enable Clinical Health Records, add `NSHealthClinicalHealthRecordsShareUsageDescription`, and provide a privacy policy.

## HealthKitUI

- **`HKActivityRingView`** — a UIKit view that animates an `HKActivitySummary` via `setActivitySummary(_:animated:)` (wrap in `UIViewRepresentable` for SwiftUI).
- **`healthDataAccessRequest(store:shareTypes:readTypes:trigger:completion:)`** — the SwiftUI modifier that presents the system authorization sheet, driven by an `Equatable` `trigger`. There's a read-only overload. On visionOS it fails for Guest Users (no sheet) — defer and handle that.

## Foundation Models + HealthKit

For an app feature that summarizes HealthKit data with a model:
1. Expose **specific, minimal** HealthKit reads as Foundation Models `Tool`s (e.g., "fetch average resting heart rate for the last 7 days").
2. Let a `LanguageModelSession` call those tools and summarize — keeping inference **on-device** for privacy.
3. Never feed more health data into a prompt than the feature needs; never send it to a third-party cloud model without explicit, specific consent (and never for advertising).

Use [Foundation Models](https://developer.apple.com/documentation/foundationmodels) for model availability, tool-calling, and structured output. The companion `foundation-models` skill is optional; this HealthKit skill is independently installable.

Reviewed 2026-10-16 with Xcode 27.0 / iOS 27.0 SDK. Primary reference: [HealthKit](https://developer.apple.com/documentation/healthkit). Availability and runtime behavior must be checked for the app’s actual platforms.
