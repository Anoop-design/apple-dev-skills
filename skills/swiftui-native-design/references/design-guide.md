# SwiftUI Native Design

Apply native design patterns to the requested screen or interaction. Preserve the project's deployment target and the user's visual direction. Treat examples and design values below as guidance for the affected UI; do not impose a redesign or full-app audit on a focused change.

## Core Design Principles

1. **Clarity** — Content is paramount. UI supports content, never competes with it
2. **Deference** — Fluid motion and crisp interface help understand content without competing
3. **Depth** — Visual layers and motion convey hierarchy and position

## Native Over Custom

Prefer system controls when they fit the interaction; preserve custom styling through ButtonStyle and other supported APIs:

```swift
// ✅ Native — adapts to platform, accessibility, future updates
Button("Add Item") { addItem() }
    .buttonStyle(.borderedProminent)

// ❌ Custom — misses system behaviors
Text("Add Item")
    .padding()
    .background(Color.blue)
    .onTapGesture { addItem() }
```

Native components automatically get:
- Dynamic Type support
- VoiceOver accessibility
- Appropriate platform interaction behavior (add haptics explicitly when needed)
- Dark mode adaptation
- Liquid Glass (iOS 26+)
- Localization support

## Typography

### Semantic Text Styles

```swift
Text("Welcome")
    .font(.largeTitle)      // 34pt - Page titles

Text("Section")
    .font(.title)           // 28pt - Section headers

Text("Subsection")
    .font(.title2)          // 22pt

Text("Headline")
    .font(.headline)        // 17pt semibold - List row titles

Text("Body text")
    .font(.body)            // 17pt - Primary content

Text("Supporting")
    .font(.subheadline)     // 15pt - Secondary info

Text("Detail")
    .font(.caption)         // 12pt - Timestamps, metadata

Text("Legal")
    .font(.footnote)        // 13pt - Fine print
```

### Typography Rules

Use tabular numerals for numeric UI: counters, timers, durations, dates, percentages, and metrics. In SwiftUI use `.monospacedDigit()`; in UIKit enable the tabular-number font feature. Keep the chosen font for letters. For changing values, reserve a stable field width that accommodates the expected range. Verify custom-font tabular glyph support and preserve the `tnum` feature when subsetting.

- **Scale type intentionally** — Prefer semantic styles; use scaled custom fonts or `@ScaledMetric` for a deliberate display size.
- **Preserve the type system** — San Francisco is a good default; keep an intentional custom font and verify its accessibility and numeric glyphs.
- **Hierarchy** — Use size, weight and spacing coherently.
- **Line limits thoughtfully** — `.lineLimit(2)` with `.truncationMode(.tail)`

```swift
// Proper text hierarchy
VStack(alignment: .leading, spacing: 4) {
    Text(item.title)
        .font(.headline)
    Text(item.subtitle)
        .font(.subheadline)
        .foregroundStyle(.secondary)
}
```

## Color System

### Semantic Colors

```swift
// Text
.foregroundStyle(.primary)      // Main text
.foregroundStyle(.secondary)    // Supporting text
.foregroundStyle(.tertiary)     // Disabled/hint text

// Backgrounds
.background(.background)        // View backgrounds
.background(Color(uiColor: .secondarySystemBackground))  // Grouped sections

// Interactive
.tint(.accentColor)            // Buttons, links, selection

// Status
Color.red                       // Errors, destructive
Color.green                     // Success
Color.orange                    // Warnings
Color.blue                      // Info, links
```

### Color Rules

- **Adaptive color** — Use semantic colors or light/dark asset variants for custom palettes.
- **Accent color defines brand** — Set in asset catalog, use `.tint()`
- **Contrast** — Aim for at least 4.5:1 for ordinary text and 3:1 for large/bold text; verify actual foreground/background combinations and applicable accessibility standards.
- **Test both appearances** — Light and dark mode

```swift
// ✅ Adapts to dark mode
Text("Label")
    .foregroundStyle(.primary)
    .background(Color(uiColor: .secondarySystemBackground))

// ❌ Breaks in dark mode
Text("Label")
    .foregroundColor(.black)
    .background(Color.white)
```

## Spacing System

### Standard Spacing Values

```swift
// Example spacing tokens; not an Apple-mandated scale
4   // Tight - between related items
8   // Compact - icon to label
12  // Default - list item padding vertical
16  // Example page margin; default padding varies by context
20  // Comfortable - section spacing
24  // Relaxed - group separation
32  // Loose - major sections
```

### Layout Margins

