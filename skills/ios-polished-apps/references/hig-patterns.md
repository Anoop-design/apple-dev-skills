# Human Interface Guidelines Patterns

Common UI patterns that match Apple's design language.

## Lists

### Standard Row

```swift
struct ItemRow: View {
    let item: Item

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.body)
                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if item.hasChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
```

### Swipe Actions

```swift
List {
    ForEach(items) { item in
        ItemRow(item: item)
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    delete(item)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .swipeActions(edge: .leading) {
                Button {
                    toggleFavorite(item)
                } label: {
                    Label("Favorite", systemImage: "star")
                }
                .tint(.yellow)
            }
    }
}
```

## Modals

### Sheet with Toolbar

```swift
.sheet(isPresented: $showSheet) {
    NavigationStack {
        ContentView()
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
    Text("This action cannot be undone.")
}
```

### Alert

```swift
.alert("Error", isPresented: $showError) {
    Button("OK") { }
} message: {
    Text(errorMessage)
}
```

## Forms & Input

### Settings-Style Form

```swift
Form {
    Section("Account") {
        LabeledContent("Email", value: user.email)

        NavigationLink("Notifications") {
            NotificationSettings()
        }

        Toggle("Dark Mode", isOn: $darkMode)
    }

    Section("About") {
        LabeledContent("Version", value: "1.0.0").monospacedDigit()
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
    Section("Details") {
        TextField("Name", text: $name)

        TextField("Email", text: $email)
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)

        SecureField("Password", text: $password)
            .textContentType(.newPassword)
    }
}
.scrollDismissesKeyboard(.interactively)
```

## Buttons

### Primary Action

```swift
Button {
    submit()
} label: {
    Text("Continue")
        .frame(maxWidth: .infinity)
}
.buttonStyle(.borderedProminent)
.controlSize(.large)
```

### Destructive

```swift
Button("Delete Account", role: .destructive) {
    showDeleteConfirmation = true
}
```

### Icon Button in Toolbar

```swift
.toolbar {
    ToolbarItem(placement: .primaryAction) {
        Button {
            addItem()
        } label: {
            Image(systemName: "plus")
        }
    }
}
```

## Empty States

```swift
ContentUnavailableView {
    Label("No Items", systemImage: "tray")
} description: {
    Text("Items you add will appear here.")
} actions: {
    Button("Add Item") {
        showAddSheet = true
    }
    .buttonStyle(.borderedProminent)
}
```

## Search

```swift
NavigationStack {
    List(filteredItems) { item in
        ItemRow(item: item)
    }
    .searchable(text: $searchText, prompt: "Search items")
    .searchSuggestions {
        ForEach(suggestions) { suggestion in
            Text(suggestion.text)
                .searchCompletion(suggestion.text)
        }
    }
}
```

## Tab Bar

```swift
TabView(selection: $selectedTab) {
    HomeView()
        .tabItem {
            Label("Home", systemImage: "house")
        }
        .tag(Tab.home)

    SearchView()
        .tabItem {
            Label("Search", systemImage: "magnifyingglass")
        }
        .tag(Tab.search)

    ProfileView()
        .tabItem {
            Label("Profile", systemImage: "person")
        }
        .tag(Tab.profile)
}
```

## Pull to Refresh

```swift
List(items) { item in
    ItemRow(item: item)
}
.refreshable {
    await loadItems()
}
```

## Context Menu

```swift
ItemRow(item: item)
    .contextMenu {
        Button {
            copy(item)
        } label: {
            Label("Copy", systemImage: "doc.on.doc")
        }

        Button {
            share(item)
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }

        Divider()

        Button(role: .destructive) {
            delete(item)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
```
