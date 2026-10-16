# SwiftUI Shaders

Create stunning GPU-accelerated visual effects with Metal shaders in SwiftUI.

## Overview

SwiftUI Shaders (iOS 17+) let you write custom Metal shader functions that run on the GPU for every pixel of a view. They enable:

- **Custom fills** for shapes and text
- **Color effects** that transform pixel colors
- **Distortion effects** that warp geometry
- **Layer effects** that access surrounding pixels

## Quick Start

### 1. Create a Metal File

Add a new Metal file to your Xcode project (File → New → File → Metal File):

```metal
// Shaders.metal
#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

[[stitchable]] half4 colorInvert(float2 position, half4 color) {
    return half4(half3(color.a) - color.rgb, color.a);
}
```

### 2. Use in SwiftUI

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Image("photo")
            .colorEffect(ShaderLibrary.colorInvert())
    }
}
```

## Shader Types

### Color Effect

Transforms the color of each pixel. Cannot access neighboring pixels.

**Metal signature:**
```metal
[[stitchable]] half4 name(float2 position, half4 color, args...)
```

**SwiftUI usage:**
```swift
view.colorEffect(ShaderLibrary.myColorShader())
```

### Distortion Effect

Transforms the position where each pixel samples from. Changes geometry without changing colors.

**Metal signature:**
```metal
[[stitchable]] float2 name(float2 position, args...)
```

**SwiftUI usage:**
```swift
view.distortionEffect(
    ShaderLibrary.myDistortion(),
    maxSampleOffset: CGSize(width: 100, height: 100)
)
```

### Layer Effect

Most powerful — can sample any pixel within `maxSampleOffset` of current position. Enables blur, ripple, and complex effects.

**Metal signature:**
```metal
[[stitchable]] half4 name(float2 position, SwiftUI::Layer layer, args...)
```

**SwiftUI usage:**
```swift
view.layerEffect(
    ShaderLibrary.myLayerEffect(),
    maxSampleOffset: CGSize(width: 50, height: 50)
)
```

### Shape Fill

Use shaders as `ShapeStyle` for fills and strokes.

**Metal signature:**
```metal
[[stitchable]] half4 name(float2 position, args...)
```

**SwiftUI usage:**
```swift
Circle()
    .fill(ShaderLibrary.myPattern())

Text("Hello")
    .foregroundStyle(ShaderLibrary.myGradient())
```

## Metal Basics

### The `[[stitchable]]` Attribute

Required for all SwiftUI shaders. Tells the compiler this function can be dynamically linked:

```metal
[[stitchable]] half4 myShader(float2 position, half4 color) {
    // shader code
}
```

### Include Headers

Always include these at the top of your Metal file:

```metal
#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;
```

### Common Types

| Metal Type | Description | Swift Equivalent |
|------------|-------------|------------------|
| `float` | 32-bit float | `Float` |
| `float2` | 2D vector | `CGPoint`, `CGSize` |
| `float3` | 3D vector | — |
| `float4` | 4D vector | `CGRect` (x,y,w,h) |
| `half` | 16-bit float | — |
| `half4` | RGBA color | `Color` |

### Vector Operations

```metal
float2 pos = float2(100.0, 200.0);
float len = length(pos);           // Distance from origin
float2 norm = normalize(pos);      // Unit vector
float d = distance(pos, other);    // Distance between points
float2 mixed = mix(a, b, 0.5);     // Linear interpolation

half4 color = half4(1.0, 0.0, 0.0, 1.0);  // Red
color.rgb;    // Access RGB components
color.a;      // Access alpha
color.rg;     // Swizzle: just red and green
```

## Shader Arguments

Pass values from SwiftUI to Metal using `Shader.Argument`:

### Argument Types

```swift
// Float (single value)
ShaderLibrary.myShader(.float(0.5))

// Float2 (point or size)
ShaderLibrary.myShader(.float2(CGPoint(x: 100, y: 200)))
ShaderLibrary.myShader(.float2(CGSize(width: 100, height: 200)))

