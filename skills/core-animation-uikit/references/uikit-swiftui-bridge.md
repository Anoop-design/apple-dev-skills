# Using Core Animation with SwiftUI

## Overview

SwiftUI interoperates with UIKit/Core Animation. Use a representable with owned layers when the feature needs:

- Layer-only properties (shadowPath, sublayers)
- Fine-grained timing control
- CAEmitterLayer, CAReplicatorLayer, etc.
- Explicit layer timing or existing UIKit rendering

---

## UIViewRepresentable Wrapper

### Basic Pattern

```swift
struct CoreAnimationView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        // Add your CALayer
        let layer = CAShapeLayer()
        layer.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 100, height: 100)).cgPath
        layer.fillColor = UIColor.systemBlue.cgColor
        view.layer.addSublayer(layer)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Update layer properties based on SwiftUI state
    }
}

// Usage in SwiftUI
struct ContentView: View {
    var body: some View {
        CoreAnimationView()
            .frame(width: 100, height: 100)
    }
}
```

### With Coordinator for Animations

```swift
struct AnimatedShapeView: UIViewRepresentable {
    var isAnimating: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 100, height: 100)).cgPath
        shapeLayer.fillColor = UIColor.systemRed.cgColor
        view.layer.addSublayer(shapeLayer)

        context.coordinator.shapeLayer = shapeLayer
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if isAnimating {
            context.coordinator.startAnimation()
        } else {
            context.coordinator.stopAnimation()
        }
    }

    class Coordinator {
        var shapeLayer: CAShapeLayer?

        func startAnimation() {
            guard let layer = shapeLayer, layer.animation(forKey: "pulse") == nil else { return }

            let pulse = CABasicAnimation(keyPath: "transform.scale")
            pulse.fromValue = 1.0
            pulse.toValue = 1.2
            pulse.duration = 0.5
            pulse.autoreverses = true
            pulse.repeatCount = .infinity
            layer.add(pulse, forKey: "pulse")
        }

        func stopAnimation() {
            shapeLayer?.removeAnimation(forKey: "pulse")
        }
    }
}
```

---

## Particle Effects in SwiftUI

### CAEmitterLayer Wrapper

```swift
struct ParticleEmitterView: UIViewRepresentable {
    var isEmitting: Bool
    var particleImage: UIImage
    var birthRate: Float = 50

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: 100, y: 100)
        emitter.emitterShape = .point

        let cell = CAEmitterCell()
        cell.contents = particleImage.cgImage
        cell.birthRate = 1  // Scale emission using emitter.birthRate
        emitter.birthRate = 0
        cell.lifetime = 2.0
        cell.velocity = 100
        cell.velocityRange = 50
        cell.emissionRange = .pi * 2
        cell.scale = 0.5
        cell.scaleSpeed = -0.2
        cell.alphaSpeed = -0.5

        emitter.emitterCells = [cell]
        view.layer.addSublayer(emitter)

        context.coordinator.emitter = emitter
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.emitter?.birthRate = isEmitting ? birthRate : 0
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var emitter: CAEmitterLayer?
    }
}

// SwiftUI Usage
struct ParticleDemo: View {
    @State private var showParticles = false

    var body: some View {
        ZStack {
            ParticleEmitterView(
                isEmitting: showParticles,
                particleImage: UIImage(systemName: "star.fill")!
                    .withTintColor(.yellow, renderingMode: .alwaysOriginal)
            )

            Button("Celebrate!") {
                showParticles = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showParticles = false
                }
            }
        }
    }
}
```

---

## Custom Drawing Layer

### Animatable Custom Property

