# Shader Recipes

Adaptable effects with SwiftUI integration. Include metal_stdlib and SwiftUI/SwiftUI_Metal.h in the Metal target. Bound all user parameters; snippets are not complete app components. Preserve premultiplied alpha and use conservative sample offsets.

## Color Effects

### Grayscale

```metal
// Shaders.metal
[[stitchable]] half4 grayscale(float2 position, half4 color) {
    half gray = dot(color.rgb, half3(0.299, 0.587, 0.114));
    return half4(gray, gray, gray, color.a);
}
```

```swift
// SwiftUI
Image("photo")
    .colorEffect(ShaderLibrary.grayscale())
```

### Sepia Tone

```metal
[[stitchable]] half4 sepia(float2 position, half4 color, float intensity) {
    half3 sepia = half3(
        dot(color.rgb, half3(0.393, 0.769, 0.189)),
        dot(color.rgb, half3(0.349, 0.686, 0.168)),
        dot(color.rgb, half3(0.272, 0.534, 0.131))
    );
    return half4(mix(color.rgb, sepia, half(intensity)), color.a);
}
```

```swift
Image("photo")
    .colorEffect(ShaderLibrary.sepia(.float(0.8)))
```

### Color Invert

```metal
[[stitchable]] half4 invert(float2 position, half4 color) {
    return half4(half3(color.a) - color.rgb, color.a);
}
```

### Brightness & Contrast

```metal
[[stitchable]] half4 brightnessContrast(
    float2 position,
    half4 color,
    float brightness,
    float contrast
) {
    half3 straight = color.a > 0 ? color.rgb / color.a : half3(0);
    half3 result = (straight * half(brightness) - 0.5h) * half(contrast) + 0.5h;
    return half4(clamp(result, 0.0h, 1.0h) * color.a, color.a);
}
```

```swift
Image("photo")
    .colorEffect(ShaderLibrary.brightnessContrast(
        .float(1.2),   // brightness
        .float(1.5)    // contrast
    ))
```

### Hue Shift

```metal
half3 rgb2hsv(half3 c) {
    half4 K = half4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
    half4 p = mix(half4(c.bg, K.wz), half4(c.gb, K.xy), step(c.b, c.g));
    half4 q = mix(half4(p.xyw, c.r), half4(c.r, p.yzx), step(p.x, c.r));
    half d = q.x - min(q.w, q.y);
    half e = 0.0001h; // Representable in half precision; avoids division by zero
    return half3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

half3 hsv2rgb(half3 c) {
    half4 K = half4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    half3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

[[stitchable]] half4 hueShift(float2 position, half4 color, float shift) {
    half3 hsv = rgb2hsv(color.rgb);
    hsv.x = fract(hsv.x + half(shift));
    return half4(hsv2rgb(hsv), color.a);
}
```

```swift
Image("photo")
    .colorEffect(ShaderLibrary.hueShift(.float(0.5)))  // 0-1
```

### Vignette

```metal
[[stitchable]] half4 vignette(
    float2 position,
    half4 color,
    float4 bounds,
    float radius,
    float softness
) {
    float2 uv = (position - bounds.xy) / max(bounds.zw, float2(0.0001));
    float2 center = float2(0.5, 0.5);
    float dist = distance(uv, center);
    float vignette = 1.0 - smoothstep(radius - max(softness, 0.0001), radius, dist);
    return half4(color.rgb * half(vignette), color.a);
}
```

```swift
Image("photo")
    .colorEffect(ShaderLibrary.vignette(
        .boundingRect,
        .float(0.75),  // radius
        .float(0.45)   // softness
    ))
```

### Color Replace

```metal
[[stitchable]] half4 colorReplace(
    float2 position,
    half4 color,
    half4 targetColor,
    half4 newColor,
    float tolerance
) {
    half3 straight = color.a > 0 ? color.rgb / color.a : half3(0);
    half3 target = targetColor.a > 0 ? targetColor.rgb / targetColor.a : half3(0);
    float dist = distance(float3(straight), float3(target));
    half blend = half(1.0 - smoothstep(0.0, max(tolerance, 0.0001), dist));
    return half4(mix(color.rgb, newColor.rgb * color.a, blend), color.a);
}
```

## Distortion Effects

