---
name: swiftui-native-design
description: Design or refine SwiftUI visual hierarchy, typography, layout, navigation, and interaction. Use for visual or UX design work; use implementation or profiling guidance for state and performance defects.
license: MIT
---

# SwiftUI native design

Preserve the user’s visual direction and deployment target. Use native controls where their semantics fit, and customize through supported styles rather than replacing buttons with unlabeled tap gestures. A focused visual change does not call for an unrelated redesign or release audit.

Use coherent hierarchy, adaptive text/color, reachable actions and sensible local geometry. Semantic fonts are a strong default; intentionally scaled custom fonts and colors are valid. Support larger text through wrapping/reflow before truncating or shrinking important content. Check actual accessibility labels, focus order and contrast; native components do not automatically supply every needed label or haptic.

Numeric UI uses tabular glyphs (`.monospacedDigit()` or the UIKit feature) without changing letterforms. Reserve stable widths for changing values, signs, separators and units; verify custom-font glyph support and keep `tnum` when subsetting.

Read only the relevant reference:

- [Design guide](references/design-guide.md): typography, color, layout, navigation, lists, forms, sheets and accessibility.
- [HIG components](references/hig-components.md): native control recipes and platform-aware usage.
- [Apple app patterns](references/apple-app-patterns.md): illustrative product patterns to adapt, not specifications to copy.
- [Liquid Glass](references/liquid-glass-guide.md): iOS 26 surfaces, precise API names and scoped adoption.

Evaluate the changed states at relevant device sizes, Dynamic Type, light/dark appearance, VoiceOver and Reduce Motion. Treat dimensions, timings and component counts in recipes as examples, not universal Apple requirements.

Checked 2026-10-16 with Xcode 27.0 (27A266a), iPhoneOS 27 SDK. Representative SwiftUI APIs typecheck; verify appearance and interaction in the app. Sources: [HIG](https://developer.apple.com/design/human-interface-guidelines/), [Typography](https://developer.apple.com/design/human-interface-guidelines/typography), [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility).
