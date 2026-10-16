---
name: liquid-glass
description: Adopt or refine Liquid Glass in SwiftUI or UIKit on iOS 26 and later. Use for custom glass, toolbar grouping, tab accessories, sheet appearance, or glass morphing while preserving the app’s design and deployment target.
license: MIT
---

# Liquid Glass

Use standard controls and navigation containers as the starting point. On supported systems, building with the newer SDK adopts system design changes; existing appearance overrides and container configuration can change the result. Inspect the affected screens before removing any customization.

Glass establishes a control/navigation layer above content. Preserve the user's visual direction. Use ordinary materials or solid surfaces where the content benefits; glass does not have to cover every card. Avoid placing a second glass effect on a native control that already supplies it.

Read only what the task needs:

- [SwiftUI APIs](references/swiftui-glass-api.md): glass shapes, button styles, morphing, toolbar spacing, tabs and scroll edges.
- [UIKit APIs](references/uikit-glass-api.md): visual-effect content, corner configuration, containers and scroll edges.
- [Patterns](references/glass-patterns.md): availability-safe fallbacks, stable numeric badges and accessible floating controls.

Verify API spelling and availability against the selected SDK. `glassEffect(_:in:)` takes a **Shape** as its second argument. `Glass` has `tint` and `interactive`; do not invent `shape` or `prominence` members. `ToolbarSpacer` is toolbar content, so place it directly inside `.toolbar`, outside a `ToolbarItem`.

Use a shared `GlassEffectContainer` for nearby custom glass that should merge or morph. Keep glass identities stable and drive changes in an animated transaction. This container coordinates rendering; it does not make overlapping glass layers a useful design.

Test light/dark backgrounds, legibility, Dynamic Type, Reduce Transparency, Increase Contrast, Reduce Motion and VoiceOver. Native material adaptation helps, but custom content, labels and hit targets remain the app’s responsibility. Use tabular numerals and stable widths for numeric controls without changing the letterforms.

Checked 2026-10-16 against Xcode 27.0 (27A266a), iPhoneOS 27.0 SDK. Representative SwiftUI/UIKit recipes typecheck; visual behavior still requires an app/runtime check. Primary sources: [custom glass](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views), [UIGlassEffect](https://developer.apple.com/documentation/uikit/uiglasseffect), [Liquid Glass adoption](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass).
