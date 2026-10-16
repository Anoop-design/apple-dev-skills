# @Observable Migration Patterns

Recipes for migrating from ObservableObject to @Observable (iOS 17+).

## Why Migrate?

**Performance gain**: `@Observable` provides property-level tracking. Only views reading a changed property re-render, not all views observing the object.

```swift
// ObservableObject: Change ANY @Published → ALL observers update
// @Observable: Change property X → only views reading X update
```

It can reduce broad update dependencies. Measure the actual bottleneck before migrating; keep a working architecture and supported OS range when migration is unrelated to the task.

---

## Pattern 1: Simple ViewModel Migration

### Before (ObservableObject)

```swift
class ProfileViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var isLoading: Bool = false

    func load() {
        isLoading = true
        // fetch...
    }
}

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        Form {
            TextField("Name", text: $viewModel.name)
            TextField("Email", text: $viewModel.email)
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .onAppear { viewModel.load() }
    }
}
```

### After (@Observable)

```swift
@Observable
class ProfileViewModel {
    var name: String = ""
    var email: String = ""
    var isLoading: Bool = false

    func load() {
        isLoading = true
        // fetch...
    }
}

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()

    var body: some View {
        @Bindable var vm = viewModel  // For bindings
        Form {
            TextField("Name", text: $vm.name)
            TextField("Email", text: $vm.email)
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .onAppear { viewModel.load() }
    }
}
```

**Key changes:**
- `@StateObject` → `@State`
- Remove `@Published` (all properties auto-tracked)
- Add `@Bindable` local variable for bindings

---

## Pattern 2: Environment Object Migration

### Before

```swift
class AppStore: ObservableObject {
    @Published var user: User?
    @Published var settings: Settings
    @Published var notifications: [Notification] = []
}

// At app root
ContentView()
    .environmentObject(store)

// In child view
struct SettingsView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        Toggle("Dark Mode", isOn: $store.settings.darkMode)
    }
}
```

### After

```swift
@Observable
class AppStore {
    var user: User?
    var settings: Settings
    var notifications: [Notification] = []
}

// At app root
ContentView()
    .environment(store)  // Note: .environment, not .environmentObject

// In child view
struct SettingsView: View {
    @Environment(AppStore.self) var store

    var body: some View {
        @Bindable var store = store
        Toggle("Dark Mode", isOn: $store.settings.darkMode)
    }
}
```

**Key changes:**
- `.environmentObject()` → `.environment()`
- `@EnvironmentObject` → `@Environment(Type.self)`
- Add `@Bindable` for bindings

---

## Pattern 3: Passed Object (ObservedObject)

### Before

```swift
struct ItemRow: View {
    @ObservedObject var item: ItemModel

    var body: some View {
        HStack {
            Text(item.title)
            Spacer()
            if item.isComplete {
                Image(systemName: "checkmark")
            }
        }
    }
}
```

### After

```swift
struct ItemRow: View {
    var item: ItemModel  // Plain property - no wrapper needed

    var body: some View {
        HStack {
            Text(item.title)
            Spacer()
            if item.isComplete {
                Image(systemName: "checkmark")
            }
        }
    }
}
```

**Key changes:**
- `@ObservedObject` → remove wrapper entirely
- Object is still tracked automatically when accessed in body

---

## Pattern 4: Binding to Observable Properties

### Before

```swift
struct EditView: View {
    @ObservedObject var item: ItemModel

    var body: some View {
        TextField("Title", text: $item.title)
    }
}
```

### After

```swift
struct EditView: View {
    @Bindable var item: ItemModel  // Need @Bindable for $ syntax

    var body: some View {
        TextField("Title", text: $item.title)
    }
}
```

**Rule:** Use `@Bindable` when you need bindings (`$`) to an `@Observable` object's properties.

---

## Pattern 5: Nested Observable Objects

### Before (Problematic)

```swift
class Parent: ObservableObject {
    @Published var child: Child  // Nested ObservableObject doesn't propagate
}

class Child: ObservableObject {
    @Published var value: Int = 0
}
// Changes to child.value don't update views observing parent!
```

### After (Works Correctly)

```swift
@Observable
class Parent {
    var child: Child
}

@Observable
class Child {
    var value: Int = 0
}
// Changes to child.value properly tracked through parent
```

**@Observable handles nesting correctly** - no manual propagation needed.

---

## Pattern 6: Computed Properties

### Before

```swift
class CartViewModel: ObservableObject {
    @Published var items: [Item] = []

    var total: Double {
        items.reduce(0) { $0 + $1.price }
    }
    // An observing view DOES update when @Published items changes;
    // total is recomputed when the view reads it.
}
```

### After

```swift
@Observable
class CartViewModel {
    var items: [Item] = []

    var total: Double {
        items.reduce(0) { $0 + $1.price }
    }
    // total properly tracked - views update when items changes
}
```

Both versions can refresh the computed total when their dependencies change. Observation tracks the stored-property reads performed by the computation; it does not cache expensive computation or independently observe a nested non-observable reference.

---

## Pattern 7: Optional @Observable

### Handling Optional Observable Objects

```swift
@Observable
class UserSession {
    var user: User?
}

struct ProfileView: View {
    var session: UserSession

    var body: some View {
        if let user = session.user {
            @Bindable var user = user  // Local @Bindable for bindings
            TextField("Name", text: $user.name)
        } else {
            Text("Not logged in")
        }
    }
}
```

---

## Migration Checklist

For each ObservableObject class:

- [ ] Add `@Observable` macro to class
- [ ] Remove `ObservableObject` conformance
- [ ] Remove all `@Published` property wrappers
- [ ] Keep properties as plain `var`

For each view using the object:

- [ ] `@StateObject` → `@State` (if view owns the object)
- [ ] `@ObservedObject` → plain property or `@Bindable` (if bindings needed)
- [ ] `@EnvironmentObject` → `@Environment(Type.self)`

For environment injection:

- [ ] `.environmentObject(obj)` → `.environment(obj)`

For bindings:

- [ ] Add `@Bindable var local = observed` where `$` syntax needed

---

## Backward Compatibility

For apps supporting iOS 16 and earlier, keep `ObservableObject`/`@Published` in the compatible path or deliberately maintain separately availability-gated implementations. `#if canImport(Observation)` only checks whether the compiler can import the module; it does not make SwiftUI Observation integration available on an older running OS. Do not conditionally remove `@Published` based on that import check.

Import `Observation` in files that define `@Observable` models. Keep UI-owned mutable models on `@MainActor` where appropriate; the macro does not make shared mutable state thread-safe. Preserve Combine pipelines that relied on `$property` publishers or redesign them explicitly. Add initializers for required model properties; sketches with app-specific `Settings`, `User`, or `Child` types omit that setup.

## Performance Verification

After migration, verify improvement:

1. Add `Self._printChanges()` to views
2. Change one property
3. Confirm only views reading that property print

```swift
// In ProfileHeaderView
let _ = Self._printChanges()
// Should NOT print when unrelated properties change
```

Use Instruments to verify reduced view body evaluation counts.
