# Core Animation & UIKit recipes

Implementation recipes for QuartzCore and UIKit. Code fragments assume the surrounding view/controller supplies referenced properties. Preserve the app’s visual design and target OS; choose the smallest suitable API.

## Architecture Overview

### The Layer-View Relationship

Every UIView is backed by a CALayer. UIView handles touch events and responder chain; CALayer handles rendering, layout, and animation.

```swift
// Every UIView has a backing layer
let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))

// Direct layer configuration
view.layer.cornerRadius = 16
view.layer.borderWidth = 2
view.layer.borderColor = UIColor.systemBlue.cgColor

// Shadow (provide a matching shadowPath when the intended shadow outline is known)
view.layer.shadowColor = UIColor.black.cgColor
view.layer.shadowOffset = CGSize(width: 0, height: 4)
view.layer.shadowRadius = 8
view.layer.shadowOpacity = 0.3
view.layer.shadowPath = UIBezierPath(roundedRect: view.bounds,
                                      cornerRadius: 16).cgPath
```

### Three Layer Trees

Core Animation maintains three parallel hierarchies:

| Tree | Purpose | Access |
|------|---------|--------|
| **Model Layer** | Target/final values your code sets | `layer` (default) |
| **Presentation Layer** | Current in-flight animated values | `layer.presentation()` |
| **Render Tree** | Private, used by GPU compositor | Not accessible |

```swift
// During animation, model and presentation differ
UIView.animate(withDuration: 2.0) {
    self.box.center = CGPoint(x: 300, y: 200)
}

// Model shows final value immediately
print(box.layer.position)  // (300, 200)

// Presentation shows current animated position
print(box.layer.presentation()?.position)  // Interpolated value
```

**Why this matters:** The model stores the intended final state. UIKit hit testing does not automatically follow every presentation-layer animation. For a custom layer-based interaction, explicitly convert the point into the correct coordinate space and query the presentation tree when visible animated geometry should determine the hit.

### Rendering Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│  YOUR APP PROCESS                                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │  Layout  │→ │ Display  │→ │ Prepare  │→ │  Commit  │ ──────┐│
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘       ││
└───────────────────────────────────────────────────────────────│┘
                                                    IPC         │
┌───────────────────────────────────────────────────────────────│┘
│  RENDER SERVER (backboardd)                                   ▼
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │  Decode  │→ │  VSync   │→ │  Draw    │→ │   GPU    │       │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘       │
└─────────────────────────────────────────────────────────────────┘
```

**Key insight:** Many compositing animations can continue in the render server after commit. Custom drawing, layout and new transactions still require app work; render-server or GPU load can also cause hitches. A busy main thread remains a responsiveness problem.

---

## Implicit Animations

### How They Work

Standalone CALayers (not UIView backing layers) automatically animate property changes:

```swift
let layer = CALayer()
layer.frame = CGRect(x: 50, y: 50, width: 100, height: 100)
layer.backgroundColor = UIColor.blue.cgColor
view.layer.addSublayer(layer)

// This automatically animates over 0.25 seconds!
layer.opacity = 0.5
layer.position = CGPoint(x: 200, y: 200)
```

### Why UIView Layers Don't Implicitly Animate

UIView's backing layer delegate returns `NSNull` for action lookups, disabling implicit animation. This is why you need `UIView.animate` or explicit CAAnimation.

### Customizing with CATransaction

```swift
// Change duration and timing
CATransaction.begin()
CATransaction.setAnimationDuration(0.8)
CATransaction.setAnimationTimingFunction(
    CAMediaTimingFunction(name: .easeInEaseOut)
)

layer.position = CGPoint(x: 200, y: 200)
layer.opacity = 0.5
layer.backgroundColor = UIColor.red.cgColor

CATransaction.setCompletionBlock {
    print("Animation complete!")
}
CATransaction.commit()
```

### Disabling Implicit Animations

```swift
// Method 1: CATransaction
CATransaction.begin()
CATransaction.setDisableActions(true)
layer.position = CGPoint(x: 100, y: 100)
CATransaction.commit()

// Method 2: For UIView layers in certain contexts
UIView.performWithoutAnimation {
    view.layer.cornerRadius = 20
}