```swift
class ProgressRingLayer: CALayer {
    @NSManaged var progress: CGFloat

    override init() {
        super.init()
    }

    override init(layer: Any) {
        super.init(layer: layer)
        if let progressLayer = layer as? ProgressRingLayer {
            progress = progressLayer.progress
        }
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override class func needsDisplay(forKey key: String) -> Bool {
        if key == #keyPath(progress) { return true }
        return super.needsDisplay(forKey: key)
    }

    override func draw(in ctx: CGContext) {
        let currentProgress = presentation()?.progress ?? progress

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - 10

        // Background ring
        ctx.setStrokeColor(UIColor.systemGray5.cgColor)
        ctx.setLineWidth(10)
        ctx.addArc(center: center, radius: radius,
                   startAngle: 0, endAngle: .pi * 2, clockwise: false)
        ctx.strokePath()

        // Progress ring
        ctx.setStrokeColor(UIColor.systemBlue.cgColor)
        ctx.setLineCap(.round)
        let endAngle = -.pi / 2 + (.pi * 2 * currentProgress)
        ctx.addArc(center: center, radius: radius,
                   startAngle: -.pi / 2, endAngle: endAngle, clockwise: false)
        ctx.strokePath()
    }
}

// SwiftUI Wrapper
struct ProgressRingView: UIViewRepresentable {
    var progress: CGFloat
    var animated: Bool = true

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        let ring = ProgressRingLayer()
        ring.contentsScale = view.traitCollection.displayScale
        ring.progress = 0
        view.layer.addSublayer(ring)

        context.coordinator.ringLayer = ring
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let ring = context.coordinator.ringLayer else { return }

        ring.frame = uiView.bounds

        if animated {
            let animation = CABasicAnimation(keyPath: #keyPath(ProgressRingLayer.progress))
            animation.fromValue = ring.presentation()?.progress ?? ring.progress
            animation.toValue = progress
            animation.duration = 0.3
            ring.add(animation, forKey: "progress")
        }
        ring.progress = progress
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var ringLayer: ProgressRingLayer?
    }
}
```

---

## Replicator Patterns

### Loading Indicator

```swift
struct ReplicatorLoadingView: UIViewRepresentable {
    var isAnimating: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        let replicator = CAReplicatorLayer()
        replicator.instanceCount = 12
        replicator.instanceDelay = 0.1
        replicator.instanceTransform = CATransform3DMakeRotation(.pi * 2 / 12, 0, 0, 1)

        let dot = CALayer()
        dot.frame = CGRect(x: 45, y: 5, width: 10, height: 10)
        dot.cornerRadius = 5
        dot.backgroundColor = UIColor.systemBlue.cgColor

        replicator.addSublayer(dot)
        view.layer.addSublayer(replicator)

        context.coordinator.replicator = replicator
        context.coordinator.dot = dot
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.replicator?.frame = uiView.bounds
        context.coordinator.replicator?.position = CGPoint(
            x: uiView.bounds.midX,
            y: uiView.bounds.midY
        )

        if isAnimating {
            context.coordinator.startAnimation()
        } else {
            context.coordinator.stopAnimation()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var replicator: CAReplicatorLayer?
        var dot: CALayer?

        func startAnimation() {
            guard let dot = dot, dot.animation(forKey: "fade") == nil else { return }

            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 1.0
            fade.toValue = 0.2
            fade.duration = 1.2
            fade.repeatCount = .infinity
            dot.add(fade, forKey: "fade")
        }

        func stopAnimation() {
            dot?.removeAllAnimations()
        }
    }
}
```

---

## Shimmer Effect

```swift
struct ShimmerView: UIViewRepresentable {
    var isShimmering: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .systemGray5
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true

        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.clear.cgColor,
            UIColor.white.withAlphaComponent(0.6).cgColor,
            UIColor.clear.cgColor
        ]
        gradient.locations = [0.0, 0.5, 1.0]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        view.layer.addSublayer(gradient)

        context.coordinator.gradient = gradient
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.gradient?.frame = CGRect(
            x: -uiView.bounds.width,
            y: 0,
            width: uiView.bounds.width * 3,
            height: uiView.bounds.height
        )

        if isShimmering {
            context.coordinator.startShimmer()
        } else {
            context.coordinator.stopShimmer()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var gradient: CAGradientLayer?

        func startShimmer() {
            guard let gradient = gradient,
                  gradient.animation(forKey: "shimmer") == nil else { return }

            let animation = CABasicAnimation(keyPath: "transform.translation.x")
            animation.fromValue = 0
            animation.toValue = gradient.bounds.width * 0.66
            animation.duration = 1.5
            animation.repeatCount = .infinity
            gradient.add(animation, forKey: "shimmer")
        }

        func stopShimmer() {
            gradient?.removeAnimation(forKey: "shimmer")
        }
    }
}

// Usage
struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ShimmerView(isShimmering: true)
                .frame(height: 20)
            ShimmerView(isShimmering: true)
                .frame(height: 20)
            ShimmerView(isShimmering: true)
                .frame(width: 150, height: 20)
        }
        .padding()
    }
}
```