### Wave

```metal
[[stitchable]] float2 wave(
    float2 position,
    float time,
    float amplitude,
    float frequency
) {
    float offset = sin(position.y * frequency + time) * amplitude;
    return float2(position.x + offset, position.y);
}
```

```swift
struct WaveView: View {
    @State private var startDate = Date()

    var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSince(startDate)

            Image("photo")
                .distortionEffect(
                    ShaderLibrary.wave(
                        .float(Float(time * 3)),
                        .float(10),   // amplitude
                        .float(0.05)  // frequency
                    ),
                    maxSampleOffset: CGSize(width: 20, height: 0)
                )
        }
    }
}
```

### Bulge/Pinch

```metal
[[stitchable]] float2 bulge(
    float2 position,
    float2 center,
    float radius,
    float strength
) {
    float2 offset = position - center;
    float dist = length(offset);

    if (radius > 0 && dist < radius) {
        float percent = dist / radius;
        float factor = 1.0 + clamp(strength, -1.0, 1.0) * pow(1.0 - percent, 2.0);
        return center + offset * factor;
    }

    return position;
}
```

```swift
Image("photo")
    .distortionEffect(
        ShaderLibrary.bulge(
            .float2(CGPoint(x: 150, y: 150)),
            .float(100),  // radius
            .float(0.5)   // strength (negative for pinch)
        ),
        maxSampleOffset: CGSize(width: 100, height: 100)
    )
```

### Swirl

```metal
[[stitchable]] float2 swirl(
    float2 position,
    float2 center,
    float radius,
    float angle
) {
    float2 offset = position - center;
    float dist = length(offset);

    if (dist < radius) {
        float percent = (radius - dist) / radius;
        float theta = percent * percent * angle;
        float s = sin(theta);
        float c = cos(theta);
        offset = float2(
            offset.x * c - offset.y * s,
            offset.x * s + offset.y * c
        );
    }

    return center + offset;
}
```

### Fisheye

```metal
[[stitchable]] float2 fisheye(
    float2 position,
    float4 bounds,
    float strength
) {
    float2 center = bounds.xy + bounds.zw / 2.0;
    float2 offset = position - center;
    float dist = length(offset) / max(length(bounds.zw / 2.0), 0.0001);

    float power = pow(max(dist, 0.0001), max(strength, 0.0001));
    float len = length(offset);
    float2 direction = len > 0 ? offset / len : float2(0);
    float2 result = center + direction * power * max(length(bounds.zw / 2.0), 0.0001);

    return result;
}
```

## Layer Effects

### Box Blur

```metal
[[stitchable]] half4 boxBlur(
    float2 position,
    SwiftUI::Layer layer,
    float radius
) {
    half4 sum = half4(0);
    int samples = 0;

    for (float y = -radius; y <= radius; y += 1.0) {
        for (float x = -radius; x <= radius; x += 1.0) {
            sum += layer.sample(position + float2(x, y));
            samples++;
        }
    }

    return sum / half(samples);
}
```

```swift
Image("photo")
    .layerEffect(
        ShaderLibrary.boxBlur(.float(5)),
        maxSampleOffset: CGSize(width: 10, height: 10)
    )
```

### Separable Gaussian Blur

```metal
[[stitchable]] half4 gaussianBlur(
    float2 position,
    SwiftUI::Layer layer,
    float radius,
    float2 axis
) {
    // Normalized 9-tap one-dimensional Gaussian weights
    const half weights[5] = { 0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216 };

    half4 result = layer.sample(position) * weights[0];

    for (int i = 1; i < 5; i++) {
        float offset = float(i) * radius / 4.0;
        result += layer.sample(position + axis * offset) * weights[i];
        result += layer.sample(position - axis * offset) * weights[i];
    }

    return result;
}
```

For the Gaussian recipe, apply two passes with axes `(1, 0)` and `(0, 1)` and a maxSampleOffset covering radius per pass. The original cross-shaped 17-sample combination was not normalized and brightened the image.

### Ripple

