# CALayer Types Reference

## CALayer Hierarchy

```
CALayer
├── CAShapeLayer          - Vector paths
├── CAGradientLayer       - Color gradients
├── CATextLayer           - Text rendering
├── CAScrollLayer         - Scrollable content
├── CATiledLayer          - Large zoomable content
├── CAEmitterLayer        - Particle systems
├── CAReplicatorLayer     - Efficient sublayer duplication
├── CATransformLayer      - True 3D hierarchies
└── CAEAGLLayer/CAMetalLayer - OpenGL/Metal rendering
```

---

## CALayer (Base)

The foundation for all layer types.

```swift
let layer = CALayer()
layer.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
layer.backgroundColor = UIColor.systemBlue.cgColor
layer.cornerRadius = 16
layer.borderWidth = 2
layer.borderColor = UIColor.white.cgColor

// Shadow (provide shadowPath when the intended outline is known)
layer.shadowColor = UIColor.black.cgColor
layer.shadowOffset = CGSize(width: 0, height: 4)
layer.shadowRadius = 8
layer.shadowOpacity = 0.3
layer.shadowPath = UIBezierPath(roundedRect: layer.bounds,
                                 cornerRadius: 16).cgPath

// Image content
layer.contents = UIImage(named: "photo")?.cgImage
layer.contentsGravity = .resizeAspectFill
layer.masksToBounds = true
```

---

## CAShapeLayer

Vector paths with animatable shape properties. Complexity and redraw frequency determine whether this outperforms custom drawing.

### Basic Shape

```swift
let circleLayer = CAShapeLayer()
circleLayer.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 100, height: 100)).cgPath
circleLayer.fillColor = UIColor.systemRed.cgColor
circleLayer.strokeColor = UIColor.white.cgColor
circleLayer.lineWidth = 3
```

### Drawing Animation

```swift
let pathLayer = CAShapeLayer()
let path = UIBezierPath()
path.move(to: CGPoint(x: 0, y: 50))
path.addQuadCurve(to: CGPoint(x: 200, y: 50), controlPoint: CGPoint(x: 100, y: 0))

pathLayer.path = path.cgPath
pathLayer.strokeColor = UIColor.systemBlue.cgColor
pathLayer.fillColor = UIColor.clear.cgColor
pathLayer.lineWidth = 4
pathLayer.lineCap = .round
pathLayer.strokeEnd = 0

// Animate drawing
let draw = CABasicAnimation(keyPath: "strokeEnd")
draw.fromValue = 0
draw.toValue = 1
draw.duration = 1.5
draw.timingFunction = CAMediaTimingFunction(name: .easeOut)
pathLayer.add(draw, forKey: "drawLine")
pathLayer.strokeEnd = 1
```

### Dashed Lines & Marching Ants

```swift
let dashedLayer = CAShapeLayer()
dashedLayer.path = UIBezierPath(rect: CGRect(x: 10, y: 10, width: 180, height: 100)).cgPath
dashedLayer.strokeColor = UIColor.black.cgColor
dashedLayer.fillColor = UIColor.clear.cgColor
dashedLayer.lineWidth = 2
dashedLayer.lineDashPattern = [8, 4]  // 8pt dash, 4pt gap

// Marching ants animation
let march = CABasicAnimation(keyPath: "lineDashPhase")
march.fromValue = 0
march.toValue = 12  // Sum of dash pattern
march.duration = 0.5
march.repeatCount = .infinity
dashedLayer.add(march, forKey: "marchingAnts")
```

### Path Morphing

Use paths with matching element counts/types and compatible control-point ordering. A UIBezierPath rectangle and oval do not guarantee a meaningful morph; build corresponding cubic segments or crossfade instead. The following fragment illustrates animation setup only.

```swift
let morphLayer = CAShapeLayer()
let squarePath = UIBezierPath(rect: CGRect(x: 25, y: 25, width: 50, height: 50))
let circlePath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 100, height: 100))

morphLayer.path = squarePath.cgPath
morphLayer.fillColor = UIColor.systemPurple.cgColor

let morph = CABasicAnimation(keyPath: "path")
morph.fromValue = squarePath.cgPath
morph.toValue = circlePath.cgPath
morph.duration = 1.0
morph.autoreverses = true
morph.repeatCount = .infinity
morphLayer.add(morph, forKey: "morphShape")
```

