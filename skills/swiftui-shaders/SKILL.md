---
name: swiftui-shaders
description: Implement SwiftUI stitchable Metal color, distortion, layer and shape-fill effects. Use for custom pixel effects, ripple/warp behavior, sampling bounds and shader animation; preserve native controls and accessibility around the effect.
license: MIT
---

# SwiftUI shaders

Select the shader contract before writing code: colorEffect receives position and premultiplied color; distortionEffect returns a source position; layerEffect receives a SwiftUI::Layer; a shape-fill shader receives position without an incoming color. Argument order/types in Swift must match the Metal function exactly. ShaderLibrary dynamic member lookup does not typecheck the Metal signature.

Use iOS 17+, macOS 14+, tvOS 17+ or visionOS 1+ availability; these shader APIs are unavailable on watchOS in the inspected SDK. Verify the active SDK for platform-specific adoption.

Read only the needed guide:

- [Implementation guide](references/shader-guide.md): contracts, binding arguments, animation and basic effects.
- [API reference](references/shader-api.md): current ShaderLibrary/Argument surface and sample bounds.
- [Metal reference](references/metal-reference.md): vector math, colors and sampling.
- [Recipes](references/shader-recipes.md): color transforms, bounded warps, ripple, blur and generated fills.

Preserve premultiplied alpha, guard zero-length directions/divisors and use increasing edges for smoothstep. Bound each shader parameter and calculate a conservative maxSampleOffset from its maximum displacement; this declaration is not a clamp. Use a persistent animation origin, reset one-shot keyframes, and pause decorative animation for Reduce Motion/background state. UIKit/AppKit-backed views may not render into a shader; check actual content and provide a normal rendering fallback.

Numeric overlays use tabular digits and stable field widths without changing letterforms. Measure expensive sampling/large effect surfaces on representative hardware; neither GPU execution nor half precision alone guarantees a speedup.

Checked 2026-10-16, Xcode 27.0 (27A266a), iPhoneOS 27 SDK. Representative Swift calls passed typechecking. Metal source review is complete, but compilation could not run because this machine lacks the optional Metal Toolchain; runtime binding and rendered output remain unverified. Sources: [Shader](https://developer.apple.com/documentation/swiftui/shader), [layerEffect](https://developer.apple.com/documentation/swiftui/view/layereffect(_:maxsampleoffset:isenabled:)), [Create custom visual effects](https://developer.apple.com/videos/play/wwdc2024/10151/).
