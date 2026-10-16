---
name: app-intents-siri
description: "Build or debug App Intents, App Entities, App Shortcuts, system schemas, Siri integration, Spotlight entity indexing, Visual Intelligence queries, and intent testing or migration. Use when exposing app actions or content to system experiences; ordinary widget layout or unrelated app UI does not need this skill."
license: MIT
---

# App Intents & the New Siri (iOS 27 / WWDC 2026)

Reviewed 2026-10-16 against Xcode 27.0 (27A266a), Swift 6.4, and the iOS 27.0 SDK. Check the target platform and deployment version for each API; newer SDK availability does not imply that a consumer service is enabled for every account or region. Code using app stores, routers, or model types is an integration sketch; supply those app-specific dependencies.

App Intents exposes an app’s actions and content to Siri, Shortcuts, Spotlight, widgets, and other system experiences. Adopt the surfaces that serve the requested feature. Keep existing SiriKit behavior until its replacement is verified for the app’s supported OS versions and domains.

## The Mental Model

Three nouns, one verb:
- **App Entity** — a piece of content the app owns (a song, a landmark, a message thread). Conform to `AppEntity`.
- **App Intent** — an action the app can perform on entities. Conform to `AppIntent`.
- **App Schema** — a *system-defined shape* for an intent/entity/enum that Siri already knows how to process (e.g. `.mail.createDraft`, `.messages.sendMessage`). Applied via the `@AppIntent(schema:)` / `@AppEntity(schema:)` / `@AppEnum(schema:)` macros.
- The verb is **`perform()`** — the async function that does the work and optionally returns a value, dialog, or snippet.

The system builds a Spotlight **semantic index** of indexed entities plus an "app toolbox" of available intents, and a system orchestrator decides what to run. The app's job is to model entities, expose intents, adopt the matching schemas, and annotate on-screen views.

## API and availability reference

| API | What it does | Back-deploys? |
|-----|--------------|---------------|
| `@AppIntent(schema:)` / `@AppEntity(schema:)` / `@AppEnum(schema:)` | Adopt system schemas (supersede the old `@AssistantIntent`/`@AssistantEntity`/`@AssistantEnum`) | Macro iOS 18+; schema availability varies |
| **View annotations** (`appEntityIdentifier`) | Associate views and selection with entities | iOS 18.4+; system surface support varies |
| `IntentValueQuery` | Return entities for large/server-side/visual search (also powers Visual Intelligence) | iOS 26+ |
| `EntityCollection<T>` | Parameter that passes entity **IDs** not resolved entities — huge speedup for bulk ops | iOS 27 only |
| `RelevantEntities` | Proactively suggest entities to the system with a context | iOS 27 only |
| `SyncableEntity` | Stable cross-device IDs so Siri conversations continue across devices | iOS 27 only |
| `ValueRepresentation` / `IntentValueRepresentation` | Export an entity as a structured system type (e.g. `PlaceDescriptor` → Maps) | iOS 26.4+ |
| `@UnionValue` | One parameter accepts multiple entity types | iOS 18+ |
| `LongRunningIntent` + `CancellableIntent` | Run longer tasks with progress and cancellation support | iOS 27 only |
| `IntentExecutionTargets` | Choose which process runs an intent (app / extension / widget) | iOS 27 only |
| `.system.searchInApp` | Re-run Siri's search inside the app's own search UI (renamed from `.system.search`) | iOS 27 only |
| **AppIntentsTesting** | Integration-test intents through the real App Intents stack | iOS 27+ (UI test target) |
| `@ComputedProperty` / `@DeferredProperty` | Read entity props from source of truth / lazily | iOS 26+ |
| `SnippetIntent` (interactive snippets) | Confirmation + result snippets with buttons/toggles | iOS 26+ |

App Intents itself dates to **iOS 16**; the core `AppIntent`/`AppEntity`/`AppShortcut` model and `ParameterSummary` work back to then. SwiftData-backed intents need iOS 17. Annotate new APIs with `@available(iOS 27.0, *)` and degrade gracefully.