---

## CAGradientLayer

### Linear Gradient

```swift
let gradient = CAGradientLayer()
gradient.frame = view.bounds
gradient.colors = [
    UIColor.systemPurple.cgColor,
    UIColor.systemBlue.cgColor,
    UIColor.systemCyan.cgColor
]
gradient.locations = [0.0, 0.5, 1.0]
gradient.startPoint = CGPoint(x: 0, y: 0)  // Top-left
gradient.endPoint = CGPoint(x: 1, y: 1)    // Bottom-right
```

### Radial Gradient (iOS 12+)

```swift
let radialGradient = CAGradientLayer()
radialGradient.type = .radial
radialGradient.colors = [
    UIColor.white.cgColor,
    UIColor.systemBlue.cgColor
]
radialGradient.startPoint = CGPoint(x: 0.5, y: 0.5)  // Center
radialGradient.endPoint = CGPoint(x: 1, y: 1)        // Corner (defines radius)
```

### Conic Gradient (iOS 12+)

```swift
let conicGradient = CAGradientLayer()
conicGradient.type = .conic
conicGradient.colors = [
    UIColor.red.cgColor,
    UIColor.yellow.cgColor,
    UIColor.green.cgColor,
    UIColor.cyan.cgColor,
    UIColor.blue.cgColor,
    UIColor.magenta.cgColor,
    UIColor.red.cgColor
]
conicGradient.startPoint = CGPoint(x: 0.5, y: 0.5)
```

### Animated Shimmer Effect

```swift
let shimmerGradient = CAGradientLayer()
shimmerGradient.colors = [
    UIColor.clear.cgColor,
    UIColor.white.withAlphaComponent(0.6).cgColor,
    UIColor.clear.cgColor
]
shimmerGradient.locations = [0.0, 0.5, 1.0]
shimmerGradient.startPoint = CGPoint(x: 0, y: 0.5)
shimmerGradient.endPoint = CGPoint(x: 1, y: 0.5)

let shimmer = CABasicAnimation(keyPath: "locations")
shimmer.fromValue = [-1.0, -0.5, 0.0]
shimmer.toValue = [1.0, 1.5, 2.0]
shimmer.duration = 1.5
shimmer.repeatCount = .infinity
shimmerGradient.add(shimmer, forKey: "shimmer")
```

---

## CAEmitterLayer

Particle systems for fire, smoke, confetti, rain, etc.

### Confetti

```swift
func createConfetti() -> CAEmitterLayer {
    let emitter = CAEmitterLayer()
    emitter.emitterPosition = CGPoint(x: view.center.x, y: -20)
    emitter.emitterShape = .line
    emitter.emitterSize = CGSize(width: view.frame.width, height: 1)

    func makeCell(color: UIColor) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.birthRate = 5
        cell.lifetime = 10
        cell.velocity = 150
        cell.velocityRange = 50
        cell.emissionLongitude = .pi / 2  // Down in UIKit coordinates
        cell.emissionRange = .pi / 4
        cell.spin = 3
        cell.spinRange = 4
        cell.scale = 0.4
        cell.scaleRange = 0.2
        cell.color = color.cgColor

        // Create simple rectangle for confetti
        let size: CGFloat = 10
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size, height: size * 1.5), false, 0)
        UIColor.white.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: size, height: size * 1.5))
        cell.contents = UIGraphicsGetImageFromCurrentImageContext()?.cgImage
        UIGraphicsEndImageContext()

        return cell
    }

    emitter.emitterCells = [
        makeCell(color: .systemRed),
        makeCell(color: .systemBlue),
        makeCell(color: .systemGreen),
        makeCell(color: .systemYellow),
        makeCell(color: .systemPurple)
    ]

    return emitter
}
```

### Fire Effect

