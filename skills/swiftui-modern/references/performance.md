# SwiftUI performance decisions

Checked 2026-10-16 against Xcode 27.0 (27A266a), Swift 6.4, and the iOS 27 SDK. Availability below is per API, not the skill name.

Start with an observed symptom and representative interaction. Keep I/O, sorting large collections, formatting repeated data, and other expensive work out of `body`. Cache only when measurements and invalidation rules justify it; a Swift computed property is not a cache.

Use stable collection identity. Prefer `List` for built-in list behavior such as selection, swipe actions, and reordering, or a scroll view with a lazy stack for custom presentation. Offscreen lifetime/recycling is implementation-dependent; don't rely on either container retaining or destroying a particular view at an exact scroll position.

Filtering before `ForEach` can avoid variable per-element row counts, especially in `List`, but don't turn this into a ban on all conditional content. Measure the relevant layout. Avoid unnecessary nested scrolling; nested scroll containers can be intentional when sized and coordinated correctly.

Do not move network requests or other side effects into view initializers to chase prefetch behavior. SwiftUI can initialize views speculatively and frequently. Use `.task(id:)` for cancelable lifetime-bound work and reserve `onAppear` for work that actually depends on appearance.

```swift
.task(id: query) {
    do {
        try await Task.sleep(for: .milliseconds(300))
        try Task.checkCancellation()
        await search(query)
    } catch is CancellationError {
        // A new query or disappearance canceled this task.
    } catch {
        // Handle a non-cancellation failure if the task adds throwing work.
    }
}
```

The app-owned `search` function should also cooperate with cancellation and reject obsolete results. A delay alone doesn't prevent a slow earlier response from overwriting a newer one.

Prefer typed composition to unnecessary `AnyView` erasure in hot paths; use erasure when the abstraction requires it. Verify performance before introducing equality-based skipping or custom caches.

Xcode 27 unifies result builders under `ContentBuilder`. It can improve typechecking, but doesn't prove an individual expression will compile quickly. For ambiguity, qualify conflicting type names and split complex expressions. Follow [TN3211](https://developer.apple.com/documentation/technotes/tn3211-resolving-swiftui-source-incompatibilities-for-state-and-contentbuilder) for actual migration errors.

Use Instruments when the issue is runtime cost: SwiftUI updates explain invalidations, Time Profiler finds CPU work, and animation/hitch tools show missed frame deadlines. Record before/after traces for the same scenario. No fixed rule about body count or subview count replaces profiling.

Official sources: [Understanding and improving SwiftUI performance](https://developer.apple.com/documentation/xcode/understanding-and-improving-swiftui-performance), [Demystify SwiftUI performance](https://developer.apple.com/videos/play/wwdc2023/10160/).
