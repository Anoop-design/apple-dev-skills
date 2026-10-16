# Apple App Patterns

UX patterns observed in Apple's native iOS apps.

## Settings App

### Section Structure

```swift
Form {
    // Profile section - prominent at top
    Section {
        NavigationLink {
            ProfileView()
        } label: {
            HStack(spacing: 16) {
                ProfileAvatar(size: 60)
                VStack(alignment: .leading) {
                    Text(user.name)
                        .font(.title2)
                    Text("Apple Account, iCloud & more")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
    }

    // Feature sections
    Section {
        SettingsRow(icon: "airplane", color: .orange, title: "Airplane Mode") {
            Toggle("Airplane Mode", isOn: $airplaneMode)
                .labelsHidden()
        }
        SettingsRow(icon: "wifi", color: .blue, title: "Wi-Fi") {
            Text(wifiNetwork)
                .foregroundStyle(.secondary)
        }
    }
}
```

### Settings Row Pattern

```swift
struct SettingsRow<Trailing: View>: View {
    let icon: String
    let color: Color
    let title: String
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(color, in: RoundedRectangle(cornerRadius: 6))

            Text(title)

            Spacer()

            trailing()
        }
    }
}
```

## Messages App

### Conversation List

```swift
List(conversations) { conversation in
    NavigationLink(value: conversation) {
        HStack(spacing: 12) {
            // Avatar with unread indicator
            ZStack(alignment: .topTrailing) {
                PersonAvatar(person: conversation.person)
                    .frame(width: 50, height: 50)

                if conversation.unreadCount > 0 {
                    Circle()
                        .fill(.blue)
                        .frame(width: 12, height: 12)
                        .offset(x: 2, y: -2)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.name)
                        .font(.headline)
                        .fontWeight(conversation.unreadCount > 0 ? .semibold : .regular)

                    Spacer()

                    Text(conversation.timestamp.formatted(.relative)).monospacedDigit()
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(conversation.lastMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}
.listStyle(.plain)
```

## Photos App

### Grid Layout

```swift
let columns = [GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 2)]

ScrollView {
    LazyVGrid(columns: columns, spacing: 2) {
        ForEach(photos) { photo in
            PhotoThumbnail(photo: photo)
                .aspectRatio(1, contentMode: .fill)
                .clipped()
                .onTapGesture {
                    selectedPhoto = photo
                }
        }
    }
}
.navigationTitle("Library")
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        Menu {
            Button("Select") { isSelecting = true }
            Button("Slideshow") { startSlideshow() }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}
```

### Photo Detail with Scale Feedback

```swift
// Minimal gesture sketch: scaleEffect does not enlarge scrollable layout.
// For bounded panning at zoom, use a zoom-capable UIScrollView wrapper.
struct PhotoDetailView: View {
    let photo: Photo
    @State private var scale: CGFloat = 1
    @GestureState private var gestureScale: CGFloat = 1

    var body: some View {
        GeometryReader { geo in
            ScrollView([.horizontal, .vertical]) {
                Image(photo.image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale * gestureScale)
                    .gesture(
                        MagnificationGesture()
                            .updating($gestureScale) { value, state, _ in
                                state = value
                            }
                            .onEnded { value in
                                scale = max(1, min(scale * value, 4))
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring) {
                            scale = scale > 1 ? 1 : 2
                        }
                    }
            }
        }
        .background(.black)
        .ignoresSafeArea()
    }
}
```

## Mail App

### Inbox List

```swift
List {
    ForEach(emails) { email in
        EmailRow(email: email)
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) { trash(email) } label: {
                    Label("Trash", systemImage: "trash")
                }
                Button { archive(email) } label: {
                    Label("Archive", systemImage: "archivebox")
                }
                .tint(.purple)
            }
            .swipeActions(edge: .leading) {
                Button { toggleRead(email) } label: {
                    Label(
                        email.isRead ? "Unread" : "Read",
                        systemImage: email.isRead ? "envelope.badge" : "envelope.open"
                    )
                }
                .tint(.blue)
            }
    }
}
.listStyle(.plain)
.toolbar {
    ToolbarItem(placement: .bottomBar) {
        HStack {
            Button(action: filter) {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }
            Spacer()
            Text("\(emails.count) Emails").monospacedDigit()
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button(action: compose) {
                Image(systemName: "square.and.pencil")
            }
        }
    }
}
```

## Notes App

### Note Editor

```swift
struct NoteEditor: View {
    @Binding var note: Note
    @FocusState private var isFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                // Title
                TextField("Title", text: $note.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .focused($isFocused)

                // Date
                Text(note.date.formatted(date: .long, time: .shortened)).monospacedDigit()
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Divider()
                    .padding(.vertical, 8)

                // Body
                TextEditor(text: $note.body)
                    .font(.body)
                    .scrollContentBackground(.hidden)
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Button(action: addChecklist) {
                        Image(systemName: "checklist")
                    }
                    Button(action: addTable) {
                        Image(systemName: "tablecells")
                    }
                    Spacer()
                    Button("Done") { isFocused = false }
                }
            }
        }
    }
}
```