```metal
[[stitchable]] half4 ripple(
    float2 position,
    SwiftUI::Layer layer,
    float2 origin,
    float time,
    float amplitude,
    float frequency,
    float decay
) {
    float2 offset = position - origin;
    float dist = length(offset);

    // Wave calculation
    float wave = sin(dist * frequency - time * 10.0);
    float falloff = exp(-dist * decay) * exp(-time * 2.0);

    // Apply displacement
    float2 direction = dist > 0 ? normalize(offset) : float2(0, 0);
    float2 samplePos = position + direction * wave * amplitude * falloff;

    return layer.sample(samplePos);
}
```

```swift
struct RippleView: View {
    @State private var trigger = 0
    @State private var origin = CGPoint.zero

    var body: some View {
        Image("photo")
            .keyframeAnimator(
                initialValue: RippleData(),
                trigger: trigger
            ) { view, data in
                view.layerEffect(
                    ShaderLibrary.ripple(
                        .float2(origin),
                        .float(data.time),
                        .float(data.amplitude),
                        .float(0.1),   // frequency
                        .float(0.01)   // decay
                    ),
                    maxSampleOffset: CGSize(width: 100, height: 100)
                )
            } keyframes: { _ in
                KeyframeTrack(\.time) {
                    MoveKeyframe(0.0)
                    LinearKeyframe(1.0, duration: 1.0)
                }
                KeyframeTrack(\.amplitude) {
                    LinearKeyframe(30.0, duration: 0.2)
                    LinearKeyframe(0.0, duration: 0.8)
                }
            }
            .onTapGesture { location in
                origin = location
                trigger += 1
            }
    }

    struct RippleData {
        var time: Float = 0
        var amplitude: Float = 0
    }
}
```

### Chromatic Aberration

```metal
[[stitchable]] half4 chromaticAberration(
    float2 position,
    SwiftUI::Layer layer,
    float2 center,
    float strength
) {
    float2 dir = position - center;
    float dist = length(dir);
    float2 offset = dir * strength * 0.01;

    half r = layer.sample(position + offset).r;
    half g = layer.sample(position).g;
    half b = layer.sample(position - offset).b;
    half a = layer.sample(position).a;

    return half4(r, g, b, a);
}
```

### Pixelate

```metal
[[stitchable]] half4 pixelate(
    float2 position,
    SwiftUI::Layer layer,
    float pixelSize
) {
    pixelSize = max(pixelSize, 1.0);
    float2 pixelPos = floor(position / pixelSize) * pixelSize + pixelSize / 2.0;
    return layer.sample(pixelPos);
}
```

### Edge Detection

```metal
[[stitchable]] half4 edgeDetection(
    float2 position,
    SwiftUI::Layer layer
) {
    // Sobel kernels
    half gx = 0;
    half gy = 0;

    // Sample 3x3 neighborhood
    half tl = dot(layer.sample(position + float2(-1, -1)).rgb, half3(0.333));
    half t  = dot(layer.sample(position + float2( 0, -1)).rgb, half3(0.333));
    half tr = dot(layer.sample(position + float2( 1, -1)).rgb, half3(0.333));
    half l  = dot(layer.sample(position + float2(-1,  0)).rgb, half3(0.333));
    half r  = dot(layer.sample(position + float2( 1,  0)).rgb, half3(0.333));
    half bl = dot(layer.sample(position + float2(-1,  1)).rgb, half3(0.333));
    half b  = dot(layer.sample(position + float2( 0,  1)).rgb, half3(0.333));
    half br = dot(layer.sample(position + float2( 1,  1)).rgb, half3(0.333));

    // Sobel X
    gx = -tl - 2.0*l - bl + tr + 2.0*r + br;
    // Sobel Y
    gy = -tl - 2.0*t - tr + bl + 2.0*b + br;

    half edge = sqrt(gx*gx + gy*gy);
    return half4(edge, edge, edge, 1.0);
}
```

## Shape Fills

### Gradient Stripes

```metal
[[stitchable]] half4 stripes(
    float2 position,
    float spacing,
    float angle,
    half4 color1,
    half4 color2
) {
    float c = cos(angle);
    float s = sin(angle);
    float2 rotated = float2(
        position.x * c - position.y * s,
        position.x * s + position.y * c
    );

    float stripe = fract(rotated.x / max(spacing, 0.0001));
    return mix(color1, color2, half(step(0.5, stripe)));
}
```

