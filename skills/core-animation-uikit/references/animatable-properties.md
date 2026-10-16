# Complete Animatable Properties Reference

## CALayer Properties

### Geometry

| Key Path | Type | Notes |
|----------|------|-------|
| `position` | CGPoint | Layer center |
| `position.x` | CGFloat | Horizontal center |
| `position.y` | CGFloat | Vertical center |
| `bounds` | CGRect | Layer bounds |
| `bounds.size` | CGSize | Width and height |
| `bounds.size.width` | CGFloat | |
| `bounds.size.height` | CGFloat | |
| `bounds.origin` | CGPoint | Usually (0,0) |
| `anchorPoint` | CGPoint | 0-1 normalized |
| `anchorPointZ` | CGFloat | 3D anchor |
| `zPosition` | CGFloat | Z-order |

### Transform

| Key Path | Type | Notes |
|----------|------|-------|
| `transform` | CATransform3D | Full 3D transform |
| `transform.scale` | CGFloat | Uniform scale |
| `transform.scale.x` | CGFloat | |
| `transform.scale.y` | CGFloat | |
| `transform.scale.z` | CGFloat | |
| `transform.rotation` | CGFloat | Radians, around Z |
| `transform.rotation.x` | CGFloat | |
| `transform.rotation.y` | CGFloat | |
| `transform.rotation.z` | CGFloat | Same as .rotation |
| `transform.translation` | CGSize | |
| `transform.translation.x` | CGFloat | |
| `transform.translation.y` | CGFloat | |
| `transform.translation.z` | CGFloat | |
| `sublayerTransform` | CATransform3D | Applied to sublayers |

### Visual

| Key Path | Type | Notes |
|----------|------|-------|
| `opacity` | Float | 0.0 - 1.0 |
| `hidden` | Bool | Discrete, no interpolation |
| `backgroundColor` | CGColor | |
| `cornerRadius` | CGFloat | |
| `borderWidth` | CGFloat | |
| `borderColor` | CGColor | |
| `contents` | CGImage | Crossfade between images |
| `contentsRect` | CGRect | Sprite sheet animation |
| `contentsCenter` | CGRect | Stretching region |
| `contentsScale` | CGFloat | |
| `minificationFilter` | String | Discrete |
| `magnificationFilter` | String | Discrete |

### Shadow

| Key Path | Type | Notes |
|----------|------|-------|
| `shadowColor` | CGColor | |
| `shadowOpacity` | Float | 0.0 - 1.0 |
| `shadowOffset` | CGSize | |
| `shadowRadius` | CGFloat | Blur amount |
| `shadowPath` | CGPath | Use a matching path when the shadow silhouette is known |

### Mask & Clipping

| Key Path | Type | Notes |
|----------|------|-------|
| `mask` | CALayer | Not an implicitly animatable property; animate properties of the mask layer |
| `masksToBounds` | Bool | Discrete |

## CAShapeLayer Properties

| Key Path | Type | Notes |
|----------|------|-------|
| `path` | CGPath | Shape path |
| `fillColor` | CGColor | |
| `fillRule` | String | Discrete |
| `strokeColor` | CGColor | |
| `strokeStart` | CGFloat | 0.0 - 1.0, for drawing animation |
| `strokeEnd` | CGFloat | 0.0 - 1.0, for drawing animation |
| `lineWidth` | CGFloat | |
| `lineCap` | String | Discrete |
| `lineJoin` | String | Discrete |
| `lineDashPhase` | CGFloat | Marching ants |
| `miterLimit` | CGFloat | |

## CAGradientLayer Properties

| Key Path | Type | Notes |
|----------|------|-------|
| `colors` | [CGColor] | Array of colors |
| `locations` | [NSNumber] | Color stop positions |
| `startPoint` | CGPoint | 0-1 normalized |
| `endPoint` | CGPoint | 0-1 normalized |
| `type` | String | Discrete (.axial, .radial, .conic) |

## CAEmitterLayer Properties

| Key Path | Type | Notes |
|----------|------|-------|
| `emitterPosition` | CGPoint | |
| `emitterZPosition` | CGFloat | |
| `emitterSize` | CGSize | |
| `birthRate` | Float | Multiplier for all cells |
| `lifetime` | Float | Multiplier for all cells |
| `velocity` | Float | Multiplier for all cells |

## CATextLayer Properties

| Key Path | Type | Notes |
|----------|------|-------|
| `fontSize` | CGFloat | |
| `foregroundColor` | CGColor | |

## CAReplicatorLayer Properties

| Key Path | Type | Notes |
|----------|------|-------|
| `instanceCount` | Int | Number of copies |
| `instanceDelay` | CFTimeInterval | Animation delay per instance |
| `instanceTransform` | CATransform3D | Transform per instance |
| `instanceColor` | CGColor | Base color |
| `instanceRedOffset` | Float | Color shift per instance |
| `instanceGreenOffset` | Float | |
| `instanceBlueOffset` | Float | |
| `instanceAlphaOffset` | Float | |

## Non-Animatable Properties

These do NOT animate:

- `delegate`
- `name`
- `actions`
- `style`
- `needsDisplayOnBoundsChange`
- `edgeAntialiasingMask`
- `allowsEdgeAntialiasing`
- `rasterizationScale` (can cause flicker)
- `shouldRasterize` (discrete)
- `drawsAsynchronously`
- `allowsGroupOpacity`

## UIView Animatable Properties

These work with `UIView.animate`:

```swift
frame
bounds
center
transform (CGAffineTransform)
alpha
backgroundColor
contentStretch (deprecated)
```

## Backing-layer property animation

UIView animation blocks manage view properties and may support some backing-layer properties. Do not treat all layer-only properties as either always supported or always unsupported. Use explicit CAAnimation when a property needs guaranteed key-path control, and update its model value with implicit actions disabled. A standalone CATransaction does not force UIView’s disabled layer actions to animate.

Check each property’s Apple declaration before relying on implicit animation. The table is a discovery aid, not a guarantee that interpolation makes sense for arbitrary values (for example, incompatible paths or gradient stops).