// Method 3: CALayer action override
class NoAnimationLayer: CALayer {
    override func action(forKey event: String) -> CAAction? {
        return NSNull()
    }
}
```

---

## Explicit Animations

### CABasicAnimation

Animates from one value to another:

```swift
let animation = CABasicAnimation(keyPath: "position.x")
animation.fromValue = 50
animation.toValue = 300
animation.duration = 1.0
animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

// CRITICAL: Update model layer to prevent snap-back
CATransaction.begin()
CATransaction.setDisableActions(true)
layer.position.x = 300
CATransaction.commit()
layer.add(animation, forKey: "slideRight")
```

### Animatable Key Paths

| Property | Key Path | Notes |
|----------|----------|-------|
| Position | `position`, `position.x`, `position.y` | Center point |
| Size | `bounds.size`, `bounds.size.width` | |
| Transform | `transform`, `transform.scale`, `transform.rotation.z` | 3D transforms |
| Opacity | `opacity` | 0.0 to 1.0 |
| Background | `backgroundColor` | CGColor |
| Corner Radius | `cornerRadius` | |
| Border | `borderWidth`, `borderColor` | |
| Shadow | `shadowOffset`, `shadowRadius`, `shadowOpacity`, `shadowColor` | |
| Contents | `contents` | Image crossfade |

### CAKeyframeAnimation

For complex multi-point animations:

```swift
// Value-based keyframes
let shake = CAKeyframeAnimation(keyPath: "position.x")
shake.values = [0, 10, -10, 10, -5, 5, 0]
shake.keyTimes = [0, 0.125, 0.25, 0.375, 0.5, 0.625, 1.0]
shake.duration = 0.4
shake.isAdditive = true  // Add to current position
layer.add(shake, forKey: "shake")

// Path-based animation
let orbit = CAKeyframeAnimation(keyPath: "position")
let path = CGMutablePath()
path.addEllipse(in: CGRect(x: 50, y: 50, width: 200, height: 200))
orbit.path = path
orbit.duration = 3.0
orbit.repeatCount = .infinity
orbit.rotationMode = .rotateAuto  // Orient along path
orbit.calculationMode = .paced    // Constant velocity
layer.add(orbit, forKey: "orbit")
```

**Calculation Modes:**

| Mode | Behavior |
|------|----------|
| `.linear` | Straight lines between keyframes |
| `.discrete` | Jump instantly between values |
| `.paced` | Constant velocity, ignores keyTimes |
| `.cubic` | Smooth Catmull-Rom spline |
| `.cubicPaced` | Cubic with constant velocity |

### CASpringAnimation

Physics-based spring motion:

```swift
let spring = CASpringAnimation(keyPath: "transform.scale")
spring.fromValue = 1.0
spring.toValue = 1.3
spring.mass = 1.0           // Object mass (affects momentum)
spring.stiffness = 100.0    // Higher = snappier
spring.damping = 10.0       // Higher = less oscillation
spring.initialVelocity = 0

// IMPORTANT: Use settlingDuration for proper timing
spring.duration = spring.settlingDuration

layer.transform = CATransform3DMakeScale(1.3, 1.3, 1.0)
layer.add(spring, forKey: "springScale")
```

**Spring Parameter Guide:**

| Feel | Stiffness | Damping | Bounce |
|------|-----------|---------|--------|
| Snappy | 200-400 | 15-25 | Minimal |
| Bouncy | 100-200 | 8-12 | Visible |
| Sluggish | 50-100 | 5-10 | Slow settle |

### CAAnimationGroup

Combine multiple animations:

```swift
let scale = CABasicAnimation(keyPath: "transform.scale")
scale.fromValue = 1.0
scale.toValue = 1.5

let rotate = CABasicAnimation(keyPath: "transform.rotation.z")
rotate.fromValue = 0
rotate.toValue = CGFloat.pi * 2

let fade = CABasicAnimation(keyPath: "opacity")
fade.fromValue = 1.0
fade.toValue = 0.3

let group = CAAnimationGroup()
group.animations = [scale, rotate, fade]
group.duration = 2.0
group.autoreverses = true
group.repeatCount = .infinity

layer.add(group, forKey: "combined")
```

### CATransition

Animate layer content changes:

```swift
let transition = CATransition()
transition.type = .push
transition.subtype = .fromRight
transition.duration = 0.3