```swift
// Content respects safe areas
ScrollView {
    content
        .padding(.horizontal)  // Contextual default
        .safeAreaPadding()     // Adds safe-area padding; avoid doubling existing margins
}

// Full-width content extending to edges
ScrollView {
    Image(heroImage)
        .ignoresSafeArea(edges: .horizontal)
}
```

## SF Symbols

### Proper Symbol Usage

```swift
// Semantic weight matching
Label("Favorites", systemImage: "heart.fill")
    .font(.body)  // Symbol scales with text

// Explicit sizing
Image(systemName: "gear")
    .font(.system(size: 24))
    .symbolRenderingMode(.hierarchical)

// Symbol variants
Image(systemName: "heart")      // Outline
Image(systemName: "heart.fill") // Filled - selected state
```

### Symbol Rendering Modes

```swift
// Monochrome — single color
Image(systemName: "cloud.sun.fill")
    .symbolRenderingMode(.monochrome)

// Hierarchical — depth with single color
Image(systemName: "cloud.sun.fill")
    .symbolRenderingMode(.hierarchical)
    .foregroundStyle(.blue)

// Palette — multiple specific colors
Image(systemName: "cloud.sun.fill")
    .symbolRenderingMode(.palette)
    .foregroundStyle(.gray, .yellow)

// Multicolor — system colors
Image(systemName: "cloud.sun.fill")
    .symbolRenderingMode(.multicolor)
```

### Symbol Effects (iOS 17+)

```swift
Image(systemName: "bell")
    .symbolEffect(.bounce, value: notificationCount)
    .symbolEffect(.pulse)
    .symbolEffect(.variableColor.iterative)
```

## Liquid Glass (iOS 26+)

The new adaptive material for controls and navigation:

### Automatic Adoption

Standard components get Liquid Glass automatically:
- Navigation bars
- Tab bars
- Toolbars
- Sheets
- Segmented controls

### Custom Glass Effects

```swift
// Apply to custom views
MyCustomControl()
    .glassEffect()

// Shaped glass
MyBadge()
    .glassEffect(.regular, in: Capsule())

// Tinted glass
MyButton()
    .glassEffect(.regular.tint(.blue))

// Interactive glass (press effects)
Button("Tap Me") { }
    .glassEffect(.regular.interactive())
```

### Glass Containers

```swift
// Group glass elements for proper rendering
GlassEffectContainer {
    HStack {
        GlassButton("One")
        GlassButton("Two")
    }
}
```

### Glass Transitions

```swift
// Morph between glass elements
view
    .glassEffectID("myElement", in: namespace)
```

## Navigation Patterns

### Tab-Based Apps

```swift
TabView {
    HomeView()
        .tabItem {
            Label("Home", systemImage: "house")
        }

    SearchView()
        .tabItem {
            Label("Search", systemImage: "magnifyingglass")
        }

    ProfileView()
        .tabItem {
            Label("Profile", systemImage: "person")
        }
}
```

**Tab Bar Rules:**
- Keep primary destinations manageable; the appropriate count depends on device and adaptive layout.
- Most important destinations only
- Use `Tab(role: .search)` for dedicated search behavior when search belongs in the tab bar.
- Use coherent symbols and let native selection behavior supply variants where appropriate.

### Hierarchical Navigation

```swift
NavigationStack {
    List(items) { item in
        NavigationLink(value: item) {
            ItemRow(item: item)
        }
    }
    .navigationTitle("Items")
    .navigationDestination(for: Item.self) { item in
        ItemDetail(item: item)
    }
}
```

### Split View (iPad)

```swift
NavigationSplitView {
    // Sidebar
    List(categories, selection: $selectedCategory) { category in
        Label(category.name, systemImage: category.icon)
    }
} content: {
    // Content list
    if let category = selectedCategory {
        ItemList(category: category)
    }
} detail: {
    // Detail view
    if let item = selectedItem {
        ItemDetail(item: item)
    } else {
        ContentUnavailableView("Select an Item", systemImage: "doc")
    }
}
```

## Lists & Content

### Standard List

```swift
List {
    Section("Recent") {
        ForEach(recentItems) { item in
            ItemRow(item: item)
        }
    }

    Section("All Items") {
        ForEach(allItems) { item in
            ItemRow(item: item)
        }
    }
}
.listStyle(.insetGrouped)  // Explicit choice for grouped content
```

### List Row Design

```swift
struct ItemRow: View {
    let item: Item

    var body: some View {
        HStack(spacing: 12) {
            // Leading icon
            Image(systemName: item.icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.body)
                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Trailing accessory
            if item.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
            }
        }
        .padding(.vertical, 4)
    }
}
```

