---
name: swiftui-performance-profiling
description: Expert guidance on profiling and diagnosing SwiftUI performance issues using Instruments. Use when debugging slow UI, finding why views re-evaluate, identifying hitches/hangs, profiling with the SwiftUI instrument, understanding view identity and dependencies, migrating to @Observable, or optimizing List/Table performance. Covers the WWDC 2023-2025 performance mental model and systematic debugging workflows.
license: MIT
---

# SwiftUI Performance Profiling

Diagnose and fix performance issues using Apple's tools and mental model.

## The Performance Mental Model

Two common SwiftUI update bottlenecks are:

1. **View bodies run too often** — unnecessary dependency triggers
2. **View bodies run too slow** — expensive work in body computation

Understanding SwiftUI's **dependency graph** reveals both: state changes → dependencies evaluated → affected view bodies called → diff and render.

### Frame Budget Reality

| Display | Frame Time | Practical Budget |
|---------|------------|------------------|
| 60 Hz   | 16.67ms    | ~12ms            |
| 120 Hz  | 8.33ms     | ~5ms             |

Measure the total update and render work against the target display deadline. There is no universal safe number of view-body evaluations per frame; their cost and the rest of the pipeline determine the impact.

### Hangs vs Hitches

- **Hang**: Delay responding to interaction (tap takes too long)
- **Hitch**: Animation stutter, dropped frames, jerky scrolling

Either can also come from I/O, synchronization, layout, commit, image decoding, the render server or GPU work. Correlate the relevant tracks rather than assuming a view-body cause.

## Instruments Profiling Workflow

### Setup (Critical)

1. **Build for Profiling**: ⌘+I (not Debug builds)
2. **Use a physical device for performance claims**: Simulator is useful for investigation, but not hardware timing/battery evidence
3. **Release Mode**: Debug has vastly different characteristics

### SwiftUI Template

Select SwiftUI template in Instruments (Instruments 26 has enhanced SwiftUI instrument).

**Key Tracks:**

- **Update Groups**: Shows when SwiftUI is working (empty = problem elsewhere)
- **Long View Body Updates**: Color-coded warnings (orange = concern, red = likely hitch)
- **View Body Updates**: Individual view evaluations with duration

### Diagnostic Steps

```
1. Record interaction that feels slow
2. Check Update Groups lane — is SwiftUI even the problem?
3. Expand Long View Body Updates — which views are slow?
4. Check Count column — excessive re-evaluations?
5. Check Total Duration — expensive computations?
6. Use Time Profiler to see what's inside slow bodies
```

### Time Profiler Tips

- Enable "Hide System Libraries"
- Enable "Invert Call Tree"
- ⌘+F to search for specific view names
- Set inspection range to problematic interval

## Debugging Why Views Update

### _printChanges() (Dev Only)

```swift
var body: some View {
    let _ = Self._printChanges()  // REMOVE before shipping!
    // ...
}
```

**Output meanings:**

| Output | Meaning |
|--------|---------|
| `@self changed` | View's value/properties changed |
| `@propertyName changed` | Specific @State property changed |
| `@Observable changed` | Observable dependency changed |

### Common unexpected updates

Inspect values and dependencies passed into the view, including closures and broad observable objects. A method reference is not a guaranteed stable closure identity and is not a universal performance fix. Use Instruments and temporary `_printChanges()` output to confirm a change reduces meaningful work. Exact debug output is implementation detail; an update is not necessarily a visible redraw.

## View Identity & Performance

Identity determines whether SwiftUI **updates** (cheap) or **recreates** (expensive).

### Structural vs Explicit Identity

```swift
// Structural: Position in hierarchy determines identity
VStack {
    Text("A")  // Identity from position 0
    Text("B")  // Identity from position 1
}

// Explicit: You assign identity
ForEach(items, id: \.id) { item in
    ItemRow(item: item)
}
```

### Conditional Identity Trap

```swift
// BAD: Each branch = different identity = state destroyed
if dayTime {
    CatView().modifier(.day)   // Identity A
} else {
    CatView().modifier(.night) // Identity B
}

// GOOD: Single identity, state preserved
CatView()
    .opacity(dayTime ? 1.0 : 0.3)
```

Switching branches forces teardown + reconstruction. Use **inert modifiers** (`opacity(1.0)`, `padding(0)`) which SwiftUI prunes efficiently.

### Stable ForEach Identity

```swift
// BAD: Index-based identity breaks on reorder/insert
ForEach(items.indices, id: \.self) { index in
    ItemRow(item: items[index])
}

// GOOD: Content-based stable identity
ForEach(items, id: \.id) { item in
    ItemRow(item: item)
}
```

## @Observable Migration (iOS 17+)

### The Performance Win

With `ObservableObject`: ANY `@Published` change → ALL observing views update.
With `@Observable`: Only views reading changed properties update.