// Apply before changing content
layer.add(transition, forKey: kCATransition)
layer.contents = newImage.cgImage

// For UIView content
view.layer.add(transition, forKey: kCATransition)
imageView.image = newImage
```

**Transition Types:**

| Type | Effect |
|------|--------|
| `.fade` | Crossfade |
| `.moveIn` | New slides over old |
| `.push` | New pushes old out |
| `.reveal` | Old slides away revealing new |

---

## Timing Functions

### Built-in Curves

```swift
// Standard curves
CAMediaTimingFunction(name: .linear)       // Constant speed
CAMediaTimingFunction(name: .easeIn)       // Start slow, end fast
CAMediaTimingFunction(name: .easeOut)      // Start fast, end slow
CAMediaTimingFunction(name: .easeInEaseOut) // Slow-fast-slow
CAMediaTimingFunction(name: .default)      // Slight ease-in/out
```

### Custom Cubic Bézier

```swift
// Control points: (c1x, c1y, c2x, c2y)
let snappy = CAMediaTimingFunction(controlPoints: 0.4, 0, 0.2, 1)
let overshoot = CAMediaTimingFunction(controlPoints: 0.68, -0.55, 0.265, 1.55)
let bounce = CAMediaTimingFunction(controlPoints: 0.175, 0.885, 0.32, 1.275)
```

### CAMediaTiming Protocol

Both CAAnimation and CALayer conform to this:

```swift
animation.duration = 2.0
animation.repeatCount = .infinity    // Or specific: 3.5
animation.repeatDuration = 10.0      // Repeat for 10 seconds total
animation.autoreverses = true        // Play forward then backward
animation.beginTime = layer.convertTime(CACurrentMediaTime(), from: nil) + 0.5  // Layer-local time
animation.speed = 2.0                // 2x playback speed
animation.timeOffset = 0.5           // Offset in seconds, not a fraction
animation.fillMode = .forwards       // Presentation outside active interval; does not update the model
```

### Animation Scrubbing

```swift
class ScrubbableView: UIView {
    private let animatedLayer = CALayer()

    func setupAnimation() {
        let animation = CABasicAnimation(keyPath: "position.x")
        animation.fromValue = 50
        animation.toValue = 300
        animation.duration = 1.0

        animation.beginTime = 0
        animatedLayer.speed = 0  // Paused
        animatedLayer.timeOffset = 0
        animatedLayer.add(animation, forKey: "scrub")
    }

    func scrubTo(progress: CGFloat) {
        // progress: 0.0 to 1.0
        animatedLayer.timeOffset = CFTimeInterval(max(0, min(1, progress)))
    }
}
```

### Pause and Resume

```swift
func pauseAnimation(layer: CALayer) {
    let pausedTime = layer.convertTime(CACurrentMediaTime(), from: nil)
    layer.speed = 0
    layer.timeOffset = pausedTime
}

func resumeAnimation(layer: CALayer) {
    let pausedTime = layer.timeOffset
    layer.speed = 1.0
    layer.timeOffset = 0.0
    layer.beginTime = 0.0
    let timeSincePause = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
    layer.beginTime = timeSincePause
}
```

---

## Specialized Layers

### CAShapeLayer

Vector paths with an animatable layer representation:

```swift
let shapeLayer = CAShapeLayer()

// Create path
let path = UIBezierPath()
path.move(to: CGPoint(x: 50, y: 100))
path.addCurve(to: CGPoint(x: 250, y: 100),
              controlPoint1: CGPoint(x: 100, y: 0),
              controlPoint2: CGPoint(x: 200, y: 200))

shapeLayer.path = path.cgPath
shapeLayer.strokeColor = UIColor.systemBlue.cgColor
shapeLayer.fillColor = UIColor.clear.cgColor
shapeLayer.lineWidth = 4
shapeLayer.lineCap = .round
shapeLayer.lineJoin = .round

// Stroke animation (drawing effect)
shapeLayer.strokeEnd = 0

let drawAnimation = CABasicAnimation(keyPath: "strokeEnd")
drawAnimation.fromValue = 0
drawAnimation.toValue = 1
drawAnimation.duration = 2.0
shapeLayer.add(drawAnimation, forKey: "draw")
shapeLayer.strokeEnd = 1
```

**Stroke Properties:**

```swift
shapeLayer.lineDashPattern = [10, 5]  // Dashed line
shapeLayer.lineDashPhase = 0          // Animate for marching ants

