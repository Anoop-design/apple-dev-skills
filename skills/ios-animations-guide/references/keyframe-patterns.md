# Keyframe Animation Patterns

Recipes for iOS 17+ keyframe and phase animation. Fragments use app-owned state/content; make them accessible and respect Reduce Motion before shipping.

## Keyframe Types Reference

| Type | Curve | Use Case |
|------|-------|----------|
| `LinearKeyframe` | Constant speed | Holds, mechanical motion |
| `CubicKeyframe` | Smooth bezier | Organic motion, most common |
| `SpringKeyframe` | Physics spring | Bouncy effects, settling |
| `MoveKeyframe` | Instant jump | Discontinuous changes |

```swift
KeyframeTrack(\.value) {
    LinearKeyframe(1.0, duration: 0.5)      // Hold at 1.0 for 0.5s
    CubicKeyframe(2.0, duration: 0.3)       // Smooth curve to 2.0
    SpringKeyframe(1.0, spring: .bouncy)    // Bounce back to 1.0
    MoveKeyframe(0.5)                        // Instant jump to 0.5
}
```

---

## Basic Patterns

### Like/Heart Animation

```swift
struct HeartValues {
    var scale: Double = 1.0
    var rotation: Angle = .zero
}

Image(systemName: "heart.fill")
    .foregroundStyle(.red)
    .keyframeAnimator(
        initialValue: HeartValues(),
        trigger: likeCount
    ) { content, value in
        content
            .scaleEffect(value.scale)
            .rotationEffect(value.rotation)
    } keyframes: { _ in
        KeyframeTrack(\.scale) {
            SpringKeyframe(1.4, duration: 0.15, spring: .bouncy)
            SpringKeyframe(0.9, duration: 0.1, spring: .bouncy)
            SpringKeyframe(1.0, duration: 0.2, spring: .smooth)
        }
        KeyframeTrack(\.rotation) {
            CubicKeyframe(.degrees(-10), duration: 0.1)
            CubicKeyframe(.degrees(10), duration: 0.1)
            CubicKeyframe(.zero, duration: 0.15)
        }
    }
```

---

### Shake/Error Animation

```swift
struct ShakeValues {
    var offsetX: Double = 0
}

TextField("Email", text: $email)
    .keyframeAnimator(
        initialValue: ShakeValues(),
        trigger: errorCount
    ) { content, value in
        content.offset(x: value.offsetX)
    } keyframes: { _ in
        KeyframeTrack(\.offsetX) {
            CubicKeyframe(10, duration: 0.08)
            CubicKeyframe(-10, duration: 0.08)
            CubicKeyframe(8, duration: 0.08)
            CubicKeyframe(-8, duration: 0.08)
            CubicKeyframe(5, duration: 0.08)
            CubicKeyframe(-5, duration: 0.08)
            CubicKeyframe(0, duration: 0.1)
        }
    }
```

---

### Success Checkmark

```swift
struct SuccessValues {
    var scale: Double = 0
    var opacity: Double = 0
    var rotation: Angle = .degrees(-45)
}

Image(systemName: "checkmark.circle.fill")
    .foregroundStyle(.green)
    .keyframeAnimator(
        initialValue: SuccessValues(),
        trigger: showSuccess
    ) { content, value in
        content
            .scaleEffect(value.scale)
            .opacity(value.opacity)
            .rotationEffect(value.rotation)
    } keyframes: { _ in
        KeyframeTrack(\.scale) {
            LinearKeyframe(0, duration: 0)
            SpringKeyframe(1.3, duration: 0.3, spring: .bouncy)
            SpringKeyframe(1.0, duration: 0.2, spring: .smooth)
        }
        KeyframeTrack(\.opacity) {
            LinearKeyframe(0, duration: 0)
            CubicKeyframe(1, duration: 0.15)
        }
        KeyframeTrack(\.rotation) {
            LinearKeyframe(.degrees(-45), duration: 0)
            SpringKeyframe(.zero, duration: 0.4, spring: .bouncy)
        }
    }
```

---

### Bounce In

```swift
struct BounceValues {
    var scale: Double = 0.3
    var opacity: Double = 0
}

ContentView()
    .keyframeAnimator(
        initialValue: BounceValues(),
        trigger: showContent
    ) { content, value in
        content
            .scaleEffect(value.scale)
            .opacity(value.opacity)
    } keyframes: { _ in
        KeyframeTrack(\.scale) {
            SpringKeyframe(1.1, duration: 0.3, spring: .bouncy)
            SpringKeyframe(0.95, duration: 0.1, spring: .bouncy)
            SpringKeyframe(1.0, duration: 0.15, spring: .smooth)
        }
        KeyframeTrack(\.opacity) {
            LinearKeyframe(0, duration: 0)
            CubicKeyframe(1, duration: 0.2)
        }
    }
```

---

### Attention Pulse