```swift
// Before: HeaderView updates when downloadProgress changes!
class ViewModel: ObservableObject {
    @Published var userName: String = ""        // HeaderView reads this
    @Published var downloadProgress: Double = 0 // Frequent updates
}

// After: HeaderView only updates when userName changes
@Observable class ViewModel {
    var userName: String = ""
    var downloadProgress: Double = 0
}
```

### Migration Table

| Old | New (iOS 17+) |
|-----|---------------|
| `@StateObject` | `@State` |
| `@ObservedObject` | Plain property or `@Bindable` |
| `@EnvironmentObject` | `@Environment` |
| `@Published var` | Plain `var` |

### Choosing Wrappers with @Observable

```swift
// Owned by this view? → @State
@State private var viewModel = ViewModel()

// From environment? → @Environment
@Environment(ViewModel.self) var viewModel

// Need bindings? → @Bindable
@Bindable var viewModel: ViewModel

// Just reading? → Plain property
let viewModel: ViewModel
```

## List & Table Optimization

### Constant View Count Rule

List/Table gather identifiers **eagerly**. Variable view counts defeat lazy loading.

```swift
// BAD: 0 or 1 views per element — must build ALL to count
List {
    ForEach(dogs) { dog in
        if dog.likesBall {  // Variable count!
            DogCell(dog: dog)
        }
    }
}

// BAD: AnyView hides type info — same problem
List {
    ForEach(dogs) { dog in
        AnyView(DogCell(dog: dog))
    }
}

// GOOD: Filter in model, constant 1 view per element
List {
    ForEach(filteredDogs) { dog in
        DogCell(dog: dog)
    }
}
```

### Explicit IDs on rows

`ForEach` already supplies stable element identity. Redundant or changing `.id()` can affect state lifetime and list construction. An explicit ID can also be needed for scrolling. Measure on the supported OS before removing it; this is not a blanket prohibition and does not always disable laziness.

## Performance Anti-Patterns

### Expensive Work in Body

```swift
// BAD: DateFormatter created every evaluation
var body: some View {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    Text(formatter.string(from: date)).monospacedDigit()
}

// A cached formatter can help, but must respond to locale/calendar changes.
// Prefer a format style for ordinary displayed dates; example below:
private static let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .medium
    return f
}()

var body: some View {
    Text(date, format: .dateTime.month().day().year()).monospacedDigit()
}
```

### Declaring Unused Dependencies

```swift
// BAD: Updates on ANY store change even though not used
struct StaticView: View {
    @EnvironmentObject var store: Store  // Declared but body ignores it
    var body: some View {
        Text("Static content")  // Still re-evaluates!
    }
}

// GOOD: Don't declare what you don't read
struct StaticView: View {
    var body: some View {
        Text("Static content")
    }
}
```

### Passing entire objects

For a value-type model, passing only the needed fields can reduce dependency breadth. For an `@Observable` reference, SwiftUI tracks property reads in `body`, so passing the object itself does not automatically subscribe the view to every property. Choose the data flow for correctness first and measure the affected updates before redesigning it.

## Interpreting measurements

Continuous animation must meet the display's frame deadline (about 8.3 ms at 120 Hz or 16.7 ms at 60 Hz), with other pipeline work consuming part of that budget. Apple's responsiveness guidance suggests keeping main-thread update work below roughly 5 ms where possible. A delay well under 100 ms can still cause a visible animation hitch.

The roughly 100 ms threshold concerns noticeable latency in a discrete interaction, not an acceptable animation hitch. Use Instruments to measure missed frame deadlines, hitch duration, and the expensive work contributing to each update. View-body duration and evaluation count are diagnostic clues, not universal pass/fail thresholds.

Source: [Improving app responsiveness](https://developer.apple.com/documentation/xcode/improving-app-responsiveness).

## Essential WWDC Sessions

- **Demystify SwiftUI** (WWDC21) — Identity, lifetime, dependencies
- **Demystify SwiftUI performance** (WWDC23) — Mental model, optimization
- **Discover Observation in SwiftUI** (WWDC23) — @Observable deep dive
- **Optimize SwiftUI performance with Instruments** (WWDC25) — New tooling

## See Also

- `references/instruments-workflows.md` — Detailed profiling walkthroughs
- `references/migration-patterns.md` — @Observable migration recipes

## Validation and sources

Checked 2026-10-16 with Xcode 27.0 (27A266a). Profiling guidance is diagnostic, not a device benchmark of this collection. Keep migrations scoped to a measured need; preserve older targets and Combine subscriptions when required. `async` and `.task` do not by themselves move CPU work off the main actor. Numeric output uses tabular digits and stable widths for changing fields.

Primary sources: [Demystify SwiftUI performance](https://developer.apple.com/videos/play/wwdc2023/10160/), [Observation migration](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro), [Improving responsiveness](https://developer.apple.com/documentation/xcode/improving-app-responsiveness).
