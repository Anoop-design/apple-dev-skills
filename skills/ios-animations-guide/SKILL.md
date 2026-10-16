---
name: ios-animations-guide
description: Choose and implement SwiftUI animation, transitions, springs, matched geometry, symbol effects, and phase/keyframe sequences. Use for state-driven motion and gesture handoff; use Core Animation guidance for direct UIKit/CALayer control.
license: MIT
---

# SwiftUI animation

Start with what changes: an animatable value, view insertion/removal, navigation, an SF Symbol or a timed sequence. Preserve the product’s intended motion and the supported OS range.

- Use `withAnimation` for a coordinated state change, `.animation(_:value:)` for a value-triggered subtree (iOS 15+), or closure-scoped animation (iOS 17+) for a narrower set of modifiers. Other animatable changes in the same transaction can animate too.
- Transitions need insertion/removal in an animated transaction. Keep view identity stable; avoid replacing whole models to trigger motion.
- Use springs for interruptible motion when suitable, timing curves for deliberate duration/constant-speed effects, and phase/keyframe animators for a justified sequence. Duration/bounce springs and phase/keyframe animators require iOS 17.
- For navigation zoom use matched transition source plus `.navigationTransition(.zoom(...))` on iOS 18+. Ordinary matched geometry is for views sharing an animation context and is not a general cross-navigation replacement.
- Respect Reduce Motion, keep critical state updates independent of animation completion, and stop irrelevant repeating effects. Expose an accessible alternative to gesture-only actions.
- Use tabular digits and stable field widths for animated counters, timers and other numeric UI; keep the chosen letterforms.

Read only the useful reference:

- [Decision tree](references/animation-decision-tree.md): select a technique.
- [Implementation guide](references/animation-guide.md): state, transitions, navigation, gestures, symbols and Animatable.
- [Spring tuning](references/spring-tuning.md): perceptual duration, damping and velocity.
- [Transition catalog](references/transition-catalog.md): combinations and custom transitions.
- [Keyframe patterns](references/keyframe-patterns.md): phase/keyframe recipes and timelines.

Checked 2026-10-16 against Xcode 27.0 (27A266a), iPhoneOS 27 SDK. Representative recipes typecheck; evaluate interruption, cancellation and accessibility in the app. Sources: [Animations](https://developer.apple.com/documentation/swiftui/animations), [Animate with springs](https://developer.apple.com/videos/play/wwdc2023/10158/), [Wind your way through advanced animations](https://developer.apple.com/videos/play/wwdc2023/10157/).
