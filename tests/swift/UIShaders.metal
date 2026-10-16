// Representative recipes from swiftui-shaders. Metal Toolchain required.
// Reviewed 2026-10-16; compilation unavailable on the review host.
#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Shaders.metal
[[stitchable]] half4 grayscale(float2 position, half4 color) {
    half gray = dot(color.rgb, half3(0.299, 0.587, 0.114));
    return half4(gray, gray, gray, color.a);
}


[[stitchable]] half4 sepia(float2 position, half4 color, float intensity) {
    half3 sepia = half3(
        dot(color.rgb, half3(0.393, 0.769, 0.189)),
        dot(color.rgb, half3(0.349, 0.686, 0.168)),
        dot(color.rgb, half3(0.272, 0.534, 0.131))
    );
    return half4(mix(color.rgb, sepia, half(intensity)), color.a);
}


[[stitchable]] half4 invert(float2 position, half4 color) {
    return half4(half3(color.a) - color.rgb, color.a);
}


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


[[stitchable]] float2 wave(
    float2 position,
    float time,
    float amplitude,
    float frequency
) {
    float offset = sin(position.y * frequency + time) * amplitude;
    return float2(position.x + offset, position.y);
}


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


[[stitchable]] half4 pixelate(
    float2 position,
    SwiftUI::Layer layer,
    float pixelSize
) {
    pixelSize = max(pixelSize, 1.0);
    float2 pixelPos = floor(position / pixelSize) * pixelSize + pixelSize / 2.0;
    return layer.sample(pixelPos);
}


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
