# UIKit Liquid Glass APIs

Checked 2026-10-16 in Xcode 27.0 headers and Swift interfaces. These examples require iOS 26. Use availability guards for older targets and check Catalyst/other-platform declarations separately.

## Effect and content

```swift
let effect = UIGlassEffect(style: .regular)
effect.tintColor = .systemBlue
effect.isInteractive = true
let glass = UIVisualEffectView(effect: effect)
glass.cornerConfiguration = .capsule()
let label = UILabel()
label.text = "Action"
glass.contentView.addSubview(label)
```

Add content to `contentView` and constrain it there. `UIVisualEffectView` is a visual surface, not an accessible button by itself. Prefer a configured `UIButton` for an action; a custom `UIControl` must handle activation, traits, focus and hit testing. Avoid letting an overlay effect view intercept its control’s touches.

## Corners

```swift
glass.cornerConfiguration = .capsule()
glass.cornerConfiguration = .corners(radius: .fixed(16))
glass.cornerConfiguration = .corners(radius: .containerConcentric(minimum: 8))
```

`UICornerConfiguration` belongs to `UIView`. It is not a `CornerConfiguration` enum with `.fixed(cornerRadius:)` or `.containerRelative` cases. Concentric corners depend on a meaningful containing view geometry; inspect the result after layout.

## Coordinated glass

```swift
let effect = UIGlassContainerEffect()
effect.spacing = 20
let container = UIVisualEffectView(effect: effect)
let first = UIVisualEffectView(effect: UIGlassEffect(style: .regular))
let second = UIVisualEffectView(effect: UIGlassEffect(style: .regular))
container.contentView.addSubview(first)
container.contentView.addSubview(second)
```

Provide frames or constraints for all views. Animate their positions within the **contentView’s local coordinates** to merge/separate them. A container’s `center` is expressed in its superview coordinates and is not the right center for its children; use `contentView.bounds.midX/midY` or constraints.

## Scroll edges and background extension

```swift
scrollView.topEdgeEffect.style = .hard
scrollView.bottomEdgeEffect.style = .soft

let extensionView = UIBackgroundExtensionView()
extensionView.contentView = imageView
```

Pin the extension view to the desired container and let it manage the supplied content. An empty background extension view has no image to extend. `contentScrollEdgeStyle` is not a `UIScrollView` property.

## Animated and conditional adoption

```swift
if #available(iOS 26, *) {
    UIView.animate(withDuration: 0.3) {
        visualEffectView.effect = UIGlassEffect(style: .regular)
    }
} else {
    visualEffectView.effect = UIBlurEffect(style: .systemMaterial)
}
```

Inspect existing appearance settings when adopting system bars and sheets. Standard components adapt automatically when built with a supporting SDK, but custom backgrounds, containment and presentation configuration influence the output. System accessibility adaptation does not remove the need to test contrast and custom interactions.

Sources: [UIGlassEffect](https://developer.apple.com/documentation/uikit/uiglasseffect), [UICornerConfiguration](https://developer.apple.com/documentation/uikit/uicornerconfiguration), [UIGlassContainerEffect](https://developer.apple.com/documentation/uikit/uiglasscontainereffect), [UIScrollView](https://developer.apple.com/documentation/uikit/uiscrollview).
