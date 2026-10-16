# SwiftUI chrome and materials

Checked 2026-10-16 against Xcode 27.0 (27A266a), Swift 6.4, and the iOS 27 SDK. Availability below is per API, not the skill name.

Use standard navigation, bars, tabs, sheets, and controls where their behavior fits the design. They pick up platform appearance and accessibility behavior. Custom glass generally belongs to the navigation/control layer over content; use deliberate contrast and hierarchy instead of layering glass across every content card.

For custom material work use the iOS 26+ `glassEffect` and `GlassEffectContainer` APIs, with appropriate availability handling. `glassEffectID` and a namespace support coordinated transitions. Use button styles for buttons instead of recreating their entire interaction with a material effect. Consult the optional `liquid-glass` skill for a substantial material implementation.

Do not assume a system appearance change means every app should adopt a custom glass implementation. Preserve the requested visual design and supported targets. The `UIDesignRequiresCompatibility` escape hatch is not a durable migration strategy; check the current key documentation when updating the build SDK. Do not infer an App Store submission deadline from prior years.

Test the affected view in light/dark appearance, increased contrast, Reduce Transparency, and relevant Dynamic Type sizes. Measure actual container width for layout instead of relying solely on device idiom; size classes are coarse environment signals, not exact dimensions. Reserve stable numeric field widths and apply `.monospacedDigit()` to numbers while retaining the chosen font for letters.

Official sources: [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass), [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views), [UIDesignRequiresCompatibility](https://developer.apple.com/documentation/bundleresources/information-property-list/uidesignrequirescompatibility).