```swift
Circle()
    .fill(ShaderLibrary.stripes(
        .float(20),
        .float(0.785),  // 45 degrees
        .color(.blue),
        .color(.white)
    ))
```

### Checkerboard

```metal
[[stitchable]] half4 checkerboard(
    float2 position,
    float size,
    half4 color1,
    half4 color2
) {
    float2 cell = floor(position / max(size, 0.0001));
    float checker = 2.0 * fract((cell.x + cell.y) / 2.0);
    return mix(color1, color2, half(checker));
}
```

### Radial Gradient

```metal
[[stitchable]] half4 radialGradient(
    float2 position,
    float4 bounds,
    half4 innerColor,
    half4 outerColor
) {
    float2 center = bounds.xy + bounds.zw / 2.0;
    float dist = distance(position, center) / length(center);
    return mix(innerColor, outerColor, half(clamp(dist, 0.0, 1.0)));
}
```

### Noise Pattern

```metal
float hash(float2 p) {
    return fract(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
}

[[stitchable]] half4 noisePattern(
    float2 position,
    float scale,
    half4 color
) {
    float n = hash(floor(position / max(scale, 0.0001)));
    return color * half(n);
}
```

### Animated Plasma

```metal
[[stitchable]] half4 plasma(
    float2 position,
    float4 bounds,
    float time
) {
    float2 uv = (position - bounds.xy) / max(bounds.zw, float2(0.0001));

    float v1 = sin(uv.x * 10.0 + time);
    float v2 = sin(10.0 * (uv.x * sin(time / 2.0) + uv.y * cos(time / 3.0)) + time);
    float v3 = sin(sqrt(100.0 * ((uv.x - 0.5) * (uv.x - 0.5) + (uv.y - 0.5) * (uv.y - 0.5))) + time);

    float v = v1 + v2 + v3;

    half3 color = half3(
        sin(v) * 0.5 + 0.5,
        sin(v + 2.094) * 0.5 + 0.5,
        sin(v + 4.188) * 0.5 + 0.5
    );

    return half4(color, 1.0);
}
```

```swift
struct PlasmaView: View {
    @State private var start = Date()

    var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSince(start)

            Rectangle()
                .fill(ShaderLibrary.plasma(
                    .boundingRect,
                    .float(Float(time))
                ))
        }
    }
}
```

## Text Effects

### Rainbow Text

```metal
[[stitchable]] half4 rainbow(
    float2 position,
    half4 color,
    float4 bounds,
    float time
) {
    float hue = fract((position.x - bounds.x) / max(bounds.z, 0.0001) + time * 0.1);

    // HSV to RGB
    half3 rgb = clamp(
        abs(fmod(hue * 6.0 + half3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0,
        0.0, 1.0
    );

    return half4(rgb * color.a, color.a);
}
```

```swift
struct RainbowText: View {
    @State private var start = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            Text("Rainbow")
                .font(.largeTitle)
                .colorEffect(ShaderLibrary.rainbow(
                    .boundingRect,
                    .float(reduceMotion ? 0 : context.date.timeIntervalSince(start))
                ))
        }
    }
}
```

### Glitch Text

```metal
[[stitchable]] half4 glitch(
    float2 position,
    SwiftUI::Layer layer,
    float time,
    float intensity
) {
    // Random horizontal offset per scanline
    float lineNoise = fract(sin(floor(position.y / 3.0) * 43758.5453 + time * 100.0));
    float offset = (lineNoise - 0.5) * intensity * step(0.9, lineNoise);

    half4 color = layer.sample(position + float2(offset, 0));

    // RGB split
    if (lineNoise > 0.95) {
        color.r = layer.sample(position + float2(offset + 5.0, 0)).r;
        color.b = layer.sample(position + float2(offset - 5.0, 0)).b;
    }

    return color;
}
```

## Recipe limits

Use persistent elapsed time from TimelineView rather than a huge absolute timestamp converted to Float (which loses small time increments). Stop or simplify decorative effects for Reduce Motion and when the scene is inactive. Guard blur radii before loops and prefer built-in blur for an ordinary blur requirement. Chromatic/glitch channel shifts and edge detection deliberately change edge alpha/appearance; test transparent content and use a suitable compositing strategy rather than assuming photographic examples are safe for text masks.