// Marching ants animation
let march = CABasicAnimation(keyPath: "lineDashPhase")
march.fromValue = 0
march.toValue = 15
march.duration = 0.5
march.repeatCount = .infinity
shapeLayer.add(march, forKey: "march")
```

### CAGradientLayer

```swift
class GradientView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }

    var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }

    func configure() {
        gradientLayer.colors = [
            UIColor.systemPurple.cgColor,
            UIColor.systemBlue.cgColor,
            UIColor.systemCyan.cgColor
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.type = .axial  // or .radial, .conic
    }

    func animateGradient() {
        let colorAnimation = CABasicAnimation(keyPath: "colors")
        colorAnimation.toValue = [
            UIColor.systemRed.cgColor,
            UIColor.systemOrange.cgColor,
            UIColor.systemYellow.cgColor
        ]
        colorAnimation.duration = 2.0
        colorAnimation.autoreverses = true
        colorAnimation.repeatCount = .infinity
        gradientLayer.add(colorAnimation, forKey: "colorShift")
    }
}
```

### CAEmitterLayer

Particle systems:

```swift
func createFireEmitter() -> CAEmitterLayer {
    let emitter = CAEmitterLayer()
    emitter.emitterPosition = CGPoint(x: view.bounds.midX, y: view.bounds.maxY)
    emitter.emitterSize = CGSize(width: 100, height: 1)
    emitter.emitterShape = .line
    emitter.renderMode = .additive

    let cell = CAEmitterCell()
    cell.birthRate = 100
    cell.lifetime = 2.0
    cell.velocity = 200
    cell.velocityRange = 50
    cell.emissionLongitude = -.pi / 2  // Up
    cell.emissionRange = .pi / 4
    cell.scale = 0.5
    cell.scaleRange = 0.2
    cell.scaleSpeed = -0.1
    cell.alphaSpeed = -0.5
    cell.color = UIColor.orange.cgColor
    cell.redRange = 0.3
    cell.greenRange = 0.2
    cell.contents = UIImage(named: "spark")?.cgImage

    emitter.emitterCells = [cell]
    return emitter
}
```

### CAReplicatorLayer

Efficient sublayer duplication:

```swift
func createLoadingIndicator() -> CAReplicatorLayer {
    let replicator = CAReplicatorLayer()
    replicator.frame = CGRect(x: 0, y: 0, width: 60, height: 60)

    let count = 12
    replicator.instanceCount = count
    replicator.instanceDelay = 1.0 / Double(count)
    replicator.instanceTransform = CATransform3DMakeRotation(
        .pi * 2 / CGFloat(count), 0, 0, 1
    )

    let bar = CALayer()
    bar.frame = CGRect(x: 27, y: 5, width: 6, height: 15)
    bar.cornerRadius = 3
    bar.backgroundColor = UIColor.gray.cgColor
    replicator.addSublayer(bar)

    let fade = CABasicAnimation(keyPath: "opacity")
    fade.fromValue = 1.0
    fade.toValue = 0.2
    fade.duration = 1.0
    fade.repeatCount = .infinity
    bar.add(fade, forKey: "fade")

    return replicator
}
```

### CATransformLayer

True 3D layer hierarchy:

```swift
func create3DScene() -> CATransformLayer {
    let transformLayer = CATransformLayer()

    // Set perspective
    var perspective = CATransform3DIdentity
    perspective.m34 = -1.0 / 500.0
    transformLayer.transform = perspective

    // Add sublayers with 3D transforms
    let front = createFace(color: .red)
    front.transform = CATransform3DMakeTranslation(0, 0, 50)

    let back = createFace(color: .blue)
    back.transform = CATransform3DConcat(
        CATransform3DMakeRotation(.pi, 0, 1, 0),
        CATransform3DMakeTranslation(0, 0, -50)
    )

    transformLayer.addSublayer(front)
    transformLayer.addSublayer(back)

    return transformLayer
}
```

---

## Advanced Techniques

### Additive Animations

Enable smooth interruption by adding to current value:

```swift
func animateToPosition(_ newPosition: CGPoint, layer: CALayer) {
    // Get current animated position
    let currentPosition = layer.presentation()?.position ?? layer.position

    let animation = CABasicAnimation(keyPath: "position")
    // Animate from (current - target) to zero
    animation.fromValue = NSValue(cgPoint: CGPoint(
        x: currentPosition.x - newPosition.x,
        y: currentPosition.y - newPosition.y
    ))
    animation.toValue = NSValue(cgPoint: .zero)
    animation.isAdditive = true
    animation.duration = 0.3

    // Replace the previous animation under a stable key. The presentation
    // position already includes its offset; stacking it again would jump.
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    layer.position = newPosition
    CATransaction.commit()
    layer.add(animation, forKey: "position")
}
```

### Custom Animatable Properties

```swift
class ProgressLayer: CALayer {
    @NSManaged var progress: CGFloat

