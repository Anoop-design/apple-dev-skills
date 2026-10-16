# Glanceable widget design

Checked 2026-10-16 against Xcode 27.0 (27A266a), Swift 6.4, and the iOS 27 SDK. Availability below is per API, not the skill name.

Give the widget a clear primary job and hierarchy. A user should see current, relevant information without opening the app. Use the product's real empty and stale states; don't fabricate data to avoid showing unavailability.

## Rendering

`widgetRenderingMode` can be `.fullColor`, `.vibrant`, or `.accented`. Accented rendering predates iOS 26 and also supports tinted appearances; it isn't a reliable boolean for “Liquid Glass.” Use `widgetAccentable()` to mark the accent group and `widgetAccentedRenderingMode(_:)` for image treatment on supported targets. Keep meaning understandable without color.

Let the system manage the widget container background. Test the actual supported light/dark, tinted/clear, and background-removed contexts; don't add custom glass layers simply because the system uses a glass appearance.

## Numeric typography and dates

Use `.monospacedDigit()` for dates, durations, counters, percentages, and metrics, keeping letters in the chosen font. Monospaced digits stabilize each digit but not the overall digit count. Reserve width using a realistic maximum formatted value, including signs, grouping, localization, and possible hour fields:

```swift
import SwiftUI

struct StableCounter: View {
    let value: Int
    var body: some View {
        Text("9,999") // Example envelope: adapt to the actual range and locale.
            .hidden()
            .overlay(alignment: .trailing) {
                Text(value, format: .number).monospacedDigit()
            }
            .font(.title2).monospacedDigit()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Count")
            .accessibilityValue(Text(value, format: .number))
    }
}
```

For a ticking duration use system-supported `Text(date, style: .timer)` or an appropriate timer-interval initializer. `.relative`/`.offset` can also update relative to time. `.time` and `.date` format a fixed date; they do not turn an arbitrary stored timestamp into the current clock. Preformatting a date into a string removes system-driven timer behavior.

If a custom font is used, verify that it actually provides tabular digits and that subsetting retains `tnum`. Test transitions such as 9→10, 59→60, and 99→100 plus the localized maximum.

## Accessibility and resources

Use semantic text styles and enough space for meaningful labels; avoid shrinking essential text to an arbitrary minimum size. Prefer built-in intent buttons to gesture-shaped decorations. Label icon-only actions and check VoiceOver order/grouping. Reserve enough touch area for the actual platform without cramming app-like controls into an accessory family.

Keep images and view work small. Decode appropriately sized assets before rendering, and measure extension memory with realistic data. A universal “30 MB” threshold is not a cross-platform contract. Precompute expensive content in the provider/store, not during every view evaluation.

Official sources: [Widgets HIG](https://developer.apple.com/design/human-interface-guidelines/widgets), [WidgetRenderingMode](https://developer.apple.com/documentation/widgetkit/widgetrenderingmode), [Displaying dynamic dates](https://developer.apple.com/documentation/widgetkit/displaying-dynamic-dates), [monospacedDigit](https://developer.apple.com/documentation/swiftui/view/monospaceddigit()).
