# SwiftData and observable fetches

Checked 2026-10-16 against Xcode 27.0 (27A266a), Swift 6.4, and the iOS 27 SDK. Availability below is per API, not the skill name.

Use `@Query` for live results in a SwiftUI view. Use `ModelContext` and `FetchDescriptor` when a service needs an explicit fetch. Keep model instances within their context/isolation; pass identifiers or sendable values across actor boundaries. A context created inside a main-actor `Task` isn't automatically a background context. Consider `@ModelActor` for a dedicated persistence service.

## Version 27 additions

`ResultsObserver<Element, SectionTitle>` can observe results outside a view. The unsectioned form uses `Never` as the second generic parameter. Its initializer **throws** and takes `fetchDescriptor:` and `modelContext:`; `results` is a `FetchResultsCollection`, not `[Element]`.

```swift
import SwiftData

@available(iOS 27.0, macOS 27.0, *)
@MainActor
func observe<Model: PersistentModel>(
    _ type: Model.Type, in context: ModelContext
) throws -> ResultsObserver<Model, Never> {
    try ResultsObserver(fetchDescriptor: FetchDescriptor<Model>(),
                        modelContext: context)
}
```

Retain the observer for the required lifetime. Avoid copying all results to an array on every view evaluation merely to satisfy an incorrectly typed property.

Sectioned results use **`SectionedResults<Element, SectionTitle>`**, with the model first. Use the current SwiftUI/SwiftData `@Query(sectionBy:...)` overload and sort rules; don't invert the generic arguments or guess argument labels. Test section membership changes, deletion, and empty sections in the actual persistent store.

`@Attribute(.codable)` is available in version 27 for opaque Codable value storage. Its nested fields aren't queryable/sortable attributes. Keep decoding backward compatible and test existing stores when evolving the type. If the app needs relationships or queries into nested data, model those properties explicitly.

`HistoryObserver` observes history changes. Its throwing initializer takes `historyTokens:observedModels:authors:modelContainer:isolation:`. Use persistent history tokens and reconciliation logic to process transactions; merely observing an event counter is not a complete sync implementation. Separate local and remote authors to prevent loops when syncing is actually requested.

For enum/composite predicates and any new query form, compile the specific predicate and exercise it against the real store implementation. A macro typecheck alone doesn't prove a store can execute every predicate. Preserve a working older-target representation until migration is required.

Official sources: [SwiftData](https://developer.apple.com/documentation/swiftdata), [ResultsObserver](https://developer.apple.com/documentation/swiftdata/resultsobserver), [HistoryObserver](https://developer.apple.com/documentation/swiftdata/historyobserver), [ModelActor](https://developer.apple.com/documentation/swiftdata/modelactor).