    override init() {
        super.init()
    }

    override init(layer: Any) {
        super.init(layer: layer)
        if let progressLayer = layer as? ProgressLayer {
            progress = progressLayer.progress
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override class func needsDisplay(forKey key: String) -> Bool {
        if key == #keyPath(progress) {
            return true
        }
        return super.needsDisplay(forKey: key)
    }

    override func draw(in ctx: CGContext) {
        // Use presentation layer's value for animation
        let currentProgress = presentation()?.progress ?? progress

        // Draw based on currentProgress
        let rect = bounds.insetBy(dx: 10, dy: bounds.height * 0.4)
        ctx.setFillColor(UIColor.systemGray5.cgColor)
        ctx.fill(rect)

        var progressRect = rect
        progressRect.size.width *= currentProgress
        ctx.setFillColor(UIColor.systemBlue.cgColor)
        ctx.fill(progressRect)
    }
}

// Usage
let progressLayer = ProgressLayer()
progressLayer.frame = CGRect(x: 0, y: 0, width: 200, height: 20)
progressLayer.progress = 0

let animation = CABasicAnimation(keyPath: #keyPath(ProgressLayer.progress))
animation.fromValue = 0
animation.toValue = 1
animation.duration = 2.0
progressLayer.add(animation, forKey: "progress")
progressLayer.progress = 1
```

### Animation Delegate

⚠️ **Warning:** CAAnimation strongly retains its delegate (unusual for Cocoa):

```swift
class AnimationHandler: NSObject, CAAnimationDelegate {
    private var completion: ((Bool) -> Void)?

    init(completion: @escaping (Bool) -> Void) {
        self.completion = completion
    }

    func animationDidStart(_ anim: CAAnimation) {
        print("Animation started")
    }

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        completion?(flag)
        completion = nil  // Break potential cycles
    }
}

// Usage
let animation = CABasicAnimation(keyPath: "opacity")
animation.fromValue = 1
animation.toValue = 0
animation.duration = 0.5
animation.delegate = AnimationHandler { finished in
    print("Finished: \(finished)")
}
layer.add(animation, forKey: "fade")
```

### Preventing Snap-Back

Animations are temporary by default. Three approaches:

```swift
// Method 1: Update model layer (RECOMMENDED)
layer.opacity = 0  // Set final value
let animation = CABasicAnimation(keyPath: "opacity")
animation.fromValue = 1
animation.toValue = 0
animation.duration = 0.5
layer.add(animation, forKey: "fade")

// Method 2: Keep animation (uses more memory)
animation.fillMode = .forwards
animation.isRemovedOnCompletion = false

// Method 3: Update in completion (can cause flash)
animation.delegate = handler
// Update in animationDidStop
```

---

## UIKit Integration

### UIView.animate

Creates CAAnimations automatically and updates model values:

```swift
UIView.animate(withDuration: 0.3) {
    self.box.alpha = 0.5
    self.box.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
    self.box.center = CGPoint(x: 200, y: 300)
}

// With options
UIView.animate(
    withDuration: 0.5,
    delay: 0.1,
    usingSpringWithDamping: 0.7,
    initialSpringVelocity: 0.5,
    options: [.curveEaseOut, .allowUserInteraction]
) {
    self.box.frame = expandedFrame
} completion: { finished in
    print("Complete: \(finished)")
}
```

### Backing-layer properties

Use UIView animation APIs for documented UIView properties. Some backing-layer properties participate in a UIView animation transaction on particular OS versions; do not assume every layer property does. A bare `CATransaction` does not override a UIView backing layer’s disabled action lookup. Use an explicit animation for reliable control:

```swift
let current = button.layer.presentation()?.cornerRadius ?? button.layer.cornerRadius
let animation = CABasicAnimation(keyPath: "cornerRadius")
animation.fromValue = current
animation.toValue = 20
animation.duration = 0.3
CATransaction.begin()
CATransaction.setDisableActions(true)
button.layer.cornerRadius = 20
CATransaction.commit()
button.layer.add(animation, forKey: "cornerRadius")
```

Text/image replacement needs a content transition or another explicit presentation strategy; those values are not interpolated as UIView numeric properties.

### UIViewPropertyAnimator

Interactive, interruptible, pausable animations:

```swift
var animator: UIViewPropertyAnimator!

func setupAnimator() {
    animator = UIViewPropertyAnimator(
        duration: 0.5,
        dampingRatio: 0.8
    ) {
        self.cardView.transform = .identity
        self.cardView.alpha = 1.0
    }

    // Add completion
    animator.addCompletion { position in
        switch position {
        case .end: print("Finished at end")
        case .start: print("Reversed to start")
        case .current: print("Stopped at current")
        @unknown default: break
        }
    }
}

// Gesture-driven animation
@objc func handlePan(_ gesture: UIPanGestureRecognizer) {
    switch gesture.state {
    case .began:
        animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.8) {
            self.cardView.frame = self.expandedFrame
        }
        animator.pauseAnimation()

    case .changed:
        let translation = gesture.translation(in: view)
        let progress = translation.y / 300.0
        animator.fractionComplete = max(0, min(1, progress))

    case .cancelled, .failed:
        animator.isReversed = true
        animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)