// Color
ShaderLibrary.myShader(.color(.red))

// Image
ShaderLibrary.myShader(.image(Image("texture")))

// Bounding rect (automatic)
ShaderLibrary.myShader(.boundingRect)

// Float array
ShaderLibrary.myShader(.floatArray([1.0, 2.0, 3.0]))
```

### Corresponding Metal Parameters

```metal
// .float(value)
[[stitchable]] half4 shader(float2 pos, half4 color, float value)

// .float2(point)
[[stitchable]] half4 shader(float2 pos, half4 color, float2 point)

// .color(color)
[[stitchable]] half4 shader(float2 pos, half4 color, half4 tint)

// .image(image)
[[stitchable]] half4 shader(float2 pos, half4 color, texture2d<half> tex)

// .boundingRect
[[stitchable]] half4 shader(float2 pos, half4 color, float4 bounds)

// .floatArray(array)
[[stitchable]] half4 shader(float2 pos, half4 color,
                            device const float *values, int count)
```

## Layer Sampling

For `layerEffect`, use `SwiftUI::Layer` to sample pixels:

```metal
[[stitchable]] half4 blur(float2 position, SwiftUI::Layer layer) {
    half4 sum = half4(0);

    // Sample 9 pixels in a 3x3 grid
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            float2 offset = float2(x, y) * 2.0;
            sum += layer.sample(position + offset);
        }
    }

    return sum / 9.0;
}
```

**Important:** Only sample within `maxSampleOffset` bounds!

```swift
view.layerEffect(
    ShaderLibrary.blur(),
    maxSampleOffset: CGSize(width: 10, height: 10)  // Must cover your sampling range
)
```

## Animating Shaders

Shaders have no concept of time. Drive animations from SwiftUI:

### Using TimelineView

```swift
struct AnimatedShaderView: View {
    @State private var startDate = Date()

    var body: some View {
        TimelineView(.animation) { context in
            let elapsed = context.date.timeIntervalSince(startDate)

            Rectangle()
                .distortionEffect(
                    ShaderLibrary.wave(.float(elapsed), .float(10), .float(0.05)),
                    maxSampleOffset: CGSize(width: 10, height: 0)
                )
        }
    }
}
```

### Using Keyframe Animation

```swift
struct RippleView: View {
    @State private var trigger = false
    @State private var origin = CGPoint.zero

    var body: some View {
        Image("photo")
            .keyframeAnimator(
                initialValue: AnimationValues(),
                trigger: trigger
            ) { view, value in
                view.layerEffect(
                    ShaderLibrary.ripple(
                        .float2(origin),
                        .float(value.time),
                        .float(value.amplitude),
                        .float(0.1),
                        .float(0.01)
                    ),
                    maxSampleOffset: CGSize(width: 100, height: 100)
                )
            } keyframes: { _ in
                KeyframeTrack(\.time) {
                    MoveKeyframe(0.0)
                    LinearKeyframe(1.0, duration: 0.8)
                }
                KeyframeTrack(\.amplitude) {
                    LinearKeyframe(20.0, duration: 0.2)
                    LinearKeyframe(0.0, duration: 0.6)
                }
            }
            .onTapGesture { location in
                origin = location
                trigger.toggle()
            }
    }

