# Liquid Glass patterns

Recipes use iOS 26 APIs except the availability-safe wrapper. See the [SwiftUI reference](swiftui-glass-api.md) for imports, guards, morphing and toolbar grouping, and the [UIKit reference](uikit-glass-api.md) for visual-effect views.

## Older deployment targets

Do not put an iOS 26-only `Glass` parameter in a supposedly older-OS wrapper’s unguarded signature.

```swift
extension View {
    @ViewBuilder
    func adaptiveGlass() -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(.regular, in: Capsule())
        } else if #available(iOS 15, *) {
            self.background(.regularMaterial, in: Capsule())
        } else {
            self.background(Capsule().fill(Color.gray.opacity(0.2)))
        }
    }
}
```

Keep equivalent control behavior and accessibility across branches.

## Floating controls

```swift
@available(iOS 26, *)
struct GlassAction: View {
    let title: String
    let symbol: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .labelStyle(.iconOnly)
                .frame(minWidth: 44, minHeight: 44)
        }
        .buttonStyle(.glass)
        .accessibilityLabel(title)
    }
}
```

Group nearby controls in a `GlassEffectContainer` where their surfaces should coordinate. Use safe-area placement so the final scroll item and keyboard remain reachable. Prefer a native segmented picker over nested custom glass on both segments and their parent.

## Numeric badges

Use the chosen text font with `.monospacedDigit()`. Reserve the expected field width using an invisible exemplar that participates in layout and is hidden from accessibility. A badge can cap its visible text (for example, `999+`) and expose the actual count as its accessibility value.

```swift
@available(iOS 26, *)
struct CountBadge: View {
    let count: Int
    var body: some View {
        Text("999+")
            .hidden()
            .overlay(alignment: .trailing) {
                Text(count > 999 ? "999+" : String(max(0, count)))
            }
            .font(.caption)
            .monospacedDigit()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .glassEffect(.regular.tint(.red), in: Capsule())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Count")
            .accessibilityValue(String(max(0, count)))
    }
}
```

Check the chosen font actually provides tabular glyphs and retain its `tnum` feature when subsetting. Check localized formatting and larger type. Fixed field width should cover the supported display format rather than clipping a growing value.
