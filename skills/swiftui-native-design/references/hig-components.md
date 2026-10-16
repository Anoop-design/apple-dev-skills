# HIG Components Reference

Native SwiftUI components that match Apple's Human Interface Guidelines.

## Buttons

### Button Styles

```swift
// Primary action — filled, prominent
Button("Continue") { }
    .buttonStyle(.borderedProminent)

// Secondary action — bordered
Button("Cancel") { }
    .buttonStyle(.bordered)

// Tertiary — text only
Button("Learn More") { }
    .buttonStyle(.plain)

// Destructive
Button("Delete", role: .destructive) { }
    .buttonStyle(.bordered)

// Full width
Button("Sign In") { }
    .buttonStyle(.borderedProminent)
    .controlSize(.large)
    .frame(maxWidth: .infinity)
```

### Control Sizes

```swift
Button("Tap") { }
    .controlSize(.mini)      // Compact UI
    .controlSize(.small)     // Secondary actions
    .controlSize(.regular)   // Default
    .controlSize(.large)     // Primary CTA
    .controlSize(.extraLarge) // Hero buttons
```

### Icon Buttons

```swift
// Toolbar style
Button(action: share) {
    Image(systemName: "square.and.arrow.up")
}

// Circular icon button
Button(action: add) {
    Image(systemName: "plus")
        .font(.title2)
}
.buttonStyle(.borderedProminent)
.buttonBorderShape(.circle)
```

## Toggle & Switch

```swift
Toggle("Notifications", isOn: $notificationsEnabled)

// Custom label
Toggle(isOn: $airplaneMode) {
    Label("Airplane Mode", systemImage: "airplane")
}

// Smaller toggle
Toggle("Option", isOn: $option)
    .toggleStyle(.switch)
    .controlSize(.small)
```

## Picker

```swift
// Segmented picker
Picker("Size", selection: $size) {
    Text("S").tag(Size.small)
    Text("M").tag(Size.medium)
    Text("L").tag(Size.large)
}
.pickerStyle(.segmented)

// Menu picker
Picker("Category", selection: $category) {
    ForEach(categories) { cat in
        Text(cat.name).tag(cat)
    }
}
.pickerStyle(.menu)

// Navigation picker (in Form)
Form {
    Picker("Country", selection: $country) {
        ForEach(countries) { country in
            Text(country.name).tag(country)
        }
    }
}
// Automatic style depends on platform/context; choose an explicit style if required
```

## Slider

```swift
Slider(value: $volume, in: 0...100)

// With labels
Slider(value: $brightness, in: 0...1) {
    Text("Brightness")
} minimumValueLabel: {
    Image(systemName: "sun.min")
} maximumValueLabel: {
    Image(systemName: "sun.max")
}

// Stepped
Slider(value: $rating, in: 1...5, step: 1)
```

## Stepper

```swift
Stepper(value: $quantity, in: 1...99) {
    Text("Quantity: \(quantity)")
        .monospacedDigit()
        .frame(minWidth: 120, alignment: .leading) // Example width; verify localization/type size
}

// Custom increment
Stepper("Amount") {
    amount += 10
} onDecrement: {
    amount -= 10
}
```

## DatePicker

```swift
// Default
DatePicker("Date", selection: $date)

// Date only
DatePicker("Birthday", selection: $birthday, displayedComponents: .date)

// Time only
DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)

// Graphical style
DatePicker("Date", selection: $date)
    .datePickerStyle(.graphical)

// Compact (inline)
DatePicker("Date", selection: $date)
    .datePickerStyle(.compact)
```

## ProgressView

```swift
// Indeterminate spinner
ProgressView()

// With label
ProgressView("Loading...")

// Determinate
ProgressView(value: progress, total: 100)

// Linear style
ProgressView(value: downloaded, total: fileSize)
    .progressViewStyle(.linear)
```

## Labels

```swift
// Icon + text
Label("Favorites", systemImage: "heart")

// Title only
Label("Favorites", systemImage: "heart")
    .labelStyle(.titleOnly)

// Icon only
Label("Favorites", systemImage: "heart")
    .labelStyle(.iconOnly)

// Custom styling
Label {
    Text("Downloads")
        .font(.headline)
} icon: {
    Image(systemName: "arrow.down.circle.fill")
        .foregroundStyle(.blue)
}
```

## Menu

```swift
Menu("Options") {
    Button("Copy", action: copy)
    Button("Paste", action: paste)

    Divider()

    Menu("Share") {
        Button("Messages", action: shareMessages)
        Button("Mail", action: shareMail)
    }

    Divider()

    Button("Delete", role: .destructive, action: delete)
}

// Primary action with menu
Menu {
    Button("Option 1") { }
    Button("Option 2") { }
} label: {
    Label("Add", systemImage: "plus")
} primaryAction: {
    quickAdd()
}
```

## Alert

```swift
.alert("Delete Item?", isPresented: $showAlert) {
    Button("Delete", role: .destructive) { delete() }
    Button("Cancel", role: .cancel) { }
} message: {
    Text("This action cannot be undone.")
}

// With text field
.alert("Rename", isPresented: $showRename) {
    TextField("Name", text: $newName)
    Button("Rename") { rename() }
    Button("Cancel", role: .cancel) { }
}
```