```swift
struct PulseValues {
    var scale: Double = 1.0
    var shadowRadius: Double = 0
}

Button("Action") { }
    .keyframeAnimator(
        initialValue: PulseValues(),
        trigger: pulseCount
    ) { content, value in
        content
            .scaleEffect(value.scale)
            .shadow(color: .blue.opacity(0.5), radius: value.shadowRadius)
    } keyframes: { _ in
        KeyframeTrack(\.scale) {
            CubicKeyframe(1.05, duration: 0.2)
            CubicKeyframe(1.0, duration: 0.2)
            CubicKeyframe(1.05, duration: 0.2)
            CubicKeyframe(1.0, duration: 0.2)
        }
        KeyframeTrack(\.shadowRadius) {
            CubicKeyframe(8, duration: 0.2)
            CubicKeyframe(0, duration: 0.2)
            CubicKeyframe(8, duration: 0.2)
            CubicKeyframe(0, duration: 0.2)
        }
    }
```

---

## Advanced Patterns

### Celebration Emoji

```swift
struct CelebrationValues {
    var scale: Double = 1.0
    var verticalStretch: Double = 1.0
    var yOffset: Double = 0
    var rotation: Angle = .zero
}

Text("🎉")
    .font(.system(size: 80))
    .keyframeAnimator(
        initialValue: CelebrationValues(),
        trigger: celebrate
    ) { content, value in
        content
            .scaleEffect(value.scale)
            .scaleEffect(y: value.verticalStretch)
            .offset(y: value.yOffset)
            .rotationEffect(value.rotation)
    } keyframes: { _ in
        // Scale track
        KeyframeTrack(\.scale) {
            LinearKeyframe(1.0, duration: 0.1)
            SpringKeyframe(1.5, duration: 0.3, spring: .bouncy)
            SpringKeyframe(1.0, duration: 0.4, spring: .smooth)
        }

        // Squash/stretch
        KeyframeTrack(\.verticalStretch) {
            CubicKeyframe(0.7, duration: 0.1)   // Anticipation squash
            CubicKeyframe(1.4, duration: 0.15)  // Jump stretch
            CubicKeyframe(0.9, duration: 0.1)   // Land squash
            CubicKeyframe(1.0, duration: 0.2)   // Settle
        }

        // Jump up
        KeyframeTrack(\.yOffset) {
            LinearKeyframe(0, duration: 0.1)
            SpringKeyframe(-50, duration: 0.25, spring: .bouncy)
            SpringKeyframe(0, duration: 0.4, spring: .smooth)
        }

        // Wiggle
        KeyframeTrack(\.rotation) {
            LinearKeyframe(.zero, duration: 0.2)
            CubicKeyframe(.degrees(15), duration: 0.1)
            CubicKeyframe(.degrees(-15), duration: 0.1)
            CubicKeyframe(.degrees(10), duration: 0.08)
            CubicKeyframe(.degrees(-10), duration: 0.08)
            CubicKeyframe(.zero, duration: 0.15)
        }
    }
```

---

### Loading Dots

```swift
struct DotValues {
    var dot1Y: Double = 0
    var dot2Y: Double = 0
    var dot3Y: Double = 0
}

HStack(spacing: 8) {
    ForEach(0..<3) { index in
        Circle()
            .frame(width: 12, height: 12)
    }
}
.keyframeAnimator(initialValue: DotValues()) { content, value in
    HStack(spacing: 8) {
        Circle().frame(width: 12, height: 12).offset(y: value.dot1Y)
        Circle().frame(width: 12, height: 12).offset(y: value.dot2Y)
        Circle().frame(width: 12, height: 12).offset(y: value.dot3Y)
    }
} keyframes: { _ in
    KeyframeTrack(\.dot1Y) {
        SpringKeyframe(-15, duration: 0.3, spring: .bouncy)
        SpringKeyframe(0, duration: 0.3, spring: .bouncy)
        LinearKeyframe(0, duration: 0.6)
    }
    KeyframeTrack(\.dot2Y) {
        LinearKeyframe(0, duration: 0.2)
        SpringKeyframe(-15, duration: 0.3, spring: .bouncy)
        SpringKeyframe(0, duration: 0.3, spring: .bouncy)
        LinearKeyframe(0, duration: 0.4)
    }
    KeyframeTrack(\.dot3Y) {
        LinearKeyframe(0, duration: 0.4)
        SpringKeyframe(-15, duration: 0.3, spring: .bouncy)
        SpringKeyframe(0, duration: 0.3, spring: .bouncy)
        LinearKeyframe(0, duration: 0.2)
    }
}
```

---

### Card Flip

```swift
struct FlipValues {
    var rotationY: Double = 0
    var scale: Double = 1.0
}

Card()
    .keyframeAnimator(
        initialValue: FlipValues(),
        trigger: isFlipped
    ) { content, value in
        content
            .rotation3DEffect(
                .degrees(value.rotationY),
                axis: (x: 0, y: 1, z: 0)
            )
            .scaleEffect(value.scale)
    } keyframes: { _ in
        KeyframeTrack(\.rotationY) {
            CubicKeyframe(90, duration: 0.25)
            CubicKeyframe(180, duration: 0.25)
        }
        KeyframeTrack(\.scale) {
            CubicKeyframe(0.9, duration: 0.25)
            CubicKeyframe(1.0, duration: 0.25)
        }
    }
```

