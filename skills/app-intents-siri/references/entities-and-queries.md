# Entities, Queries & Advanced Intents (iOS 27)

Deep dive on the entity and intent APIs that make Siri AI, Spotlight semantic search, and Visual Intelligence work, plus the performance and long-running-work APIs. WWDC 2026 sessions: **345 "Discover new capabilities in the App Intents framework"**, **343 "Explore advanced App Intents features for Siri and Apple Intelligence"**, **240 "Build intelligent Siri experiences with App Schemas"**.

## Table of Contents
- [Indexing entities for Spotlight semantic search](#indexing-entities-for-spotlight-semantic-search)
- [IntentValueQuery — search beyond the index](#intentvaluequery--search-beyond-the-index)
- [EntityCollection — fast bulk operations](#entitycollection--fast-bulk-operations)
- [RelevantEntities — proactive suggestions](#relevantentities--proactive-suggestions)
- [SyncableEntity — cross-device continuity](#syncableentity--cross-device-continuity)
- [ValueRepresentation & Transferable — moving content across apps](#valuerepresentation--transferable--moving-content-across-apps)
- [@UnionValue — multi-type parameters](#unionvalue--multi-type-parameters)
- [Computed & deferred properties](#computed--deferred-properties)
- [LongRunningIntent & cancellation](#longrunningintent--cancellation)
- [ExecutionTargets — choosing the process](#executiontargets--choosing-the-process)
- [Richer parameter types](#richer-parameter-types)
- [Interactive snippets](#interactive-snippets)

## Indexing entities for Spotlight semantic search

Conform an entity to `IndexedEntity` and push it into Spotlight's **semantic** index (meaning-based, not just keyword) so Siri can find it as personal context, with attribution back to the app.

```swift
struct NoteEntity: IndexedEntity {
    let id: UUID

    @Property(indexingKey: \.title)
    var title: String

    @Property(indexingKey: \.contentDescription)
    var body: String

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Note"
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(title)") }
    static let defaultQuery = NoteQuery()
}

// Index on create/update; keep it fresh on delete.
try await CSSearchableIndex.default().indexAppEntities([note])
```

Mark searchable properties with `@Property(indexingKey:)`. If the app already reindexes through Core Spotlight, that's enough. Otherwise implement `IndexedEntityQuery` so the system can ask the app to re-index on demand. Keeping the index current (add **and** update **and** delete) is what makes "the note about the budget" resolvable.

## IntentValueQuery — search beyond the index

For content too large to index, server-side, fast-changing, or visual, use `IntentValueQuery` (iOS 26+). The system hands a **structured** input and the app returns entities (often a `@UnionValue`). It's also the protocol behind Visual Intelligence (input `SemanticContentDescriptor`).

For the chosen input type, inspect its cases in the SDK and implement `values(for:)`. For visual queries, use `SemanticContentDescriptor` as shown in `siri-integration.md`. Return only results the current account can access; bound network requests and result counts.

Use `IndexedEntity` for stable, indexable content and `IntentValueQuery` for everything else — they're complementary.

## EntityCollection — fast bulk operations

A parameter typed as `EntityCollection<T>` stores entity **identifiers** rather than fully resolved entities. The system passes only IDs into `perform()`, skipping expensive resolution. Revalidate ownership/access for every identifier before changing records.

```swift
struct TagPhotosIntent: AppIntent {
    static let title: LocalizedStringResource = "Tag Photos"

    @Parameter(title: "Photos")
    var photos: EntityCollection<PhotoEntity>

    @Parameter(title: "Tag")
    var tag: String

    func perform() async throws -> some IntentResult {
        // Operate on IDs directly — no resolution cost
        try await PhotoStore.shared.tag(ids: photos.identifiers, with: tag)
        return .result()
    }
}
```

Reach for this whenever an intent might receive a large set of entities.

## RelevantEntities — proactive suggestions

Suggest entities to the system *with a context* so relevant content can surface (e.g. a brand-new running playlist appearing when a workout starts).

```swift
import HealthKit // for AudioContext.workout(activityType:)

try await RelevantEntities.shared.updateEntities(
    workoutPlaylists,
    for: .audio(.workout(activityType: .running))
)

// Housekeeping
try await RelevantEntities.shared.removeEntities(stalePlaylists, from: .audio(.workout(activityType: .running)))
try await RelevantEntities.shared.removeAllEntities(for: .audio(.workout(activityType: .running)))
try await RelevantEntities.shared.removeAllEntities()
```

## SyncableEntity — cross-device continuity

For a Siri conversation to continue across devices, entity IDs must be stable everywhere. If IDs are already stable (server UUID, CloudKit record ID), just conform:

```swift
extension RecipeEntity: SyncableEntity {}   // id is a server UUID → done
```

If the local ID is device-specific, pair it with a stable one:

```swift
struct RecipeEntity: SyncableEntity {
    let id: SyncableEntityIdentifier<LocalID, ServerUUID>
    // ...
}
```

## ValueRepresentation & Transferable — moving content across apps

`ValueRepresentation` / `IntentValueRepresentation` (iOS 26.4+) export an entity as a structured **system** type so it flows into other apps. Example: expose a landmark as a `PlaceDescriptor` (GeoToolbox) so Maps can give directions.

```swift
import CoreTransferable
import GeoToolbox

struct LandmarkEntity: AppEntity, Transferable {
    // ...
    var placeDescriptor: PlaceDescriptor {
        PlaceDescriptor(representations: [.coordinate(coordinate)], commonName: name)
    }

    static var transferRepresentation: some TransferRepresentation {
        IntentValueRepresentation(exporting: { (entity: LandmarkEntity) in
            entity.placeDescriptor
        })
    }
}
```

For round-tripping content *into* the app (create-on-import), use `IntentValueRepresentation(exporting:importing:)`. For file/data payloads, also conform to `Transferable` with File and Data representations as usual — App Intents understands both.

## @UnionValue — multi-type parameters

A `@UnionValue` enum lets one parameter accept several entity types. Each case wraps a different type; the macro synthesizes type info, `typeDisplayRepresentation`, `caseDisplayRepresentations`, and picker support, and it works in Shortcuts and Visual Intelligence.

```swift
@UnionValue
enum PhotoSource {
    case landmark(LandmarkCollectionEntity)
    case album(AlbumEntity)
}

struct ShowPhotosIntent: AppIntent {
    @Parameter var source: PhotoSource
    // perform() switches on source
}
```

## Computed & deferred properties

- `@ComputedProperty` reads straight from the source of truth (e.g. `UserDefaults`, a store) instead of copying a snapshot — use this for inexpensive values that need to stay current.
- `@DeferredProperty` provides an async getter the system calls **only** when it genuinely needs an expensive value (network/ML). Reserve it for real cost.

```swift
struct SettingsEntity: AppEntity {
    @ComputedProperty var isPro: Bool { UserDefaults.standard.bool(forKey: "isPro") }
    @DeferredProperty var enrichedProfile: Profile { get async throws { try await API.profile() } }
}
```

## LongRunningIntent & cancellation

Ordinary intents have a limited execution budget; do not rely on an exact timeout. `LongRunningIntent` runs past it, manages the background-task lifecycle, and shows progress as a **Live Activity** (building on `ProgressReportingIntent`). Conform to `CancellableIntent` to clean up gracefully.

```swift
struct ExportLibraryIntent: LongRunningIntent, CancellableIntent {
    static let title: LocalizedStringResource = "Export Library"

    func perform() async throws -> some IntentResult {
        progress.totalUnitCount = Int64(items.count)
        try await performBackgroundTask {
            for (i, item) in items.enumerated() {
                try Task.checkCancellation()
                try await export(item)
                progress.completedUnitCount = Int64(i + 1)
            }
        } onCancel: { reason in
            // The onCancel handler is synchronous and @Sendable.
            // Signal cancellation here; await resource cleanup in perform().
            cancellationState.cancel(reason)
        }
        return .result()
    }
}
```

GPU work can request `LongRunningTaskOptions.requiresGPU` where supported. Check the task’s entitlement, runtime, and cancellation requirements before adopting it.

## ExecutionTargets — choosing the process

When intents live in a Swift package linked by both the app and its extensions, the system's process heuristics aren't always right. Override with `allowedExecutionTargets`:

```swift
struct SaveDraftIntent: AppIntent {
    // Writes need the main app:
    static var allowedExecutionTargets: IntentExecutionTargets { [.main] }
}
// Options: .main, .appIntentsExtension, .widgetKitExtension — or a combination
// like [.main, .appIntentsExtension] to let the system choose between them.
```

Choose a target that actually contains the intent and can access its dependencies. `.main` means the main app process, not the main actor. Extensions can perform authorized writes to shared data; they are not inherently display-only.

## Richer parameter types

`@Parameter` now natively supports more types, each with a system picker that works across Siri, Shortcuts, and Widgets — no custom UI needed:

- `Duration` (instead of hand-rolled time pickers)
- `PersonNameComponents`
- the union/multi-type parameters via `@UnionValue` above

## Interactive snippets

`SnippetIntent` (iOS 26+) powers two kinds of inline UI:

- **Result snippets** — show information, no confirmation.
- **Confirmation snippets** — `requestConfirmation(actionName:snippetIntent:)` before a side effect.

Buttons and toggles inside a snippet each fire an App Intent; share state across snippet reloads with `@Dependency` so values persist and animate. Design guidance: large type, generous spacing, content under ~340 points, and `ContainerRelativeShape` for responsive margins.

```swift
struct OrderConfirmationSnippet: SnippetIntent {
    static let title: LocalizedStringResource = "Confirm Order"
    func perform() async throws -> some IntentResult & ShowsSnippetView {
        .result(view: OrderSummaryView(order: order))
    }
}
```

Reviewed 2026-10-16 with Xcode 27.0 / iOS 27.0 SDK. Primary reference: [App entities](https://developer.apple.com/documentation/appintents/app-entities). Availability and runtime behavior must be checked for the app’s actual platforms.