---

## 3D Transforms

```swift
struct Card3DView: UIViewRepresentable {
    var rotationX: CGFloat
    var rotationY: CGFloat

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 10)
        view.layer.shadowRadius = 20
        view.layer.shadowOpacity = 0.3

        // Add content
        let label = UILabel()
        label.text = "3D Card"
        label.font = .boldSystemFont(ofSize: 24)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        var transform = CATransform3DIdentity
        transform.m34 = -1.0 / 500.0  // Perspective
        transform = CATransform3DRotate(transform, rotationX, 1, 0, 0)
        transform = CATransform3DRotate(transform, rotationY, 0, 1, 0)

        uiView.layer.transform = transform

        // Update shadow path for performance
        uiView.layer.shadowPath = UIBezierPath(
            roundedRect: uiView.bounds,
            cornerRadius: 16
        ).cgPath
    }
}

// Interactive 3D card in SwiftUI
struct Interactive3DCard: View {
    @State private var rotationX: CGFloat = 0
    @State private var rotationY: CGFloat = 0

    var body: some View {
        Card3DView(rotationX: rotationX, rotationY: rotationY)
            .frame(width: 250, height: 350)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        rotationY = value.translation.width / 100
                        rotationX = -value.translation.height / 100
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            rotationX = 0
                            rotationY = 0
                        }
                    }
            )
    }
}
```

---

## When to Use Core Animation in SwiftUI

| Use Core Animation When | Use SwiftUI Animation When |
|------------------------|---------------------------|
| Particle effects (CAEmitterLayer) | Simple property animations |
| Replicating patterns (CAReplicatorLayer) | Transitions |
| Path morphing (CAShapeLayer) | Matched geometry |
| Layer shadows with shadowPath | Symbol effects |
| 3D transforms with perspective | Phase/keyframe animators |
| Existing layer/timing needs | Standard UI animations |
| Complex stroke animations | Spring-based motion |

---

## Performance Tips for SwiftUI Integration

```swift
struct OptimizedCAView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()

        // Transparent content must not be marked opaque
        view.isOpaque = false
        view.backgroundColor = .clear

        // Disable implicit animations for SwiftUI-driven updates
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        // Setup layers...
        CATransaction.commit()

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Batch updates in transaction
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        // Update layer properties...
        CATransaction.commit()

        // Add explicit animations when needed
        // ...
    }
}
```

## Lifecycle and geometry requirements

These fragments show the rendering technique, not a complete reusable control. Update sublayer frames, paths and display scale in the owning UIView’s `layoutSubviews`/trait handling; SwiftUI can lay a representable out after `updateUIView`. Keep repeated `updateUIView` calls idempotent and avoid restarting an unchanged animation. Stop owned animations in `dismantleUIView`, and respect Reduce Motion/scene activity.

CAEmitterLayer copies its emitter-cell configuration. Change an installed cell through a named key path or adjust the emitter’s birth-rate multiplier; mutating a saved source CAEmitterCell after assignment need not update the displayed emitter.

A SwiftUI `withAnimation` does not automatically interpolate arbitrary CALayer writes in `updateUIView`. Inspect `context.transaction.animation`, then drive a suitable UIKit/CA animation explicitly (or use supported platform animation bridging). The 3D gesture fragment requires that handoff to spring back smoothly; setting the final layer transform alone snaps to it.