---

## Phase Animator Patterns

### Button Press Feedback

```swift
enum PressPhase: CaseIterable {
    case idle, pressed, released

    var scale: Double {
        switch self {
        case .idle: 1.0
        case .pressed: 0.95
        case .released: 1.02
        }
    }
}

Button("Tap Me") { tapCount += 1 }
    .phaseAnimator(PressPhase.allCases, trigger: tapCount) { content, phase in
        content.scaleEffect(phase.scale)
    } animation: { phase in
        switch phase {
        case .idle: .spring(duration: 0.15)
        case .pressed: .easeIn(duration: 0.08)
        case .released: .spring(duration: 0.2, bounce: 0.3)
        }
    }
```

---

### Attention Bell

```swift
enum BellPhase: CaseIterable {
    case rest, left, right, left2, rest2

    var rotation: Double {
        switch self {
        case .rest, .rest2: 0
        case .left, .left2: -15
        case .right: 15
        }
    }
}

Image(systemName: "bell.fill")
    .phaseAnimator(BellPhase.allCases, trigger: notificationCount) { content, phase in
        content.rotationEffect(.degrees(phase.rotation))
    } animation: { phase in
        .spring(duration: 0.12, bounce: 0.5)
    }
```

---

### Pulse Ring

```swift
enum RingPhase: CaseIterable {
    case small, large

    var scale: Double {
        switch self {
        case .small: 1.0
        case .large: 1.8
        }
    }

    var opacity: Double {
        switch self {
        case .small: 0.8
        case .large: 0
        }
    }
}

Circle()
    .stroke(lineWidth: 2)
    .phaseAnimator(RingPhase.allCases) { content, phase in
        content
            .scaleEffect(phase.scale)
            .opacity(phase.opacity)
    } animation: { _ in
        .easeOut(duration: 1.0)
    }
```

---

### Step Progress

```swift
enum ProgressPhase: Int, CaseIterable {
    case step1 = 1, step2, step3, complete

    var icon: String {
        switch self {
        case .step1: "1.circle.fill"
        case .step2: "2.circle.fill"
        case .step3: "3.circle.fill"
        case .complete: "checkmark.circle.fill"
        }
    }

    var color: Color {
        self == .complete ? .green : .blue
    }
}

PhaseAnimator(ProgressPhase.allCases, trigger: progress) { phase in
        Image(systemName: phase.icon)
            .foregroundStyle(phase.color)
            .scaleEffect(phase == currentPhase ? 1.2 : 1.0)
    } animation: { _ in
        .spring(duration: 0.3, bounce: 0.2)
    }
```

---

## KeyframeTimeline for Scroll-Driven

```swift
struct ScrollAnimationValues {
    var scale: Double = 1.0
    var opacity: Double = 1.0
    var blur: Double = 0
}

let timeline = KeyframeTimeline(initialValue: ScrollAnimationValues()) {
    KeyframeTrack(\.scale) {
        CubicKeyframe(1.0, duration: 0.5)
        CubicKeyframe(0.8, duration: 0.5)
    }
    KeyframeTrack(\.opacity) {
        CubicKeyframe(1.0, duration: 0.3)
        CubicKeyframe(0.3, duration: 0.7)
    }
    KeyframeTrack(\.blur) {
        CubicKeyframe(0, duration: 0.4)
        CubicKeyframe(5, duration: 0.6)
    }
}

// Use with scroll position
let progress = maxOffset > 0 ? min(1, max(0, Double(scrollOffset / maxOffset))) : 0
let values = timeline.value(progress: progress)

ContentView()
    .scaleEffect(values.scale)
    .opacity(values.opacity)
    .blur(radius: values.blur)
```

---

## Timing Cheat Sheet

| Effect | Total Duration | Keyframe Count |
|--------|----------------|----------------|
| Quick feedback | 0.2-0.3s | 2-3 |
| Bounce in | 0.4-0.5s | 3-4 |
| Shake error | 0.5-0.6s | 6-8 |
| Celebration | 0.8-1.2s | 4-6 per track |
| Complex sequence | 1.0-2.0s | 5-10 per track |

### Spring Presets for Keyframes

```swift
// Quick snap
SpringKeyframe(value, duration: 0.2, spring: .snappy)

// Standard bounce
SpringKeyframe(value, duration: 0.3, spring: .bouncy)

// Smooth settle
SpringKeyframe(value, duration: 0.4, spring: .smooth)

// Custom physics
SpringKeyframe(value, duration: 0.3, spring: Spring(duration: 0.3, bounce: 0.4))
```
