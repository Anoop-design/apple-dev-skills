# SwiftUI Shader API Reference

Complete API reference for SwiftUI shaders.

## Shader

A reference to a Metal shader function with bound arguments.

```swift
struct Shader: Equatable, Sendable
```

### Creating Shaders

Use `ShaderLibrary` to create shaders:

```swift
// No arguments
let shader = ShaderLibrary.myShader()

// With arguments
let shader = ShaderLibrary.myShader(
    .float(0.5),
    .color(.red)
)
```

### Properties

```swift
// The shader function
var function: ShaderFunction { get }

// Bound arguments
var arguments: [Shader.Argument] { get }
```

### Signature validation

On iOS 18+, use `try await shader.compile(as: .colorEffect)` (or `.distortionEffect`, `.layerEffect`, `.shapeStyle`) to prepare and validate a shader for the intended use. `Shader.UsageType` is a struct with these static values, not an enum with a `.fill` case. There is no public `dpiScale` property in the inspected Shader declaration. Build the Metal source and render it in the app too: dynamic function names and arguments are not checked against the Metal library by Swift typechecking.

## ShaderLibrary

Access Metal shader functions by name.

```swift
struct ShaderLibrary
```

### Default Library

```swift
// Access main bundle shaders
ShaderLibrary.shaderName(arguments...)

// Example
ShaderLibrary.colorInvert()
ShaderLibrary.wave(.float(time))
```

### Custom Library

```swift
// Load from bundle
let library = ShaderLibrary.bundle(myBundle)
library.myShader()

// Load from URL
let library = ShaderLibrary(url: metalLibURL)
library.myShader()
```

## Shader.Argument

Uniform values passed to shader functions.

```swift
struct Argument: Equatable, Sendable
```

### Float Arguments

```swift
// Single float
static func float(_ value: Float) -> Shader.Argument

// Example
ShaderLibrary.wave(.float(0.5))

// Metal parameter
[[stitchable]] half4 wave(float2 pos, half4 color, float value)
```

### Float2 Arguments

```swift
// From CGFloat pair
static func float2(_ x: CGFloat, _ y: CGFloat) -> Shader.Argument

// From CGPoint
static func float2(_ point: CGPoint) -> Shader.Argument

// From CGSize
static func float2(_ size: CGSize) -> Shader.Argument

// From SIMD2: pass its scalar components
Shader.Argument.float2(vector.x, vector.y)

// Example
ShaderLibrary.ripple(.float2(touchPoint))

// Metal parameter
[[stitchable]] half4 ripple(float2 pos, half4 color, float2 origin)
```

### Float3 Arguments

```swift
// From CGFloat triple
static func float3(_ x: CGFloat, _ y: CGFloat, _ z: CGFloat) -> Shader.Argument

// From SIMD3: pass its scalar components
Shader.Argument.float3(vector.x, vector.y, vector.z)

// Example
ShaderLibrary.lighting(.float3(lightDir.x, lightDir.y, lightDir.z))

// Metal parameter
[[stitchable]] half4 lighting(float2 pos, half4 color, float3 light)
```

### Float4 Arguments

```swift
// From CGFloat quad
static func float4(_ x: CGFloat, _ y: CGFloat,
                   _ z: CGFloat, _ w: CGFloat) -> Shader.Argument

// From CGRect: pass components explicitly
Shader.Argument.float4(rect.minX, rect.minY, rect.width, rect.height)

// From SIMD4: pass its scalar components
Shader.Argument.float4(vector.x, vector.y, vector.z, vector.w)

// Example
ShaderLibrary.crop(.float4(cropRect.minX, cropRect.minY, cropRect.width, cropRect.height))

// Metal parameter
[[stitchable]] half4 crop(float2 pos, half4 color, float4 rect)
// rect.x, rect.y = origin; rect.z, rect.w = size
```

### Color Arguments

```swift
// From SwiftUI Color
static func color(_ color: Color) -> Shader.Argument

// Example
ShaderLibrary.tint(.color(.red))

// Metal parameter (converts to half4)
[[stitchable]] half4 tint(float2 pos, half4 color, half4 tint)
```

### Image Arguments

```swift
// From SwiftUI Image
static func image(_ image: Image) -> Shader.Argument

// Example
ShaderLibrary.blend(.image(Image("texture")))

// Metal parameter
[[stitchable]] half4 blend(float2 pos, half4 color,
                           texture2d<half> tex)

// Sampling in Metal
half4 sample = tex.sample(sampler, uv);
```

### Bounding Rect Argument

```swift
// Automatic bounds of view/shape
static var boundingRect: Shader.Argument

// Example
ShaderLibrary.vignette(.boundingRect)

// Metal parameter (float4: x, y, width, height)
[[stitchable]] half4 vignette(float2 pos, half4 color, float4 bounds)
// bounds.xy = origin (usually 0,0)
// bounds.zw = size (width, height)
```

### Float Array Arguments

