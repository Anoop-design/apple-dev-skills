# SwiftUI Liquid Glass APIs

Checked 2026-10-16 in Xcode 27.0. Examples here require iOS 26 unless explicitly guarded; check other platforms separately. Liquid Glass APIs listed here are unavailable on visionOS in the inspected SDK.

## Shapes, tint and interaction

```swift
Text("Badge")
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .glassEffect(.regular, in: Capsule())

Image(systemName: "star.fill")
    .padding()
    .glassEffect(.regular.tint(.orange), in: Circle())

Button("Action") { }
    .buttonStyle(.glass)

Button("Primary") { }
    .buttonStyle(.glassProminent)
```

The shape is passed to `in:`. `Glass.regular`, `.clear`, and `.identity` are configurations; `tint(_:)` takes an optional color and `interactive(_:)` defaults to `true`. Clear glass suits visually rich backgrounds when contrast is adequate. Prefer the glass button styles for ordinary buttons; apply `.glassEffect(.regular.interactive(), in: ...)` when designing a custom control surface.

## Containers and morphing

```swift
@available(iOS 26.0, *)
struct GlassActions: View {
    @Namespace private var glass
    @State private var expanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GlassEffectContainer(spacing: 24) {
            HStack(spacing: 16) {
                Button(expanded ? "Less" : "More") {
                    withAnimation(reduceMotion ? nil : .smooth) {
                        expanded.toggle()
                    }
                }
                .padding()
                .glassEffect(.regular.interactive())
                .glassEffectID("toggle", in: glass)

                if expanded {
                    Button("Share", systemImage: "square.and.arrow.up") { }
                        .padding()
                        .glassEffect(.regular.interactive())
                        .glassEffectID("share", in: glass)
                }
            }
        }
    }
}
```

Container spacing controls when neighboring shapes begin to merge. Layout spacing and shape size determine their actual distance. Use `glassEffectID(_:in:)` on the glass view, with stable identities in the shared namespace. Put conditional replacement branches inside the same container for morphing. Use `glassEffectUnion(id:namespace:)` only when several views should contribute to one glass shape.

## Toolbar grouping

```swift
.toolbar {
    ToolbarItem(placement: .primaryAction) {
        Button("Edit", systemImage: "pencil") { }
    }
    ToolbarSpacer(.fixed, placement: .primaryAction)
    ToolbarItem(placement: .primaryAction) {
        Button("Share", systemImage: "square.and.arrow.up") { }
    }
}
```

`ToolbarSpacer` conforms to `ToolbarContent`, not `View`. Its default sizing is `.flexible`; specify `.fixed` for separation. Placement and platform affect grouping. For a deliberately ungrouped informational item, inspect `sharedBackgroundVisibility(_:)` on toolbar content rather than adding a background to its child view.

## Tabs, sheets and scroll content

```swift
TabView {
    Tab("Home", systemImage: "house") { Text("Home") }
    Tab(role: .search) { Text("Search") }
}
.tabViewBottomAccessory { Text("Now playing") }
```

The search **role** supplies dedicated search-tab behavior; an ordinary tab named Search does not. Use it when search is a primary destination. `Tab` predates iOS 26, while `tabViewBottomAccessory` is iOS 26.

```swift
ScrollView { Text("Content") }
    .scrollEdgeEffectStyle(.hard, for: .top)
```

Configure the relevant edges; do not invent `scrollEdgeEffect(_:)`. Choose soft/hard/automatic from actual content readability. `backgroundExtensionEffect()` extends a visual background beyond a safe area; `ignoresSafeArea` alone is not that effect.

System sheet appearance depends on size, detent, device and content. Remove a custom presentation background only if restoring the system surface is the intended change. `.presentationBackground(.clear)` makes the background clear; it does not enable glass. Zoom presentation can pair `matchedTransitionSource` with `navigationTransition(.zoom(sourceID:in:))` (iOS 18+) and needs actual presentation testing.

Sources: [glassEffect](https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:)), [GlassEffectContainer](https://developer.apple.com/documentation/swiftui/glasseffectcontainer), [ToolbarSpacer](https://developer.apple.com/documentation/swiftui/toolbarspacer), [scrollEdgeEffectStyle](https://developer.apple.com/documentation/swiftui/view/scrolledgeeffectstyle(_:for:)).
