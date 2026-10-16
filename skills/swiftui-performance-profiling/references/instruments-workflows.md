# Instruments Workflows for SwiftUI

Detailed step-by-step profiling procedures for common performance scenarios.

## Workflow 1: Diagnosing Scroll Performance

**Symptom**: List or ScrollView stutters, drops frames during scroll.

### Steps

1. **Launch Instruments**
   - In Xcode: Product → Profile (⌘+I)
   - Select "SwiftUI" template

2. **Configure Recording**
   - Connect physical device (required for accurate timing)
   - Verify Release configuration in scheme

3. **Record Scroll Interaction**
   - Click Record
   - In app: Scroll the problematic list at normal speed for 5-10 seconds
   - Click Stop

4. **Analyze Update Groups Lane**
   - If the stalled interval has no SwiftUI work → inspect other CPU threads, I/O, synchronization, commit and GPU work
   - If continuous work → inspect its cost and correlation with missed deadlines; activity alone does not prove the bottleneck

5. **Check Long View Body Updates**
   - Red bars = immediate priority
   - Orange bars = investigate
   - Click a bar to see which view

6. **Drill Into Slow Views**
   - Select the slow view row
   - Click "Show Updates" to see timeline of all evaluations
   - Note: Is it called excessively? Is each call slow?

7. **Time Profiler Cross-Reference**
   - Set inspection range to a slow frame (drag select in timeline)
   - Switch to Time Profiler track
   - Enable: Call Tree → Invert Call Tree, Hide System Libraries
   - Find what code is slow within the view body

### Common Findings

| Finding | Likely Cause | Fix |
|---------|--------------|-----|
| Cell view called 100s of times | Variable view count in ForEach | Use constant view count, filter in model |
| A costly body consumes the frame budget | Expensive computation | Cache with valid invalidation or move suitable work to an explicit non-main execution context |
| Same view called repeatedly | Unstable identity | Use stable id, check ForEach |

---

## Workflow 2: Finding Excessive Re-Renders

**Symptom**: UI feels sluggish, animations stutter during state changes.

### Steps

1. **Add _printChanges() Temporarily**
   ```swift
   var body: some View {
       let _ = Self._printChanges()
       // existing code
   }
   ```

2. **Identify Suspects**
   - Run app in Debug
   - Perform the slow interaction
   - Watch console for view names printing repeatedly

3. **Profile with Instruments**
   - Build for Profiling (⌘+I)
   - Select SwiftUI template
   - Record the same interaction

4. **Sort by Count**
   - In View Body Updates detail pane
   - Click "Count" column header to sort descending
   - High counts = views evaluating too often

5. **Investigate Dependencies**
   Questions to ask:
   - Is this view observing an ObservableObject it doesn't need?
   - Is parent passing a new closure each render?
   - Is view receiving entire object when it only needs one property?

### Common Patterns

**Over-broad ObservableObject dependency:**
```swift
// Problem: Child updates when ANY @Published changes
struct Child: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        Text(store.userName)  // Only needs userName
    }
}

// Fix 1: Pass only what's needed
struct Child: View {
    let userName: String
    var body: some View { Text(userName) }
}

// Fix 2: Use @Observable (iOS 17+)
@Observable class AppStore {
    var userName: String = ""
    var unrelatedData: [Item] = []  // Changes won't affect Child
}
```

**Closure dependencies:** Closures can contribute to changed view inputs, but substituting a method reference does not guarantee stable identity. Inspect captures, state ownership and measured update causes before changing the structure.

---

## Workflow 3: Animation Hitch Investigation

**Symptom**: Animation stutters, doesn't feel smooth 60fps.

### Steps

1. **Profile with SwiftUI + Core Animation**
   - In Instruments, add both templates to same document
   - Record the animation

2. **Check Frame Rate in Core Animation**
   - Look for dips below 60fps (or 120 for ProMotion)
   - Note exact timestamps of drops

3. **Cross-Reference SwiftUI Track**
   - At timestamps of frame drops, what's happening in SwiftUI?
   - Look for view body updates during animation

4. **Identify animation-time work**
   - View-body evaluation during animation can be expected for custom animatable views.
   - Correlate cost, dependency breadth and layout with missed frame deadlines.
   - Rendering-only transformations can be cheaper than a large layout change, but animate layout when the interaction needs it and measure the result.
   - Scope `.animation(_:value:)` to the relevant subtree. It can animate other changes occurring in that transaction too.
   - Extract frequently changing dependencies into small views when measurement justifies it. Replacing a VStack with a ZStack changes layout and does not itself guarantee update isolation.

---

## Workflow 4: List/Table Lazy Loading Verification

**Symptom**: Large list takes long to appear, memory spikes on load.

### Steps

1. **Profile Initial Load**
   - Record from app launch through list display
   - Note total time and view counts

2. **Check View Creation Pattern**
   - In View Body Updates, filter to your cell view type
   - Count how many were created

3. **Verify Lazy Loading**
   - Compare view-body evaluations and allocation cost with the visible content and prefetching; there is no fixed initial cell count
   - If the entire dataset is eagerly evaluated, inspect variable row counts/type erasure and explicit identity on that OS

4. **Find the Cause**

   **Check for conditional content:**
   ```swift
   // Can increase construction work; measure this case
   ForEach(items) { item in
       if item.isVisible {
           ItemCell(item: item)
       }
   }
   ```

   **Check for AnyView:**
   ```swift
   // Can increase construction work; measure this case
   ForEach(items) { item in
       AnyView(ItemCell(item: item))
   }
   ```

   **Check for .id() modifier:**
   ```swift
   // Can increase construction work; measure this case
   List(items) { item in
       ItemCell(item: item)
           .id(item.objectID)
   }
   ```

---

## Workflow 5: Memory Profiling for View Leaks

**Symptom**: Memory grows over time, views not deallocating.

### Steps

1. **Add Allocations Instrument**
   - Use "Leaks" template or add Allocations to existing document

2. **Record Navigation Cycle**
   - Navigate to a screen
   - Navigate back
   - Repeat 5 times

3. **Check for Growth**
   - Inspect retained reference-type models, controllers and backing allocations
   - Look for persistent monotonic growth after allowing caches and deferred cleanup to settle
   - Growth merits investigation; expected caches are not automatically leaks

4. **Common SwiftUI Retain Cycles**

   **Reference owners and async lifetime:**
   SwiftUI View values are usually structs, so `[weak self]` cannot be applied to them. Inspect reference-type models/services, retained callbacks, timers and subscriptions for cycles. A `.task` ties cancellation to view lifetime, but the async operation must cooperate with cancellation; it is not automatic leak prevention. Keep task captures and results appropriate for their actor.

   **Timer not invalidated:**
   ```swift
   // Problem: Timer holds reference
   @State private var timer: Timer?

   .onAppear {
       timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
           // work
       }
   }
   // Missing .onDisappear { timer?.invalidate() }
   ```

---

## Quick Reference: Instruments Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘R | Start/Stop Recording |
| ⌘E | Export Document |
| ⌘+/- | Zoom Timeline |
| Option+drag | Select Time Range |
| ⌘F | Find/Filter |
| Space | Pause/Resume during record |

## Profiling Checklist

Before each profiling session:

- [ ] Physical device connected (not simulator)
- [ ] Release build configuration
- [ ] Build for Profiling (⌘+I), not Run
- [ ] Close other apps on device
- [ ] Device not in Low Power Mode
- [ ] Know exactly what interaction to test
- [ ] Ready to record 5-10 seconds of that interaction