## Core Patterns

### A basic intent + entity

```swift
import AppIntents

struct LandmarkEntity: AppEntity {
    let id: UUID
    var name: String
    var region: String

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Landmark"
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(region)")
    }

    static let defaultQuery = LandmarkQuery()
}

struct LandmarkQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [LandmarkEntity] {
        await LandmarkStore.shared.landmarks(ids: identifiers)
    }
}

struct OpenLandmarkIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Landmark"
    static let openAppWhenRun = true

    @Parameter(title: "Landmark")
    var landmark: LandmarkEntity

    func perform() async throws -> some IntentResult {
        await Navigator.shared.open(landmark)
        return .result()
    }
}
```

### App Shortcuts (zero-config Siri/Spotlight access)

```swift
struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenLandmarkIntent(),
            phrases: [
                "Open \(\.$landmark) in \(.applicationName)",
                "Show \(\.$landmark) in \(.applicationName)"
            ],
            shortTitle: "Open Landmark",
            systemImageName: "mappin.and.ellipse"
        )
    }
}
```

Phrases must include `\(.applicationName)`; max 10 shortcuts per provider. App Shortcuts work without the user setting anything up, which makes them the cheapest first win.

### Adopt a system schema (the high-leverage move)

Schemas let Siri understand an action with **no trigger phrases** and no code changes as Apple expands language support. Xcode autocompletes available schemas by domain and emits Fix-Its for *missing related schemas* (e.g. it nudges to add `draftMessage` alongside `sendMessage`) so a complete conversational set is adopted.

```swift
@AppIntent(schema: .system.searchInApp) // iOS 27+
struct SearchInAppIntent: AppIntent {
    static let title: LocalizedStringResource = "Search in App"
    static var openAppWhenRun: Bool { true }
    @Parameter(title: "Search") var criteria: StringSearchCriteria

    @MainActor
    func perform() async throws -> some IntentResult {
        Router.shared.showSearch(query: criteria.term) // app-defined navigation
        return .result()
    }
}
```

Schemas convey action semantics to the system. Still enforce authorization and necessary confirmations in the app’s operation, including callers outside Siri; schema metadata is not an access-control boundary. See `references/app-schemas.md` for the full domain list and adoption workflow.

### On-screen awareness (View Annotations)

So the assistant can resolve "this," "that," or "the third one," map views to entities:

```swift
// One annotated view among many
LandmarkRow(landmark: landmark)
    .appEntityIdentifier(EntityIdentifier(for: LandmarkEntity.self,
                                          identifier: landmark.id))

// A selectable collection — map the selection type to entity IDs
List(selection: $selection) { /* rows */ }
    .appEntityIdentifier(forSelectionType: Track.ID.self) { trackID in
        EntityIdentifier(for: TrackEntity.self, identifier: trackID)
    }

// A single primary item on a detail screen — use NSUserActivity
let activity = NSUserActivity(activityType: "com.example.viewing")
activity.appEntityIdentifier = EntityIdentifier(for: SongEntity.self,
                                                identifier: song.id)
```

Works in SwiftUI, UIKit, and AppKit. Only **persistent** entities are supported (no transient entities). Annotations can also be attached to `UNMutableNotificationContent`, Now Playing (`MediaSessionRepresentable`), and AlarmKit. Implement component-based `displayRepresentations(for:requestedComponents:)` so resolution stays fast.

### Returning dialog and snippets

```swift
func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
    let summary = try await summarize()
    return .result(
        dialog: IntentDialog("Here's your summary"),
        view: SummarySnippet(text: summary)   // SwiftUI snippet
    )
}
```

Ask a clarifying question mid-intent (true multi-turn) with `$parameter.requestValue("Which playlist?")`. For interactive confirmation snippets with buttons/toggles, use `SnippetIntent` (iOS 26+) and share state via `@Dependency`. Keep snippet content under ~340 points and use `ContainerRelativeShape` for responsive margins. Details in `references/entities-and-queries.md`.