## Forms & Input

### Settings-Style Form

```swift
Form {
    Section {
        LabeledContent("Account", value: user.email)

        NavigationLink("Notifications") {
            NotificationSettings()
        }

        Toggle("Dark Mode", isOn: $prefersDarkMode)

        Picker("Language", selection: $language) {
            ForEach(languages) { lang in
                Text(lang.name).tag(lang)
            }
        }
    }

    Section {
        Button("Sign Out", role: .destructive) {
            signOut()
        }
    }
}
```

### Text Input

```swift
Form {
    TextField("Name", text: $name)
        .textContentType(.name)

    TextField("Email", text: $email)
        .textContentType(.emailAddress)
        .keyboardType(.emailAddress)
        .textInputAutocapitalization(.never)

    SecureField("Password", text: $password)
        .textContentType(.newPassword)
}
.scrollDismissesKeyboard(.interactively)
```

## Sheets & Modals

### Standard Sheet

```swift
.sheet(isPresented: $showSheet) {
    NavigationStack {
        SheetContent()
            .navigationTitle("Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save(); showSheet = false }
                        .fontWeight(.semibold)
                }
            }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
}
```

### Confirmation Dialog

```swift
.confirmationDialog("Delete Item?", isPresented: $showDelete, titleVisibility: .visible) {
    Button("Delete", role: .destructive) { delete() }
    Button("Cancel", role: .cancel) { }
} message: {
    Text("This cannot be undone.")
}
```

## Empty & Loading States

### Empty State

```swift
ContentUnavailableView {
    Label("No Items", systemImage: "tray")
} description: {
    Text("Items you add will appear here.")
} actions: {
    Button("Add Item") { showAdd = true }
        .buttonStyle(.borderedProminent)
}
```

### Loading State

```swift
if isLoading {
    ProgressView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
} else {
    content
}
```

## Accessibility

### Required Practices

```swift
// Label icon-only buttons
Button(action: addItem) {
    Image(systemName: "plus")
}
.accessibilityLabel("Add item")

// Group related content
VStack {
    Text(item.title)
    Text(item.price)
        .monospacedDigit()
}
.accessibilityElement(children: .combine)

// Custom actions
.accessibilityAction(named: "Delete") { delete() }
```

### Dynamic Type Support

```swift
// Let important text wrap and reflow instead of shrinking it
Text(longTitle)
    .fixedSize(horizontal: false, vertical: true)

// Layout adapts
@Environment(\.dynamicTypeSize) var typeSize

var body: some View {
    if typeSize >= .accessibility1 {
        // Stack vertically for large text
        VStack { content }
    } else {
        HStack { content }
    }
}
```

## UX Patterns from Apple Apps

### Pull to Refresh
```swift
List(items) { item in
    ItemRow(item: item)
}
.refreshable {
    await loadItems()
}
```

### Swipe Actions
```swift
ItemRow(item: item)
    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
        Button(role: .destructive) { delete(item) } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    .swipeActions(edge: .leading) {
        Button { toggleFavorite(item) } label: {
            Label("Favorite", systemImage: "star")
        }
        .tint(.yellow)
    }
```

### Search
```swift
NavigationStack {
    List(filteredItems) { item in
        ItemRow(item: item)
    }
    .searchable(text: $searchText, prompt: "Search")
    .searchSuggestions {
        ForEach(suggestions) { suggestion in
            Text(suggestion).searchCompletion(suggestion)
        }
    }
}
```

### Context Menu
```swift
ItemRow(item: item)
    .contextMenu {
        Button { copy(item) } label: {
            Label("Copy", systemImage: "doc.on.doc")
        }
        Button { share(item) } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        Divider()
        Button(role: .destructive) { delete(item) } label: {
            Label("Delete", systemImage: "trash")
        }
    }
```

## Design Checklist

For a requested design review or release, verify the relevant items below. For a focused edit, check the affected states:

- [ ] Semantic or intentionally scaled custom typography works at accessibility sizes
- [ ] Semantic or adaptive custom colors remain readable in both appearances
- [ ] Touch targets ≥ 44pt
- [ ] VoiceOver labels all interactive elements
- [ ] Dynamic Type scales gracefully
- [ ] Loading states for async operations
- [ ] Empty states guide users
- [ ] Error states are helpful
- [ ] Haptics for meaningful feedback
- [ ] Consistent spacing throughout
- [ ] Navigation follows platform conventions

## See Also

- `hig-components.md` — Native component reference
- `apple-app-patterns.md` — UX patterns from Apple's apps
- `liquid-glass-guide.md` — iOS 26 design adoption
