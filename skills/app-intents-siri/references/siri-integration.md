# Siri AI Integration, Privacy & Availability (iOS 27)

How App Intents connects to the rebuilt Siri AI, plus on-screen awareness, Visual Intelligence, donations, the real privacy/auth controls, and the runtime availability checks. WWDC 2026 sessions: **240** (App Schemas), **343** (advanced features), **297** (Visual Intelligence), **347 "Secure your app: mitigate risks to agentic features"**.

## Table of Contents
- [What the app integrates](#what-the-app-integrates)
- [The three developer pillars](#the-three-developer-pillars)
- [On-screen awareness](#on-screen-awareness)
- [Visual Intelligence](#visual-intelligence)
- [Donations](#donations)
- [Privacy & authentication — the real controls](#privacy--authentication--the-real-controls)
- [Availability: hardware, regions, languages](#availability-hardware-regions-languages)

## What the app integrates

Use App Intents to expose actions, entities, search, and on-screen context to system experiences. Model-provider agreements, infrastructure, and consumer rollout dates are not implementation contracts; this skill does not depend on them.

## The three developer pillars

From session 240, Siri can now:

1. **Access the app's entities** — via indexed entities (Spotlight semantic index) and `IntentValueQuery`.
2. **Take action through the app's intents** — via App Intents, ideally schema-conforming.
3. **Understand on-screen context** — via View Annotations.

A system orchestrator combines the personal-context index (Mail, Calendar, Messages, Photos, Notes, files) with an "app toolbox" of available intents to decide what to run.

## On-screen awareness

This is what lets a user say "text my wife this conversation" or "play the third one." Map views to entities with the View Annotations API (full code in the main `SKILL.md`):

- `.appEntityIdentifier(_:)` on a view → one annotated item among many.
- `.appEntityIdentifier(forSelectionType:_:)` → a selectable list/collection.
- `NSUserActivity.appEntityIdentifier` → a single primary item on a detail screen.

Also attachable to `UNMutableNotificationContent` (reply to an announced notification), Now Playing (`MediaSessionRepresentable`), and AlarmKit's `AlarmConfiguration` (snooze/dismiss). Constraints: **persistent entities only**; implement `displayRepresentations(for:requestedComponents:)` for fast resolution; works in SwiftUI, UIKit, and AppKit.

## Visual Intelligence

Visual Intelligence (iPhone Camera, iPad, Mac, and Vision Pro) lets users circle or capture something and get app results. Wire it up with `IntentValueQuery` taking a `SemanticContentDescriptor`, plus per-entity `OpenIntent`s and a `VisualIntelligenceSearchIntent` for "more results."

```swift
import VisualIntelligence

struct VisualLandmarkQuery: IntentValueQuery {
    func values(for input: SemanticContentDescriptor) async throws -> [LandmarkEntity] {
        guard let pixelBuffer = input.pixelBuffer else { return [] }
        return try await LandmarkRecognizer.shared.match(pixelBuffer)
    }
}
```

Return a `@UnionValue` if the app surfaces multiple entity types from one visual query. Check the availability of the visual search surface on the target device and OS.

## Donations

UI interactions aren't learned automatically. Donate them so Apple Intelligence learns preferences and stays aware of ongoing activity:

```swift
try await IntentDonationManager.shared.donate(intent: PlayTrackIntent(track: track))
```

Use schema-conforming intents for donations. Donate **accurately** — over-donating is ignored by the system. Ongoing activities (Maps `NavigationSession`, Clock stopwatches) are donated so Siri can reference and control them.

## Privacy & authentication — the real controls

Do not infer a per-intent cloud-routing control from press reporting. Use documented authentication and ownership APIs, and treat routing by a system assistant separately from model calls the app makes itself. Relevant controls include:

- **`IntentAuthenticationPolicy`** (per intent) — `static var authenticationPolicy` with `.alwaysAllowed`, `.requiresAuthentication`, or `.requiresLocalDeviceAuthentication`. Controls whether the device must be unlocked/authenticated to run the intent.

  ```swift
  struct TransferMoneyIntent: AppIntent {
      static var authenticationPolicy: IntentAuthenticationPolicy { .requiresLocalDeviceAuthentication }
  }
  ```

- **`OwnershipProvidingEntity` / `EntityOwnership`** (per entity) — conform shareable entities and keep ownership current (`.shared`, `.public`, `.unknown`) so Siri auto-confirms before meaningful side effects on content the user doesn't solely own.

- **`PrivacyInfo.xcprivacy`** — the pre-existing (iOS 17) privacy manifest for declared data collection and Required Reason APIs. Not documented as extending to per-intent cloud routing.

- **Model execution in your app** — if `perform()` uses a model, explicitly choose a supported model/provider and check runtime availability. An on-device model choice for the app does not control Siri’s processing of the user’s request.

- **Capabilities and entitlements** — check requirements of the particular surface and the operation it invokes; App Intents does not bypass permissions for HealthKit, contacts, location, or other data.

Session 347 also covers prompt-injection defenses and user-confirmation patterns for agentic features — worth reading before shipping intents with destructive side effects. Note that schema adoption auto-tags risk (e.g. a delete schema as destructive), which drives automatic confirmation.

## Availability: hardware, regions, languages

Separate four checks: API availability in the deployment SDK, the installed OS, the user’s device and settings, and availability of the system experience in the user’s language/region. Core App Intents actions can support Shortcuts independently of newer Siri features. Test each promised surface rather than using a static hardware or region list.

Use [Apple Intelligence requirements](https://support.apple.com/en-us/121115) for current consumer availability, [App Intents](https://developer.apple.com/documentation/appintents) for API requirements, and [secure agentic features](https://developer.apple.com/videos/play/wwdc2026/347/) for system integration guidance. Reviewed 2026-10-16; service availability is not frozen by this review.