    case .ended:
        let velocity = gesture.velocity(in: view).y

        if velocity > 500 || animator.fractionComplete > 0.5 {
            animator.continueAnimation(
                withTimingParameters: UICubicTimingParameters(animationCurve: .easeOut),
                durationFactor: 0
            )
        } else {
            animator.isReversed = true
            animator.continueAnimation(
                withTimingParameters: nil,
                durationFactor: 0
            )
        }

    default:
        break
    }
}
```

### View Controller Transitions

```swift
class CustomTransition: NSObject, UIViewControllerAnimatedTransitioning {
    let duration: TimeInterval = 0.4
    var isPresenting = true

    func transitionDuration(using context: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    func animateTransition(using context: UIViewControllerContextTransitioning) {
        let container = context.containerView

        guard let toView = context.view(forKey: .to),
              let fromView = context.view(forKey: .from) else {
            context.completeTransition(false)
            return
        }

        if isPresenting {
            if let toController = context.viewController(forKey: .to) {
                toView.frame = context.finalFrame(for: toController)
            }
            container.addSubview(toView)
            toView.alpha = 0
            toView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)

            UIView.animate(withDuration: duration, delay: 0,
                          usingSpringWithDamping: 0.8,
                          initialSpringVelocity: 0) {
                toView.alpha = 1
                toView.transform = .identity
            } completion: { _ in
                context.completeTransition(!context.transitionWasCancelled)
            }
        } else {
            UIView.animate(withDuration: duration) {
                fromView.alpha = 0
                fromView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            } completion: { _ in
                let completed = !context.transitionWasCancelled
                if completed {
                    fromView.removeFromSuperview()
                } else {
                    fromView.alpha = 1
                    fromView.transform = .identity
                }
                context.completeTransition(completed)
            }
        }
    }
}
```

---

## Performance

Profile before changing rendering behavior. See [the performance checklist](performance-checklist.md) for frame deadlines, shadow paths, rasterization and Instruments. Rounded corners, masks, transparency and offscreen passes are not universally defects. Preserve visual correctness, avoid blanket rasterization and verify on the target physical device.

## Decision Framework

### When to Use What

| Scenario | Recommended API |
|----------|----------------|
| Simple property animation | `UIView.animate` |
| Multiple views animating together | `UIView.animate` |
| Layer-only properties (cornerRadius, shadow) | `CABasicAnimation` |
| Complex keyframe/path motion | `CAKeyframeAnimation` |
| Physics-based spring | `CASpringAnimation` |
| Interactive gesture-driven | `UIViewPropertyAnimator` |
| Scrubbing/seeking control | `UIViewPropertyAnimator` |
| Custom layer type animation | Direct CAAnimation |
| View controller transitions | `UIViewControllerAnimatedTransitioning` |
| Content transitions (image swap) | `CATransition` |
| Existing layer-based rendering/timing needs | Direct CAAnimation |

### UIView.animate vs CAAnimation

| Feature | UIView.animate | CAAnimation |
|---------|---------------|-------------|
| Auto-updates model | ✅ | ❌ Manual |
| Layer properties | Some participate; verify behavior | Explicit animatable key paths |
| Keyframes | Basic | ✅ Advanced |
| Additive | ❌ | ✅ |
| Animation groups | ❌ | ✅ |
| Timing control | Basic | ✅ Full |
| Performance | Measure the actual interaction | Measure the actual interaction |

---

## Common Pitfalls

### 1. Animation Snaps Back

```swift
// ❌ Model not updated
let animation = CABasicAnimation(keyPath: "opacity")
animation.toValue = 0
layer.add(animation, forKey: nil)
// Layer snaps back to original opacity!

