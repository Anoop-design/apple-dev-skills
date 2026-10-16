# Xcode 27 / SwiftUI adoption notes

Checked 2026-10-16 against Xcode 27.0 (27A266a), Swift 6.4, and the iOS 27 SDK. Availability below is per API, not the skill name.

Use these notes for a requested migration or feature. Most additions are runtime APIs; do not raise deployment targets merely because the SDK is newer. Compiler changes such as `State`/`ContentBuilder` are distinct from OS availability.

| Area | Verified SDK surface and useful caution |
|---|---|
| State and builders | Xcode 27 introduces the `State()` macro and unified `ContentBuilder`; follow TN3211 for source incompatibilities |
| Reordering | `reorderable()` and the **view modifier** `reorderContainer(for:isEnabled:move:)`; it has no `content:` closure |
| Swipe actions | `swipeActionsContainer()` and `swipeActions(...onPresentationChanged:)` extend presentation outside `List`; check platform annotations |
| Toolbar overflow | `ToolbarOverflowMenu` is iOS/visionOS 27, unavailable on macOS/watchOS/tvOS; don't apply it indiscriminately |
| Toolbar priority | `visibilityPriority(_:)` takes `ToolbarItemVisibilityPriority`, not an arbitrary number; macOS support starts at 26.1 |
| Images | `AsyncImage(request:)` and `asyncImageURLSession(_:)` are version 27 additions; test real cache headers/cache policy rather than assuming all image responses cache |
| Navigation | `CrossFadeNavigationTransition` and `AnyNavigationTransition` are new; custom transition conformances aren't implied |
| Documents | `ReadableDocument` / `WritableDocument` and reader/writer abstractions are new; check complete associated-type requirements before migrating |
| Persistence | See [SwiftData](data-and-swiftdata.md) for sectioned results, observers, and opaque Codable attributes |

Do not paste incomplete document protocol examples that treat `DocumentReader` or `DocumentWriter` protocols as concrete generic objects. Use Apple's complete document sample and preserve undo/dirty tracking, file coordination, error handling, and save behavior. Existing `FileDocument`/`ReferenceFileDocument` apps don't need an unsolicited rewrite.

For reordering, apply the returned `ReorderDifference` using its documented collection/identifier semantics. It is not an ordinary `CollectionDifference` with a guessed `applied(to:)` method. Test moves across the actual sections and persistent order.

Item/error alert overloads are not interchangeable with the older `alert(item:content:)` API returning `Alert`. Choose the intended overload from the actual SDK and compile it in context. Don't guess new argument labels from a presentation slide.

When adopting the iOS 27 SDK, verify scene lifecycle requirements and container resizing in the app's existing scene architecture. No hardware-specific fold/hinge API should be inferred from general adaptive-layout announcements. Use current container sizes and safe areas, and test the actual display modes requested.

Official sources: [SwiftUI updates](https://developer.apple.com/documentation/updates/swiftui), [TN3211: State and ContentBuilder incompatibilities](https://developer.apple.com/documentation/technotes/tn3211-resolving-swiftui-source-incompatibilities-for-state-and-contentbuilder), [TN3187: Migrating to the UIKit scene-based life cycle](https://developer.apple.com/documentation/technotes/tn3187-migrating-to-the-uikit-scene-based-life-cycle), [SwiftUI](https://developer.apple.com/documentation/swiftui).
