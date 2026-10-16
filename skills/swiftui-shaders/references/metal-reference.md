# Metal Shading Language Reference

Essential Metal knowledge for SwiftUI shaders.

## File Setup

```metal
// Required headers
#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;
```

## Function Attributes

### [[stitchable]]

Required for all SwiftUI shaders. Enables dynamic linking:

```metal
[[stitchable]] half4 myShader(float2 position, half4 color) {
    return color;
}
```

## Data Types

### Scalar Types

| Type | Size | Range | Use |
|------|------|-------|-----|
| `half` | 16-bit | ±65504 | Colors, fast math |
| `float` | 32-bit | ±3.4e38 | Positions, precision |
| `int` | 32-bit | ±2.1e9 | Counters, indices |
| `uint` | 32-bit | 0-4.2e9 | Unsigned integers |
| `bool` | — | true/false | Conditions |

### Vector Types

```metal
// 2D vectors
float2 position = float2(100.0, 200.0);
half2 uv = half2(0.5, 0.5);

// 3D vectors
float3 rgb = float3(1.0, 0.5, 0.0);
half3 normal = half3(0.0, 1.0, 0.0);

// 4D vectors (RGBA colors, bounds)
float4 bounds = float4(0.0, 0.0, 100.0, 100.0);
half4 color = half4(1.0, 0.0, 0.0, 1.0);  // Red
```

### Constructing Vectors

```metal
// From scalars
float2 a = float2(1.0, 2.0);
float3 b = float3(1.0, 2.0, 3.0);
float4 c = float4(1.0, 2.0, 3.0, 4.0);

// From smaller vectors
float4 d = float4(a, 3.0, 4.0);       // Combine float2 + scalars
float4 e = float4(b, 1.0);            // Combine float3 + scalar
float4 f = float4(a, a);              // Combine two float2

// From single value (broadcast)
float4 g = float4(0.5);               // (0.5, 0.5, 0.5, 0.5)
```

### Swizzling

Access and rearrange vector components:

```metal
half4 color = half4(1.0, 0.5, 0.25, 1.0);

// Access components
half r = color.r;        // 1.0
half g = color.g;        // 0.5
half4 rgb = color.rgb;   // Error: rgb is half3, not half4
half3 rgb = color.rgb;   // (1.0, 0.5, 0.25)

// Alternative naming
color.x;  color.y;  color.z;  color.w;   // Position style
color.r;  color.g;  color.b;  color.a;   // Color style

// Swizzle and rearrange
half3 bgr = color.bgr;   // Reverse RGB
half2 rr = color.rr;     // Duplicate red
half4 rrra = color.rrra; // Red channel to all RGB

// Write to swizzle
color.rgb = half3(0.0);  // Set RGB, keep alpha
color.rg = color.gr;     // Swap red and green
```

## Operators

### Arithmetic

```metal
float2 a = float2(1.0, 2.0);
float2 b = float2(3.0, 4.0);

float2 sum = a + b;      // (4.0, 6.0)
float2 diff = a - b;     // (-2.0, -2.0)
float2 prod = a * b;     // (3.0, 8.0) - component-wise
float2 quot = a / b;     // (0.33, 0.5)

// Scalar operations
float2 scaled = a * 2.0; // (2.0, 4.0)
```

### Comparison

```metal
// Returns component-wise bool vector
bool2 cmp = a < b;       // (true, true)

// Use any() or all() for conditions
if (all(a < b)) { }      // True if all components less
if (any(a > b)) { }      // True if any component greater
```

## Math Functions

### Basic

```metal
abs(x)          // Absolute value
sign(x)         // -1, 0, or 1
floor(x)        // Round down
ceil(x)         // Round up
round(x)        // Round to nearest
fract(x)        // Fractional part (x - floor(x))
trunc(x)        // Integer part

min(a, b)       // Minimum
max(a, b)       // Maximum
clamp(x, lo, hi) // Constrain to range

mix(a, b, t)    // Linear interpolation: a * (1-t) + b * t
step(edge, x)   // 0 if x < edge, else 1
smoothstep(e0, e1, x)  // Smooth transition from 0 to 1
```

### Trigonometric

```metal
sin(x)          // Sine (radians)
cos(x)          // Cosine
tan(x)          // Tangent
asin(x)         // Arc sine
acos(x)         // Arc cosine
atan(x)         // Arc tangent
atan2(y, x)     // Arc tangent of y/x

// Constants
M_PI_F          // π (float)
M_PI_H          // π (half)
```

### Exponential

```metal
pow(x, y)       // x^y
exp(x)          // e^x
exp2(x)         // 2^x
log(x)          // Natural log
log2(x)         // Base-2 log
log10(x)        // Base-10 log
sqrt(x)         // Square root
rsqrt(x)        // 1 / sqrt(x) - faster
```

### Vector Math

```metal
float2 a = float2(3.0, 4.0);
float2 b = float2(1.0, 0.0);

length(a)       // Magnitude: 5.0
distance(a, b)  // Distance between points
normalize(a)    // Unit vector: (0.6, 0.8)
dot(a, b)       // Dot product: 3.0
cross(a3, b3)   // Cross product (float3 only)
reflect(i, n)   // Reflection vector
refract(i, n, eta) // Refraction vector
```