// ✅ Update model first
layer.opacity = 0
let animation = CABasicAnimation(keyPath: "opacity")
animation.fromValue = 1
animation.toValue = 0
layer.add(animation, forKey: nil)
```

### 2. Layer vs View Coordinates

```swift
// CALayer position is center (anchorPoint 0.5, 0.5)
layer.position = CGPoint(x: 100, y: 100)  // Center at (100, 100)

// UIView frame.origin is top-left
view.frame.origin = CGPoint(x: 100, y: 100)  // Top-left at (100, 100)
```

### 3. Auto Layout Conflicts

```swift
// ❌ Animating frame fights Auto Layout
UIView.animate(withDuration: 0.3) {
    self.box.frame.size.height = 200  // Gets reset by layout!
}

// ✅ Animate constraints
heightConstraint.constant = 200
UIView.animate(withDuration: 0.3) {
    self.view.layoutIfNeeded()
}

// ✅ Or use transform (doesn't affect layout)
UIView.animate(withDuration: 0.3) {
    self.box.transform = CGAffineTransform(scaleX: 1.0, y: 2.0)
}
```

### 4. Delegate Retain Cycle

```swift
// ❌ CAAnimation strongly retains delegate
animation.delegate = self  // If self holds animation, leak!

// ✅ Use weak wrapper or dedicated handler
class WeakDelegate: NSObject, CAAnimationDelegate {
    weak var target: CAAnimationDelegate?
    // Forward delegate methods
}
```

### 5. Wrong Thread

```swift
// ❌ UI updates from background
DispatchQueue.global().async {
    self.layer.opacity = 0.5  // Undefined behavior!
}

// ✅ Always update UI on main thread
DispatchQueue.main.async {
    self.layer.opacity = 0.5
}
```

---

## Quick Reference

### Animation Key Paths

```
position, position.x, position.y
bounds, bounds.size, bounds.origin
transform, transform.scale, transform.rotation.z, transform.translation.x
opacity
backgroundColor
cornerRadius
borderWidth, borderColor
shadowOffset, shadowRadius, shadowOpacity, shadowColor, shadowPath
contents
strokeStart, strokeEnd (CAShapeLayer)
strokeColor, fillColor (CAShapeLayer)
colors, locations, startPoint, endPoint (CAGradientLayer)
```

### Timing Function Control Points

| Name | Control Points |
|------|---------------|
| Linear | (0, 0, 1, 1) |
| Ease In | (0.42, 0, 1, 1) |
| Ease Out | (0, 0, 0.58, 1) |
| Ease In Out | (0.42, 0, 0.58, 1) |
| Snappy | (0.4, 0, 0.2, 1) |
| Overshoot | (0.68, -0.55, 0.265, 1.55) |

## See Also

- `animatable-properties.md` — Complete list of animatable key paths
- `layer-types.md` — All CALayer subclasses with examples
- `performance-checklist.md` — Measured rendering and responsiveness checklist
- `uikit-swiftui-bridge.md` — Using Core Animation with SwiftUI