```swift
// Array of floats
static func floatArray(_ values: [Float]) -> Shader.Argument

// Example
ShaderLibrary.kernel(.floatArray([1, 2, 1, 2, 4, 2, 1, 2, 1]))

// Metal parameter (device pointer + count)
[[stitchable]] half4 kernel(float2 pos, SwiftUI::Layer layer,
                            device const float *values, int count)
```

### Data Arguments

```swift
// Raw data buffer
static func data(_ data: Data) -> Shader.Argument

// Metal parameter
[[stitchable]] half4 shader(float2 pos, half4 color,
                            device const void *data, int length)
```

## View Modifiers

### colorEffect(_:isEnabled:)

Apply a color transformation to each pixel.

```swift
func colorEffect(
    _ shader: Shader,
    isEnabled: Bool = true
) -> some View
```

**Metal signature:**
```metal
[[stitchable]] half4 name(float2 position, half4 color, args...)
```

**Example:**
```swift
Image("photo")
    .colorEffect(ShaderLibrary.grayscale())
```

### distortionEffect(_:maxSampleOffset:isEnabled:)

Apply geometric distortion.

```swift
func distortionEffect(
    _ shader: Shader,
    maxSampleOffset: CGSize,
    isEnabled: Bool = true
) -> some View
```

**Metal signature:**
```metal
[[stitchable]] float2 name(float2 position, args...)
```

**Example:**
```swift
Image("photo")
    .distortionEffect(
        ShaderLibrary.wave(.float(time)),
        maxSampleOffset: CGSize(width: 50, height: 0)
    )
```

### layerEffect(_:maxSampleOffset:isEnabled:)

Apply effect with access to neighboring pixels.

```swift
func layerEffect(
    _ shader: Shader,
    maxSampleOffset: CGSize,
    isEnabled: Bool = true
) -> some View
```

**Metal signature:**
```metal
[[stitchable]] half4 name(float2 position, SwiftUI::Layer layer, args...)
```

**Example:**
```swift
Image("photo")
    .layerEffect(
        ShaderLibrary.blur(.float(10)),
        maxSampleOffset: CGSize(width: 20, height: 20)
    )
```

## Shape Fills

Shaders as `ShapeStyle`:

```swift
// Fill shape
Circle()
    .fill(ShaderLibrary.gradient(.boundingRect))

// Stroke shape
Rectangle()
    .stroke(ShaderLibrary.animated(.float(time)), lineWidth: 5)

// Text foreground
Text("Hello")
    .colorEffect(ShaderLibrary.rainbow(.boundingRect))
```

**Metal signature (no color parameter):**
```metal
[[stitchable]] half4 name(float2 position, args...)
```

## SwiftUI::Layer

Metal type for sampling view content in layer effects.

### sample()

```metal
// Sample at position
half4 color = layer.sample(float2 position);

// Sample with offset from current position
half4 nearby = layer.sample(position + float2(5, 0));
```

**Important:** Stay within `maxSampleOffset` bounds!

### Example Usage

```metal
[[stitchable]] half4 boxBlur(float2 position, SwiftUI::Layer layer,
                              float radius) {
    half4 sum = half4(0);
    int samples = 0;

    for (float y = -radius; y <= radius; y++) {
        for (float x = -radius; x <= radius; x++) {
            sum += layer.sample(position + float2(x, y));
            samples++;
        }
    }

    return sum / float(samples);
}
```

## Texture Sampling

For image arguments:

```metal
[[stitchable]] half4 textured(float2 position, half4 color,
                              texture2d<half> tex,
                              float4 bounds) {
    // Create sampler
    constexpr sampler s(address::clamp_to_edge, filter::linear);

    // Convert position to UV (0-1)
    float2 uv = (position - bounds.xy) / max(bounds.zw, float2(0.0001));

    // Sample texture
    half4 texColor = tex.sample(s, uv);

    return texColor * color;
}
```

### Sampler Options

```metal
// Address modes
address::clamp_to_edge    // Clamp to edge color
address::repeat           // Tile the texture
address::mirrored_repeat  // Mirror at edges

// Filter modes
filter::nearest   // Pixelated
filter::linear    // Smooth interpolation
```

## ShaderFunction

Reference to a specific function in a shader library.

```swift
struct ShaderFunction: Equatable, Sendable {
    var library: ShaderLibrary
    var name: String
}
```

## Contracts and bounds

Checked against Xcode 27.0 on 2026-10-16. Numeric float/float2/float3/float4 scalar overloads are generic over BinaryFloatingPoint; signatures above illustrate accepted values rather than reproducing the full declaration. ShaderLibrary(url:) is nonfailable; creating a library value does not prove the shader exists or its arguments match.

Coordinates and maxSampleOffset are in local user-space units. Bound radius/amplitude/pixel size to nonnegative sensible values and include the full maximum sampling excursion. A missing or underestimated offset can crop or corrupt an effect. Test representable-backed content, transparent edges and nonzero bounds origins.

Primary sources: [Shader arguments](https://developer.apple.com/documentation/swiftui/shader/argument), [compile(as:)](https://developer.apple.com/documentation/swiftui/shader/compile(as:)). Float arrays and data bind a device pointer plus an `int` count/byte length; `.color` supplies premultiplied color.