```swift
func createFire() -> CAEmitterLayer {
    let emitter = CAEmitterLayer()
    emitter.emitterPosition = CGPoint(x: 100, y: 200)
    emitter.emitterSize = CGSize(width: 50, height: 10)
    emitter.emitterShape = .line
    emitter.renderMode = .additive  // Glow effect

    let fire = CAEmitterCell()
    fire.birthRate = 150
    fire.lifetime = 1.5
    fire.velocity = 80
    fire.velocityRange = 30
    fire.emissionLongitude = -.pi / 2  // Up
    fire.emissionRange = .pi / 8
    fire.scale = 0.5
    fire.scaleSpeed = -0.3
    fire.alphaSpeed = -0.8
    fire.color = UIColor(red: 1, green: 0.6, blue: 0.2, alpha: 1).cgColor
    fire.redRange = 0.3
    fire.greenRange = 0.3

    // Use circular gradient image for particle
    let size: CGFloat = 64
    UIGraphicsBeginImageContextWithOptions(CGSize(width: size, height: size), false, 0)
    let ctx = UIGraphicsGetCurrentContext()!
    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [UIColor.white.cgColor, UIColor.clear.cgColor] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawRadialGradient(gradient,
                           startCenter: CGPoint(x: size/2, y: size/2), startRadius: 0,
                           endCenter: CGPoint(x: size/2, y: size/2), endRadius: size/2,
                           options: [])
    fire.contents = UIGraphicsGetImageFromCurrentImageContext()?.cgImage
    UIGraphicsEndImageContext()

    emitter.emitterCells = [fire]
    return emitter
}
```

---

## CAReplicatorLayer

Efficiently duplicates sublayers with transforms and animation delays.

### Loading Spinner

```swift
func createSpinner() -> CAReplicatorLayer {
    let replicator = CAReplicatorLayer()
    replicator.frame = CGRect(x: 0, y: 0, width: 60, height: 60)

    let dotCount = 12
    replicator.instanceCount = dotCount
    replicator.instanceDelay = 0.1

    let angle = CGFloat.pi * 2 / CGFloat(dotCount)
    replicator.instanceTransform = CATransform3DMakeRotation(angle, 0, 0, 1)

    let dot = CALayer()
    dot.frame = CGRect(x: 27, y: 5, width: 6, height: 6)
    dot.cornerRadius = 3
    dot.backgroundColor = UIColor.systemBlue.cgColor
    replicator.addSublayer(dot)

    let scale = CABasicAnimation(keyPath: "transform.scale")
    scale.fromValue = 1.0
    scale.toValue = 0.3
    scale.duration = Double(dotCount) * 0.1
    scale.repeatCount = .infinity
    dot.add(scale, forKey: "pulse")

    return replicator
}
```

### Reflection Effect

```swift
// Use a dedicated container. Never add view.layer beneath its own descendant.
class ReflectionView: UIView {
    override class var layerClass: AnyClass { CAReplicatorLayer.self }

    override func layoutSubviews() {
        super.layoutSubviews()
        let replicator = layer as! CAReplicatorLayer
        replicator.instanceCount = 2
        replicator.instanceTransform = CATransform3DConcat(
            CATransform3DMakeScale(1, -1, 1),
            CATransform3DMakeTranslation(0, bounds.height * 2 + 5, 0)
        )
        replicator.instanceAlphaOffset = -0.6
    }
}
// Add the content UIView as a subview of ReflectionView, then lay it out.
```

---

## CATransformLayer

Preserves 3D z-positions for sublayers (regular CALayer flattens).

### 3D Cube

