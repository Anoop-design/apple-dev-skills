---
name: core-animation-uikit
description: Implement or debug CALayer and UIKit animations, including keyframes, springs, custom layers, interruptible gestures and view-controller transitions. Use when layer timing or UIKit behavior needs direct control.
license: MIT
---

# Core Animation and UIKit

Choose UIView animation for ordinary view properties, UIViewPropertyAnimator for interactive/pauseable transitions, and explicit Core Animation for layer-specific control. Preserve the project’s visual language and deployment target.

Keep the model and presentation states distinct. Explicit CAAnimation does not update the model: capture the current presentation value, set the final model value with implicit actions disabled, and add the explicit animation. Replace the relevant animation under a stable key when the new animation already incorporates its current presentation offset. Do not keep completed animations merely to preserve an incorrect model.

Use layer-local timing via `convertTime` for delays. Keep UIKit work on the main actor. Restore state when a gesture or transition cancels. Respect Reduce Motion and stop indefinite decorative animation when it is irrelevant or offscreen. For numeric UI, use tabular digits and stable field widths without changing the text font’s letterforms.

Read only the required reference:

- [Animation guide](references/animation-guide.md): transactions, basic/keyframe/spring animations, custom animatable layers, property animators and view-controller transitions.
- [Layer types](references/layer-types.md): shapes, gradients, emitters, replicators, tiled drawing and text.
- [Animatable properties](references/animatable-properties.md): key-path selection; confirm the specific property declaration when in doubt.
- [Performance](references/performance-checklist.md): measured rendering decisions, deadlines and profiling.
- [SwiftUI bridge](references/uikit-swiftui-bridge.md): representables, lifecycle and state-driven layer animation.

Checked 2026-10-16 with Xcode 27.0 (27A266a), iPhoneOS 27 SDK. Representative layer/transition APIs are typechecked; device performance and visual results must be measured for the app. Sources: [Core Animation guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreAnimation_guide/Introduction/Introduction.html), [CALayer](https://developer.apple.com/documentation/quartzcore/calayer), [UIViewPropertyAnimator](https://developer.apple.com/documentation/uikit/uiviewpropertyanimator).
