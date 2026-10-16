# Testing & SiriKit Migration (iOS 27)

The AppIntentsTesting framework and a migration approach for legacy SiriKit integration. WWDC 2026 sessions: **295 "Validate your App Intents adoption with AppIntentsTesting"**.

## Table of Contents
- [AppIntentsTesting](#appintentstesting)
- [The progressive test ladder](#the-progressive-test-ladder)
- [SiriKit migration scope](#sirikit-migration-scope)
- [Migration playbook](#migration-playbook)
- [Verification limits](#verification-limits)

## AppIntentsTesting

A new integration-testing framework (session 295) that runs intents through the **same** infrastructure Siri, Shortcuts, and Spotlight use — no mocks, no stubs, no UI automation. Tests live in a **UI Testing (XCUITest) bundle** and talk to the app **out-of-process**, so they exercise the real registration, resolution, and `perform()` path.

```swift
import AppIntentsTesting
import XCTest

final class IntentTests: XCTestCase {
    func testCreateNote() async throws {
        let defs = IntentDefinitions(bundleIdentifier: "com.example.notes")

        // Names and parameters must match an intent registered by the app.
        let definition = defs.intents["CreateNoteIntent"]
        let intent = definition.makeIntent(title: "Review fixture")


        let result = try await intent.run()
        // Assert on the resolved result / side effects
        XCTAssertNotNil(result)
    }
}
```

It also validates:
- **Entity queries** — that an `EntityQuery` returns the right entities for given IDs.
- **Transferable round-trips** — `exported(as:)` / `resolved(from:)`.
- **Spotlight indexing** — that entities are indexed as expected.
- **View annotations** — that on-screen entities resolve.

CI picks up these tests automatically. Because they go through the real stack, a passing AppIntentsTesting suite is strong evidence the intent will actually work in Siri — far better than unit-testing `perform()` in isolation.

## The progressive test ladder

Apple's recommended order of verification, cheapest and most deterministic first:

1. **AppIntentsTesting** — does the intent's shape, resolution, and `perform()` work through the real stack? (deterministic, CI-friendly)
2. **Shortcuts** — does the intent appear with the right parameters and run when added to a shortcut?
3. **Spotlight** — are entities indexed and findable; does `.system.searchInApp` route correctly?
4. **Siri** — end-to-end on a physical Apple-Intelligence device: phrases, schemas, on-screen awareness, multi-turn.

Climb the ladder; don't skip straight to Siri, where failures are hardest to diagnose.

## SiriKit migration scope

Apple’s SiriKit documentation identifies it as legacy support. Deprecation and migration vary by domain and symbol; the installed Xcode 27 SDK does not mark the base `INIntent` declaration deprecated. Do not claim a blanket removal deadline or assume every domain has a one-for-one App Intents replacement. Inventory the app’s actual APIs and supported OS versions before removing working handlers.

See [SiriKit](https://developer.apple.com/documentation/sirikit) and [deprecated SiriKit domains](https://developer.apple.com/support/deprecated-sirikit-intent-domains/).

## Migration playbook

1. **Inventory SiriKit usage.** Find every `INIntent` subclass, `.intentdefinition` file, and Intents extension. Note which legacy domain each uses.
2. **Convert definitions.** Apple's tooling offers a one-click "Convert to App Intent" from `.intentdefinition` files (see the "Migrate custom intents to App Intents" tech talk and the WidgetKit "Migrating from SiriKit Intents to App Intents" guide).
3. **Re-home the logic.** Move the work from the Intents extension's handler into an `AppIntent.perform()`. Prefer adopting the matching **App Schema** over a bare custom intent so Siri understands the action's meaning and consequences.
4. **Model entities.** Replace `INObject`-style types with `AppEntity`/`IndexedEntity`; index them to Spotlight.
5. **Ship both during transition.** Use the documented migration metadata for custom intents and widget configurations so existing user shortcuts continue to resolve. Do not assume the system deduplicates two unrelated definitions automatically.
6. **Test up the ladder** (AppIntentsTesting → Shortcuts → Spotlight → Siri).
7. **Delete legacy code** once the deployment target is high enough that SiriKit paths are no longer needed.

## Verification limits

AppIntentsTesting exercises registration and resolution, but it does not establish that Siri understands every phrase or that every production entitlement is configured. Run UI test bundles against the real app, assert specific returned values and side effects, and separately verify cancellation, authorization failures, missing entities, and each promised system surface.

[Testing your App Intents code](https://developer.apple.com/documentation/appintentstesting/testing-your-app-intents-code) and [WWDC26 testing session](https://developer.apple.com/videos/play/wwdc2026/295/) describe supported integration tests. The sample requires a `CreateNoteIntent` in the test app; it is not a standalone executable.