## When to read the reference files

The four reference files go deep. Read the one matching the task:

- **`references/app-schemas.md`** — Full list of App Intent domains and schemas (mail, messages, photos, calendar, camera, documents, media, system, …), the schema adoption workflow, Xcode Fix-Its, and `.system.searchInApp`. Read when adopting schemas or making an app understood by Siri without custom phrases.
- **`references/entities-and-queries.md`** — Deep dive on `IndexedEntity` + Spotlight semantic search, `IntentValueQuery`, `EntityCollection`, `RelevantEntities`, `SyncableEntity`, `ValueRepresentation`/`Transferable`, `@UnionValue`, `@ComputedProperty`/`@DeferredProperty`, `LongRunningIntent`, `IntentExecutionTargets`, and interactive snippets. Read when modeling entities, doing search, or handling bulk/long-running work.
- **`references/siri-integration.md`** — How the new Siri AI uses App Intents; on-screen awareness; Visual Intelligence (`SemanticContentDescriptor`); the Siri app, history, and system surfaces; donations (`IntentDonationManager`); `IntentAuthenticationPolicy` and `EntityOwnership`; runtime availability and privacy boundaries. Read when integrating with Siri/Visual Intelligence or reasoning about privacy and availability.
- **`references/testing-and-migration.md`** — The AppIntentsTesting framework end to end, the progressive test ladder (AppIntentsTesting → Shortcuts → Spotlight → Siri), and the SiriKit → App Intents migration considerations. Read when writing tests or migrating off SiriKit.

## Recommended Adoption Order

Do these in sequence; each builds on the last.

1. **Model + index entities.** Conform core nouns to `AppEntity` and `IndexedEntity`; index to Spotlight; keep the index fresh on add/update/delete.
2. **Ship App Shortcuts** for the 3–5 highest-value actions (cheapest Siri/Spotlight win, works today and back-deploys).
3. **Adopt matching App Schemas** and resolve Xcode's missing-schema Fix-Its so conversational sets are complete.
4. **Customize `DisplayRepresentation`s**, then add `IntentValueQuery` + `.system.searchInApp` for search.
5. **Annotate on-screen views** with `appEntityIdentifier` for on-screen awareness.
6. **Add `ValueRepresentation`/`Transferable`** to move structured content across apps.
7. **Adopt `EntityCollection`** for bulk operations and `LongRunningIntent` + `CancellableIntent` for work that needs extended execution.
8. **Donate UI interactions** (`IntentDonationManager`) for personalization — accurately; excessive donations are ignored.
9. **Add governance** — `IntentAuthenticationPolicy` and `EntityOwnership` on sensitive/shared-content intents.
10. **Test progressively** — AppIntentsTesting in CI, then up the ladder to a live Siri device.

## Critical gotchas

- Resolve each entity ID through the current user’s authorized data, including bulk IDs in `EntityCollection.identifiers`. A supplied identifier is not proof of access.
- Keep queries and `perform()` safe for foreground and background execution. Do UI navigation on the main actor and select the supported execution mode for the target SDK.
- Use availability checks per symbol: `IntentValueQuery` starts at iOS 26, `IntentValueRepresentation` at 26.4, and `EntityCollection` / `SyncableEntity` at 27.
- Use `@ComputedProperty` for cheap current values and `@DeferredProperty` for asynchronous values; a computed property can still be expensive if its implementation is expensive.
- System intelligence availability and account authorization are separate from SDK availability. Test the requested surface on a supported device.

## Primary references

- [App Intents](https://developer.apple.com/documentation/appintents)
- [New framework capabilities](https://developer.apple.com/videos/play/wwdc2026/345/)
- [Defining app entities](https://developer.apple.com/documentation/appintents/defining-app-entities-for-your-custom-data-types)
- [Testing App Intents](https://developer.apple.com/documentation/appintentstesting/testing-your-app-intents-code)
