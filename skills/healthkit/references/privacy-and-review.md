# Privacy, App Review & Compliance

Health data is among the most regulated data on the platform. Check current requirements for the app’s actual features and distribution territories. Apply this before submission and whenever wording medical claims.

## Table of Contents
- [Guideline 5.1.3 summary](#guideline-513-summary)
- [The medical-vs-wellness line](#the-medical-vs-wellness-line)
- [Medical-device declarations](#medical-device-declarations)
- [Data minimization](#data-minimization)
- [Common pitfalls](#common-pitfalls)

## Guideline 5.1.3 summary

App Review Guideline 5.1.3 governs Health, Fitness, and Medical Research data (HealthKit, Clinical Health Records, Motion & Fitness, and similar). The hard rules:
- **No advertising/marketing/data-mining use.** Health data (including from HealthKit and Motion & Fitness) **may not** be used or disclosed for advertising, marketing, or other use-based data mining — and **may not be sold** to data brokers or advertising platforms.
- **No false data.** Apps **must not** write false or inaccurate data into HealthKit.
- **Do not store personal health information in your app’s iCloud storage.** Apple’s system-managed Health synchronization is separate from your app uploading PHI to CloudKit or iCloud Drive.
- **Privacy policy is mandatory**, and must clearly describe data handling.
- **Research needs consent + ethics approval.** Health research requires informed consent and review-board/ethics-board approval.
- Related: **Guideline 2.5.1** — HealthKit must be used for genuine health/fitness purposes integrated with the Health app; **2.5.18 / 3.1.7** — no targeted/behavioral advertising based on health data.

If a feature can't be built without violating one of these, it can't ship — there's no entitlement that unlocks advertising use of health data.

## The medical-vs-wellness line

Intended use, functionality, and claims can affect whether an app is a **regulated medical device**; examples of materially different claims include:
- "**detected** atrial fibrillation" (medical claim) vs "**logged** your heart rate" (wellness).
- "**diagnose**," "**treat**," "**cure**," "**prevent**" are medical-claim verbs.

Audit **onboarding, notifications, paywalls, and App Store copy**, not just in-app labels. If you make a medical claim, you take on regulatory obligations (and the declaration below). When in doubt, describe what the app *records/shows*, not what it *concludes* about the user's health.

Record **provenance** so a transcribed reading is distinguishable from a measured one (`HKDevice`, `HKSource`, `HKMetadataKeyWasUserEntered`). An OCR result is not a paired-sensor measurement.

## Medical-device declarations

Before a medical-feature release, check [App Store Connect Help](https://developer.apple.com/help/app-store-connect/) and [upcoming requirements](https://developer.apple.com/news/upcoming-requirements/) for applicable declarations and submission deadlines. Determine the app’s intended use and territory-specific regulatory status; do not use a static date in a skill or a wording change as proof that a product is outside medical-device regulation.

## Data minimization

- Request the **minimum** type set, and request **contextually** (when a feature needs it), not everything at first launch.
- Over-requesting triggers reviewer scrutiny, lowers grant rates, and erodes trust.
- Read narrowly even after authorization — just because you *can* read a type doesn't mean a given feature should.

## Common pitfalls

- **Assuming you can detect read denial** — you can't; handle empty results (see `references/authorization-and-setup.md`).
- **Forgetting the `HKObserverQuery` completion handler** — iOS throttles future background deliveries.
- **Not re-registering `enableBackgroundDelivery` on launch** — updates silently stop.
- **Unit mismatches** — reading a quantity with an incompatible `HKUnit` (or wrong cumulative/discrete statistics option) throws or returns wrong numbers.
- **Wrong thread/actor** — callback-based query results and delegate callbacks can arrive off the main thread; marshal to `@MainActor` for UI.
- **Not persisting `HKQueryAnchor`s** — re-fetching the full history every launch.
- **Using deprecated `HKWorkout(...)` initializers** — use the builders for new code.
- **Storing PHI in iCloud / using health data for ads** — violates the applicable restrictions in Guideline 5.1.3; verify the current wording and scope before release.
- **Testing only on the Simulator** — Seeded Simulator data is useful, but background delivery, sensors, and live workout behavior require physical-device checks.

Primary source: [App Review Guidelines, Health and Health Research](https://developer.apple.com/app-store/review/guidelines/#health-and-health-research), reviewed 2026-10-16. This summary is not the complete text of the guidelines.