## Weather App

### Gradient Background

```swift
struct WeatherBackground: View {
    let condition: WeatherCondition

    var body: some View {
        LinearGradient(
            colors: condition.gradientColors,
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// Weather card
struct WeatherCard: View {
    let forecast: Forecast
    @ScaledMetric(relativeTo: .largeTitle) private var temperatureSize = 96.0

    var body: some View {
        VStack(spacing: 16) {
            // Current temperature
            Text("\(forecast.temperature)°").monospacedDigit()
                .font(.system(size: temperatureSize, weight: .thin))

            Text(forecast.condition)
                .font(.title2)

            Text("H:\(forecast.high)° L:\(forecast.low)°").monospacedDigit()
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.white)
    }
}
```

### Hourly Forecast

```swift
ScrollView(.horizontal, showsIndicators: false) {
    HStack(spacing: 20) {
        ForEach(hourlyForecast) { hour in
            VStack(spacing: 8) {
                Text(hour.time).monospacedDigit()
                    .font(.caption)

                Image(systemName: hour.icon)
                    .symbolRenderingMode(.multicolor)
                    .font(.title2)

                Text("\(hour.temp)°").monospacedDigit()
                    .font(.headline)
            }
        }
    }
    .padding(.horizontal)
}
.padding(.vertical)
.background(.ultraThinMaterial)
```

## App Store

### Featured Card

```swift
struct FeaturedAppCard: View {
    let app: App

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero image
            Image(app.heroImage)
                .resizable()
                .aspectRatio(16/9, contentMode: .fill)
                .clipped()

            // Info section
            HStack(spacing: 12) {
                AppIcon(app: app, size: 50)

                VStack(alignment: .leading, spacing: 2) {
                    Text(app.category.uppercased())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(app.name)
                        .font(.headline)
                    Text(app.tagline)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("GET") { }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
            }
            .padding()
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}
```

## Music App

### Now Playing Bar

```swift
struct NowPlayingBar: View {
    @ObservedObject var player: MusicPlayer

    var body: some View {
        HStack(spacing: 12) {
            // Album art
            AsyncImage(url: player.currentTrack?.artworkURL) { image in
                image.resizable()
            } placeholder: {
                Color.gray
            }
            .frame(width: 48, height: 48)
            .cornerRadius(4)

            // Track info
            VStack(alignment: .leading) {
                Text(player.currentTrack?.title ?? "Not Playing")
                    .font(.subheadline)
                    .lineLimit(1)
                Text(player.currentTrack?.artist ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Controls
            Button(action: player.togglePlayPause) {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
            }

            Button(action: player.skipForward) {
                Image(systemName: "forward.fill")
                    .font(.title3)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
}
```

## Calendar App

### Day View

```swift
struct DayView: View {
    let date: Date
    let events: [Event]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(0..<24, id: \.self) { hour in
                    HStack(alignment: .top) {
                        // Time label
                        Text(formatHour(hour)).monospacedDigit()
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 50, alignment: .trailing)

                        // Hour row
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 1)
                            .padding(.leading, 8)
                    }
                    .frame(height: 60)
                    .overlay(alignment: .leading) {
                        ForEach(events(for: hour)) { event in
                            EventBlock(event: event)
                                .padding(.leading, 58)
                        }
                    }
                }
            }
        }
    }
}
```

Changing numeric fields must reserve space for the supported format (including signs, units and locale). Use a measured exemplar or an adaptive field width; the fixed calendar width here is only a layout sketch. Do not clip accessibility-size text to hold an example width.

## Common Patterns Summary

### Loading → Content → Empty Pattern

```swift
struct ContentView: View {
    @State private var state: ViewState = .loading

    var body: some View {
        Group {
            switch state {
            case .loading:
                ProgressView()
            case .empty:
                ContentUnavailableView(
                    "No Items",
                    systemImage: "tray",
                    description: Text("Add items to get started")
                )
            case .loaded(let items):
                ItemList(items: items)
            case .error(let message):
                ContentUnavailableView(
                    "Error",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
        .task { await load() }
    }
}
```

### Search with Suggestions

```swift
@State private var searchText = ""
@State private var searchScope = SearchScope.all

NavigationStack {
    List(filteredResults) { item in
        ItemRow(item: item)
    }
    .searchable(text: $searchText, prompt: "Search")
    .searchScopes($searchScope) {
        Text("All").tag(SearchScope.all)
        Text("Recent").tag(SearchScope.recent)
        Text("Favorites").tag(SearchScope.favorites)
    }
    .searchSuggestions {
        if searchText.isEmpty {
            ForEach(recentSearches, id: \.self) { term in
                Label(term, systemImage: "clock")
                    .searchCompletion(term)
            }
        }
    }
}
```

### Toolbar Actions Pattern

```swift
.toolbar {
    ToolbarItem(placement: .primaryAction) {
        Button(action: primaryAction) {
            Image(systemName: "plus")
        }
    }

    ToolbarItem(placement: .secondaryAction) {
        Menu {
            Button("Option 1", action: option1)
            Button("Option 2", action: option2)
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}
```