```swift
func createCube(size: CGFloat) -> CATransformLayer {
    let cube = CATransformLayer()

    // Set perspective on parent
    var perspective = CATransform3DIdentity
    perspective.m34 = -1.0 / 500.0
    cube.transform = perspective

    func face(color: UIColor, transform: CATransform3D) -> CALayer {
        let layer = CALayer()
        layer.frame = CGRect(x: -size/2, y: -size/2, width: size, height: size)
        layer.backgroundColor = color.cgColor
        layer.borderWidth = 2
        layer.borderColor = UIColor.white.cgColor
        layer.transform = transform
        return layer
    }

    let halfSize = size / 2

    // Front
    cube.addSublayer(face(color: .systemRed,
                          transform: CATransform3DMakeTranslation(0, 0, halfSize)))
    // Back
    cube.addSublayer(face(color: .systemBlue,
                          transform: CATransform3DConcat(
                              CATransform3DMakeRotation(.pi, 0, 1, 0),
                              CATransform3DMakeTranslation(0, 0, halfSize))))
    // Left
    cube.addSublayer(face(color: .systemGreen,
                          transform: CATransform3DConcat(
                              CATransform3DMakeRotation(-.pi/2, 0, 1, 0),
                              CATransform3DMakeTranslation(0, 0, halfSize))))
    // Right
    cube.addSublayer(face(color: .systemYellow,
                          transform: CATransform3DConcat(
                              CATransform3DMakeRotation(.pi/2, 0, 1, 0),
                              CATransform3DMakeTranslation(0, 0, halfSize))))
    // Top
    cube.addSublayer(face(color: .systemOrange,
                          transform: CATransform3DConcat(
                              CATransform3DMakeRotation(-.pi/2, 1, 0, 0),
                              CATransform3DMakeTranslation(0, 0, halfSize))))
    // Bottom
    cube.addSublayer(face(color: .systemPurple,
                          transform: CATransform3DConcat(
                              CATransform3DMakeRotation(.pi/2, 1, 0, 0),
                              CATransform3DMakeTranslation(0, 0, halfSize))))

    return cube
}

// Animate rotation
let rotation = CABasicAnimation(keyPath: "transform.rotation.y")
rotation.fromValue = 0
rotation.toValue = CGFloat.pi * 2  // Component rotation preserves a full turn
rotation.duration = 8.0
rotation.repeatCount = .infinity
cube.add(rotation, forKey: "spin")
```

---

## CATextLayer

Renders text efficiently on GPU.

```swift
let textLayer = CATextLayer()
textLayer.string = "Hello, Core Animation!"
textLayer.fontSize = 24
textLayer.foregroundColor = UIColor.label.cgColor
textLayer.alignmentMode = .center
textLayer.contentsScale = view.traitCollection.displayScale  // IMPORTANT for crisp text
textLayer.isWrapped = true
textLayer.truncationMode = .end

// Attributed string
let attributed = NSAttributedString(
    string: "Styled Text",
    attributes: [
        .font: UIFont.boldSystemFont(ofSize: 32),
        .foregroundColor: UIColor.systemBlue
    ]
)
textLayer.string = attributed
```

---

## CATiledLayer

For large zoomable content (maps, high-res images).

```swift
class TiledView: UIView {
    override class var layerClass: AnyClass { CATiledLayer.self }

    override init(frame: CGRect) {
        super.init(frame: frame)

        let tiledLayer = layer as! CATiledLayer
        tiledLayer.tileSize = CGSize(width: 256, height: 256)
        tiledLayer.levelsOfDetail = 4
        tiledLayer.levelsOfDetailBias = 3
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func draw(_ rect: CGRect) {
        // Called per-tile on background thread
        guard let context = UIGraphicsGetCurrentContext() else { return }

        // Draw tile content
        // Use rect to determine which tile this is
    }
}
```

---

## CAScrollLayer

Programmatic layer scrolling. It does not supply UIScrollView’s gestures, accessibility, deceleration or zoom behavior.

```swift
let scrollLayer = CAScrollLayer()
scrollLayer.frame = view.bounds
scrollLayer.scrollMode = .both  // .horizontally, .vertically, .both, .none

let content = CALayer()
content.frame = CGRect(x: 0, y: 0, width: 2000, height: 2000)
// Add content sublayers...
scrollLayer.addSublayer(content)

// Scroll programmatically
scrollLayer.scroll(to: CGPoint(x: 500, y: 500))
```

---

## Layer Selection Guide

| Use Case | Layer Type |
|----------|------------|
| Basic rectangles, images | `CALayer` |
| Vector shapes, paths | `CAShapeLayer` |
| Color gradients | `CAGradientLayer` |
| Text rendering | `CATextLayer` |
| Particle effects | `CAEmitterLayer` |
| Repeating elements | `CAReplicatorLayer` |
| 3D scenes | `CATransformLayer` |
| Large zoomable images | `CATiledLayer` |
| Metal rendering | `CAMetalLayer` |