    struct AnimationValues {
        var time: Float = 0
        var amplitude: Float = 0
    }
}
```

## Common Shader Examples

### Grayscale

```metal
[[stitchable]] half4 grayscale(float2 position, half4 color) {
    float gray = dot(color.rgb, half3(0.299, 0.587, 0.114));
    return half4(gray, gray, gray, color.a);
}
```

### Pixelate

```metal
[[stitchable]] half4 pixelate(float2 position, SwiftUI::Layer layer,
                               float size) {
    size = max(size, 1.0);
    float2 pixelPos = floor(position / size) * size;
    return layer.sample(pixelPos);
}
```

### Wave Distortion

```metal
[[stitchable]] float2 wave(float2 position, float time,
                            float amplitude, float frequency) {
    float offset = sin(position.y * frequency + time) * amplitude;
    return float2(position.x + offset, position.y);
}
```

### Ripple Effect

```metal
[[stitchable]] half4 ripple(float2 position, SwiftUI::Layer layer,
                            float2 origin, float time,
                            float amplitude, float frequency,
                            float decay) {
    float distance = length(position - origin);
    float wave = sin(distance * frequency - time * 10.0);
    float falloff = exp(-distance * decay) * exp(-time * 2.0);

    float2 delta = position - origin;
    float2 direction = length(delta) > 0 ? delta / length(delta) : float2(0);
    float2 offset = direction * wave * amplitude * falloff;
    return layer.sample(position + offset);
}
```

### Stripe Pattern

```metal
[[stitchable]] half4 stripes(float2 position, float spacing,
                              float angle, half4 color) {
    float cosAngle = cos(angle);
    float sinAngle = sin(angle);
    float2 rotated = float2(
        position.x * cosAngle - position.y * sinAngle,
        position.x * sinAngle + position.y * cosAngle
    );

    float stripe = step(0.5, fract(rotated.x / max(spacing, 0.0001)));
    return color * stripe;
}
```

### Chromatic Aberration

```metal
[[stitchable]] half4 chromatic(float2 position, SwiftUI::Layer layer,
                               float2 center, float strength) {
    float2 delta = position - center;
    float dist = length(delta);
    float2 dir = dist > 0 ? delta / dist : float2(0);

    half4 r = layer.sample(position + dir * dist * strength);
    half4 g = layer.sample(position);
    half4 b = layer.sample(position - dir * dist * strength);

    return half4(r.r, g.g, b.b, g.a);
}
```

### Vignette

```metal
[[stitchable]] half4 vignette(float2 position, half4 color,
                              float4 bounds, float intensity) {
    float2 center = bounds.xy + bounds.zw / 2.0;
    float2 uv = (position - bounds.xy) / max(bounds.zw, float2(0.0001));
    float dist = distance(uv, float2(0.5, 0.5));

    float vignette = 1.0 - smoothstep(0.2, 0.8, dist * intensity);
    return half4(color.rgb * vignette, color.a);
}
```

## Premultiplied Alpha

SwiftUI uses premultiplied alpha. When modifying colors:

```metal
// ❌ Wrong — breaks transparency
[[stitchable]] half4 tint(float2 pos, half4 color, half4 tintColor) {
    return half4(tintColor.rgb, color.a);
}

// ✅ Correct — multiply RGB by alpha
[[stitchable]] half4 tint(float2 pos, half4 color, half4 tintColor) {
    return half4(tintColor.rgb * color.a, tintColor.a * color.a);
}
```

## Performance Tips

1. **Minimize sampling** — Each `layer.sample()` is expensive
2. **Use `half` over `float`** — Half precision is faster when sufficient
3. **Avoid branching** — GPUs prefer uniform code paths
4. **Keep `maxSampleOffset` small** — Larger offsets reduce performance
5. **Test on device** — Simulator performance differs from real devices

## Debugging

Metal debugger doesn't support `[[stitchable]]` functions directly. Debug strategies:

1. **Output debug colors** — Return specific colors to verify code paths
2. **Simplify incrementally** — Start simple, add complexity gradually
3. **Check bounds** — Verify positions and offsets are in expected ranges
4. **Test in isolation** — Create minimal test views

## Availability

- iOS 17.0+
- macOS 14.0+
- tvOS 17.0+
- Unavailable on watchOS in the inspected SDK
- visionOS 1.0+

## See Also

- `shader-api.md` — Complete API reference
- `metal-reference.md` — Metal Shading Language reference
- `shader-recipes.md` — Ready-to-use shader effects
