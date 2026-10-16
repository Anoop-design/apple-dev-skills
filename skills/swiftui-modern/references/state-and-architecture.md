# State, ownership, and identity

Checked 2026-10-16 against Xcode 27.0 (27A266a), Swift 6.4, and the iOS 27 SDK. Availability below is per API, not the skill name.

## Choose by ownership and deployment target

| API | Use |
|---|---|
| `@State` | Private view-owned value state or a view-owned `@Observable` instance |
| `@Binding` | Edit state whose ownership/lifetime is elsewhere |
| `@Bindable` | Produce bindings to an existing Observation model |
| `@Environment` | Read system values or an explicitly injected shared dependency |
| `@Observable` | Model reference types with property-level observation (iOS 17+) |
| `@StateObject` / `@ObservedObject` | Existing `ObservableObject` ownership/observation, including older targets |

Don't rewrite an established architecture to change a small feature. Migrate to Observation incrementally; remove `@Published` from properties managed by `@Observable`, and account for any existing Combine subscribers separately. Observation doesn't automatically replace a publisher pipeline.

For an Observation model, SwiftUI tracks observable properties accessed during evaluation. Passing a model reference to a leaf view doesn't itself subscribe the parent to every property. Passing a computed property value makes its read happen in the parent. Choose the boundary that localizes real dependencies; don't always replace a model argument with scalar values.

## Xcode 27 State migration

The Xcode 27 SDK makes `@State` a macro, lazily creating initial state. This addresses repeated construction of discarded default objects; it does **not** mean older `@State` normally reset persistent state on every parent update. State lifetime still follows view identity.

An explicit initializer can initialize the declared property directly. Avoid an inline default plus an early read/reassignment that violates Swift definite initialization. Keep side effects out of model construction; use a controlled lifecycle task for work that can be canceled. Consult [TN3211](https://developer.apple.com/documentation/technotes/tn3211-resolving-swiftui-source-incompatibilities-for-state-and-contentbuilder) for source incompatibilities and check the generated code when migrating.

## Identity

Use stable model identifiers for changing `ForEach` data. Indices work for a truly fixed collection but identify positions, not moving or deleted objects. Changing `.id(...)` resets the associated subtree; use it deliberately.

Prefer concrete types, generics, and `@ViewBuilder` for ordinary composition. `AnyView` is valid when runtime type erasure is actually needed; it isn't universally forbidden. Measure large-list effects and understand identity changes instead of assuming every erased view loses state.

Keep view initializers and `body` inexpensive and free of externally visible side effects. SwiftUI can create view values and evaluate bodies without later displaying them. Split subviews when it improves dependency scope, reuse, or readability; every computed property doesn't create an independent update boundary.

## Isolation and dependency scope

Use the main actor for UI-owned mutable state; use deliberately isolated services for background work. Actors are reentrant across `await`; protect invariants that span suspension points and don't assume actor isolation prevents overlapping requests.

Environment values are scoped to the view hierarchy, and deeper values override outer values. A type-based observable lookup requires an instance injected in scope. Use initializer injection for explicit/testable dependencies where it fits; don't classify the environment as inherently global. Define custom keys with `@Entry` when the build toolchain supports the macro.

Equatable views are an optimization to evaluate when input comparison is cheaper than reevaluating an expensive body. Use `.equatable()`/`EquatableView` when appropriate; a conformance alone isn't a universal skip-render guarantee. Internal state and environment can still cause updates. Equality must reflect all externally supplied data that affects output.

Official sources: [Managing model data in your app](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app), [State](https://developer.apple.com/documentation/swiftui/state), [Migrating from ObservableObject to Observable](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro).