## TextField

```swift
// Basic
TextField("Username", text: $username)

// With prompt
TextField("Search", text: $search, prompt: Text("Search items..."))

// Secure
SecureField("Password", text: $password)

// Text area (multiline)
TextField("Description", text: $description, axis: .vertical)
    .lineLimit(3...6)

// With format
TextField("Amount", value: $amount, format: .currency(code: "USD"))
    .monospacedDigit()
```

### Text Field Modifiers

```swift
TextField("Email", text: $email)
    .textContentType(.emailAddress)
    .keyboardType(.emailAddress)
    .textInputAutocapitalization(.never)
    .autocorrectionDisabled()
    .submitLabel(.next)
    .onSubmit { focusPassword() }
```

## TextEditor

```swift
TextEditor(text: $notes)
    .frame(minHeight: 100)
    .scrollContentBackground(.hidden)  // Custom background
    .background(Color.gray.opacity(0.1))
```

## Link

```swift
Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)

Link(destination: url) {
    Label("Open in Safari", systemImage: "safari")
}
```

## ShareLink

```swift
ShareLink(item: url)

ShareLink(item: url, subject: Text("Check this out"), message: Text("I found this interesting"))

ShareLink(item: image, preview: SharePreview("Photo", image: image))
```

## GroupBox

```swift
GroupBox {
    Text("Premium features include...")
} label: {
    Label("Upgrade", systemImage: "star")
}
```

## DisclosureGroup

```swift
DisclosureGroup("Advanced Options") {
    Toggle("Option 1", isOn: $option1)
    Toggle("Option 2", isOn: $option2)
}

// Controlled expansion
DisclosureGroup("Details", isExpanded: $showDetails) {
    DetailContent()
}
```

## ScrollView

```swift
ScrollView {
    LazyVStack(spacing: 16) {
        ForEach(items) { item in
            ItemCard(item: item)
        }
    }
    .padding()
}
.scrollIndicators(.hidden)
.scrollDismissesKeyboard(.interactively)
```

### Scroll Position (iOS 17+)

```swift
ScrollView {
    LazyVStack {
        ForEach(items) { item in
            ItemRow(item: item)
                .id(item.id)
        }
    }
    .scrollTargetLayout()
}
.scrollPosition(id: $scrolledID)
```

## Grid

```swift
// Fixed columns
LazyVGrid(columns: [
    GridItem(.flexible()),
    GridItem(.flexible()),
    GridItem(.flexible())
], spacing: 16) {
    ForEach(items) { item in
        ItemCell(item: item)
    }
}

// Adaptive columns
LazyVGrid(columns: [
    GridItem(.adaptive(minimum: 150, maximum: 200))
], spacing: 16) {
    ForEach(items) { item in
        ItemCell(item: item)
    }
}
```

## Gauge

```swift
// Default style is platform/context dependent
Gauge(value: progress, in: 0...100) {
    Text("Progress")
}

// Linear
Gauge(value: temperature, in: 0...100) {
    Text("Temperature")
} currentValueLabel: {
    Text("\(Int(temperature))°").monospacedDigit()
}
.gaugeStyle(.linearCapacity)

// Accessory circular (for widgets)
Gauge(value: 0.7) {
    Text("70%").monospacedDigit()
}
.gaugeStyle(.accessoryCircularCapacity)
```

## Charts

```swift
import Charts

Chart(data) { item in
    BarMark(
        x: .value("Category", item.category),
        y: .value("Value", item.value)
    )
}
.frame(height: 200)

// Line chart
Chart(data) { item in
    LineMark(
        x: .value("Date", item.date),
        y: .value("Value", item.value)
    )
}

// Area chart
Chart(data) { item in
    AreaMark(
        x: .value("Date", item.date),
        y: .value("Value", item.value)
    )
    .foregroundStyle(.blue.gradient)
}
```

## Map

```swift
import MapKit

Map(position: $position) {
    Marker("Location", coordinate: coordinate)

    Annotation("Custom", coordinate: coord) {
        CustomAnnotationView()
    }
}
.mapStyle(.standard)
.mapControls {
    MapUserLocationButton()
    MapCompass()
    MapScaleView()
}
```

## PhotosPicker

```swift
import PhotosUI

PhotosPicker(selection: $selectedPhoto, matching: .images) {
    Label("Select Photo", systemImage: "photo")
}

// Multiple selection
PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 5, matching: .images) {
    Text("Select Photos")
}
```

## ColorPicker

```swift
ColorPicker("Theme Color", selection: $themeColor)

// Without label
ColorPicker("Theme Color", selection: $color)
    .labelsHidden()
```

## Table (macOS, iPadOS)

```swift
Table(people) {
    TableColumn("Name", value: \.name)
    TableColumn("Age") { person in
        Text("\(person.age)").monospacedDigit()
    }
    TableColumn("City", value: \.city)
}
```
