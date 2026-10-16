# Core Animation performance checks

Checked 2026-10-16. Measure the requested interaction on a representative physical device using a Release/Profile build. Simulator traces can help investigate dependencies but are not hardware performance evidence.

## Work from the missed deadline

A 60 Hz display has about 16.7 ms per frame; 120 Hz has about 8.3 ms. The app has only part of that interval because layout, commit and rendering share the pipeline. Use Animation Hitches, Time Profiler and the relevant rendering instruments available in the installed Xcode. Hangs measure response delays and are not a detector for every missed 16 ms frame.

Compare a repeatable interaction before and after the fix. Frame-body duration, layer count and offscreen passes are clues, not universal pass/fail metrics. There is no general requirement for zero offscreen passes or fewer than 5% rasterization misses.

## Shadows, masks and opacity

- Supply `shadowPath` when the shadow’s intended silhouette is known, and update it after bounds/corner changes. A dynamic content silhouette can legitimately need a computed shadow.
- Rounded clipping may be optimized by the renderer. Do not replace every `cornerRadius`/`masksToBounds` pair with pre-rendered images or shape masks. Profile the actual combination.
- Group opacity preserves the composite appearance of overlapping children. Turning `allowsGroupOpacity` off can change that appearance; use it only if correct and measured beneficial.
- Mark a view opaque only when it fills its bounds with opaque content. Transparency and blur can be intentional parts of the product.

## Rasterization

`shouldRasterize` can help a complex subtree whose contents remain unchanged while it moves. It can hurt changing content, large surfaces and frequently invalidated caches. Do not enable it across all table cells or toggle it automatically during every scroll. Use the owning view’s display scale, update it after display changes, and measure cache behavior where tooling exposes it:

```swift
complexView.layer.rasterizationScale = complexView.traitCollection.displayScale
complexView.layer.shouldRasterize = true // Only after a useful measured trial
```

## Main-thread work and images

Keep UI updates on the main actor. Dispatching CPU-heavy work asynchronously to the main queue still blocks that queue when it executes. Move suitable pure computation or decoding to an actor/background execution context with safe data transfer, then apply results on the main actor. Do not assume an `async` function or SwiftUI `.task` automatically changes executor.

Downsample large image files to the necessary pixel dimensions before decoding when possible (for example, ImageIO thumbnails). UIKit display-preparation APIs may help; preserve alpha, color space and orientation. Memory, decode cost and sampling cost are different problems. Test custom drawing and `drawsAsynchronously` before adopting them broadly.

Align static thin lines/images to the owning display’s pixel grid when needed. Do not quantize continuous animated positions merely to eliminate fractional coordinates.

## Model and interruption correctness

Capture the presentation value, update the model with implicit actions disabled, and replace an animation under a stable key. `fillMode = .forwards` plus `isRemovedOnCompletion = false` does not repair model state. Keep expensive work out of animation callbacks and handle cancellation before removing views or running completion-dependent business logic.

Sources: [Improving app responsiveness](https://developer.apple.com/documentation/xcode/improving-app-responsiveness), [Core Animation performance](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreAnimation_guide/ImprovingAnimationPerformance/ImprovingAnimationPerformance.html), [Render server hitches](https://developer.apple.com/videos/play/wwdc2021/10215/).