## Color Operations

### Common Patterns

```metal
// Grayscale (luminance)
float gray = dot(color.rgb, half3(0.299, 0.587, 0.114));

// Brighten
half4 brighter = half4(color.rgb * 1.5h, color.a);

// Darken
half4 darker = half4(color.rgb * 0.5h, color.a);

// Contrast
half3 straight = color.a > 0 ? color.rgb / color.a : half3(0);
half4 contrasted = half4(((straight - 0.5h) * contrast + 0.5h) * color.a, color.a);

// Saturation
half gray = dot(color.rgb, half3(0.299, 0.587, 0.114));
half3 saturated = mix(half3(gray), color.rgb, saturation);

// Invert
half4 inverted = half4(half3(color.a) - color.rgb, color.a);
```

### Blending

```metal
// Normal blend
half4 result = overlay + base * (1.0h - overlay.a); // Premultiplied source-over

// Multiply
half3 multiplied = base.rgb * overlay.rgb;

// Screen
half3 screened = 1.0 - (1.0 - base.rgb) * (1.0 - overlay.rgb);

// Overlay
half3 overlayed = select(
    2.0 * base.rgb * overlay.rgb,
    1.0 - 2.0 * (1.0 - base.rgb) * (1.0 - overlay.rgb),
    base.rgb > 0.5
);
```

## Noise and Randomness

### Simple Hash

```metal
float hash(float2 p) {
    return fract(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
}
```

### Value Noise

```metal
float valueNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);

    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));

    float2 u = f * f * (3.0 - 2.0 * f);

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}
```

## Texture Sampling

```metal
[[stitchable]] half4 textured(
    float2 position,
    half4 color,
    texture2d<half> tex,
    float4 bounds
) {
    // Define sampler
    constexpr sampler s(
        address::clamp_to_edge,
        filter::linear
    );

    // Convert to UV coordinates (0-1)
    float2 uv = (position - bounds.xy) / max(bounds.zw, float2(0.0001));

    // Sample texture
    half4 texColor = tex.sample(s, uv);

    return texColor;
}
```

### Sampler Configuration

```metal
// Address modes
address::clamp_to_edge     // Extend edge pixels
address::clamp_to_zero     // Zero outside bounds
address::repeat            // Tile/wrap
address::mirrored_repeat   // Mirror at edges

// Filter modes
filter::nearest    // Pixelated/blocky
filter::linear     // Smooth interpolation

// Example
constexpr sampler mySampler(
    address::repeat,
    filter::linear,
    mip_filter::linear
);
```

## Control Flow

### Conditionals

```metal
// If-else (avoid in hot paths if possible)
if (position.x > bounds.z / 2.0) {
    color = half4(1.0, 0.0, 0.0, 1.0);
} else {
    color = half4(0.0, 1.0, 0.0, 1.0);
}

// Prefer branchless where possible
half4 color = mix(green, red, step(bounds.z / 2.0, position.x));

// select() for component-wise conditional
half4 result = select(valueIfFalse, valueIfTrue, condition);
```

### Loops

```metal
// For loop
half4 sum = half4(0);
for (int i = 0; i < 10; i++) {
    sum += layer.sample(position + float2(i, 0));
}

// Unroll hint for performance
#pragma unroll
for (int i = 0; i < 4; i++) {
    // Compiler unrolls this loop
}
```

## Common Patterns

### Normalized Coordinates

```metal
// Convert position to 0-1 range
float2 uv = (position - bounds.xy) / max(bounds.zw, float2(0.0001));

// Center coordinates (-0.5 to 0.5)
float2 centered = uv - 0.5;

// Aspect-correct coordinates
float aspect = bounds.z / bounds.w;
float2 aspectCorrected = float2(centered.x * aspect, centered.y);
```

### Distance Fields

```metal
// Circle
float circleSDF(float2 p, float2 center, float radius) {
    return length(p - center) - radius;
}

// Rectangle
float rectSDF(float2 p, float2 center, float2 size) {
    float2 d = abs(p - center) - size / 2.0;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// Render SDF
half4 color = half4(1.0 - smoothstep(0.0, 1.0, sdf));
```

### Rotation

```metal
float2 rotate(float2 p, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return float2(
        p.x * c - p.y * s,
        p.x * s + p.y * c
    );
}
```

### Polar Coordinates

```metal
// Cartesian to polar
float2 toPolar(float2 p) {
    return float2(length(p), atan2(p.y, p.x));
}

// Polar to cartesian
float2 toCartesian(float2 polar) {
    return float2(
        polar.x * cos(polar.y),
        polar.x * sin(polar.y)
    );
}
```

## Performance Tips

1. **Use `half` when possible** — Faster than `float` for colors
2. **Avoid branching** — Use `mix`, `step`, `select` instead
3. **Minimize texture samples** — Each sample is expensive
4. **Use `rsqrt` over `1.0/sqrt`** — Hardware optimized
5. **Precompute constants** — Use `constexpr` for compile-time values
6. **Unroll small loops** — Use `#pragma unroll` hint
