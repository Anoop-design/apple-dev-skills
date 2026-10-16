# Spring Animation Tuning Guide

Master spring physics for natural-feeling animations.

## Why Springs?

Springs are the default animation in iOS 17+ because they:
- **Preserve velocity** — No jarring stops when interrupted
- **Feel natural** — Mimic real-world physics
- **Handle gestures** — Smooth handoff from user input
- **Settle with damping** — Zero damping can oscillate indefinitely; choose finite useful motion.

---

## Spring Presets

### Quick Reference

| Preset | Duration | Bounce | Feel |
|--------|----------|--------|------|
| `.smooth` | 0.5s | 0 | Gentle, no bounce |
| `.snappy` | 0.5s | ~0.15 | Responsive, tiny bounce |
| `.bouncy` | 0.5s | ~0.3 | Playful, visible bounce |

```swift
withAnimation(.smooth) { }       // General UI
withAnimation(.snappy) { }       // Buttons, toggles
withAnimation(.bouncy) { }       // Fun interactions
```

### Customizing Presets

```swift
// Faster smooth
.smooth(duration: 0.25)

// Snappier with more bounce
.snappy(duration: 0.3, extraBounce: 0.1)

// Very bouncy
.bouncy(duration: 0.5, extraBounce: 0.2)
```

---

## Duration + Bounce API (iOS 17+)

The modern, intuitive way to define springs:

```swift
.spring(duration: 0.4, bounce: 0.2)
```

### Duration

Perceptual duration, designed to stay comparable as bounce changes. It is not a fixed 63%-of-target threshold and can differ from settling duration:

| Value | Feel | Use Case |
|-------|------|----------|
| 0.15-0.25s | Snappy | Micro-interactions, toggles |
| 0.3-0.4s | Standard | General UI |
| 0.5-0.6s | Relaxed | Modal presentations |
| 0.8-1.0s | Slow | Dramatic reveals |

### Bounce

Controls oscillation around target:

| Value | Behavior | Use Case |
|-------|----------|----------|
| -1.0 | Overdamped (slow approach) | Rare |
| 0.0 | No bounce (critically damped) | Subtle UI |
| 0.1-0.2 | Subtle bounce | Most UI |
| 0.3-0.4 | Moderate bounce | Playful UI |
| 0.5-0.7 | Strong bounce | Cartoon effects |
| 1.0 | Undamped, does not settle | Avoid for finite UI transitions |

```swift
// No bounce — smooth slide
.spring(duration: 0.4, bounce: 0.0)

// Subtle — professional feel
.spring(duration: 0.35, bounce: 0.15)

// Playful — app store style
.spring(duration: 0.5, bounce: 0.3)

// Cartoon — game UI
.spring(duration: 0.6, bounce: 0.6)
```

---

## Response + Damping API (Legacy)

Older API, still useful for precise control:

```swift
.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)
```

### Response

Approximate period of oscillation:

| Value | Duration | Use Case |
|-------|----------|----------|
| 0.15 | Very fast | Micro feedback |
| 0.3 | Fast | Toggles, buttons |
| 0.5 | Medium | General (default) |
| 0.8 | Slow | Modals, sheets |
| 1.0+ | Very slow | Dramatic |

### Damping Fraction

Controls how quickly oscillations decay:

| Value | Behavior |
|-------|----------|
| 0.0 | Infinite oscillation (never settles) |
| 0.5 | Underdamped (visible bouncing) |
| 0.7 | Default (slight bounce) |
| 1.0 | Critically damped (no overshoot) |
| > 1.0 | Overdamped (slow approach) |

```swift
// Snappy with bounce
.spring(response: 0.3, dampingFraction: 0.6)

// Smooth, no overshoot
.spring(response: 0.4, dampingFraction: 1.0)

// Very bouncy
.spring(response: 0.5, dampingFraction: 0.5)
```

---

## Interactive Spring

For gesture-driven animations with velocity preservation:

```swift
.interactiveSpring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.1)
```

Interactive spring uses defaults suited to interactive updates. Springs preserve velocity when retargeted, but a directly assigned drag translation does not automatically guarantee the desired release momentum; use gesture velocity/predicted end information when necessary.

```swift
DragGesture()
    .onChanged { value in
        offset = value.translation
    }
    .onEnded { value in
        withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.7)) {
            offset = .zero
        }
    }
```

### Interpolating Spring

Combines with other springs:

```swift
.interpolatingSpring(mass: 1.0, stiffness: 170, damping: 15, initialVelocity: 0)
```

---

## Physics-Based Spring

Direct control over physical properties:

```swift
.interpolatingSpring(
    mass: 1.0,        // Heavier = slower, more momentum
    stiffness: 170,   // Higher = faster oscillation
    damping: 15,      // Higher = less bounce
    initialVelocity: 0 // Starting velocity
)
```

### Common Presets

```swift
// Gentle
.interpolatingSpring(mass: 1.0, stiffness: 100, damping: 15)

// Snappy
.interpolatingSpring(mass: 0.8, stiffness: 200, damping: 18)

// Bouncy
.interpolatingSpring(mass: 1.0, stiffness: 150, damping: 10)

// Heavy/slow
.interpolatingSpring(mass: 2.0, stiffness: 100, damping: 20)
```

---

## Spring Struct (Programmatic)

Create reusable springs or evaluate values:

```swift
let mySpring = Spring(duration: 0.5, bounce: 0.2)

// Evaluate position at specific time
let position = mySpring.value(target: 100.0, time: 0.3)

// Get current velocity
let velocity = mySpring.velocity(target: 100.0, time: 0.3)

// Settling duration uses the spring’s convergence criterion
let settlingTime = mySpring.settlingDuration
```

### Use Cases

```swift
// Scroll-driven animation
let progress = scrollOffset / maxOffset
let animatedValue = mySpring.value(target: 1.0, time: progress)

// Custom animation timing
let timeline = KeyframeTimeline(initialValue: 0.0) {
    KeyframeTrack(\.self) {
        SpringKeyframe(1.0, spring: mySpring)
    }
}
```

---

## Tuning by Use Case

### Buttons & Toggles

```swift
.spring(duration: 0.25, bounce: 0.15)
// OR
.snappy
```
Quick response, subtle feedback.

### Cards & Panels

```swift
.spring(duration: 0.4, bounce: 0.1)
// OR
.smooth(duration: 0.4)
```
Smooth movement, minimal bounce.

### Modals & Sheets

```swift
.spring(duration: 0.5, bounce: 0.15)
```
Slightly slower, professional feel.

### Hero Transitions

```swift
.spring(duration: 0.5, bounce: 0.2)
```
Visible but controlled bounce.

### Gesture Release

```swift
.interactiveSpring(response: 0.35, dampingFraction: 0.7)
```
Tune the release and check actual gesture velocity transfer.

### Game/Playful UI

```swift
.spring(duration: 0.6, bounce: 0.4)
// OR
.bouncy(extraBounce: 0.2)
```
More exaggerated, fun feel.

### Loading Indicators

```swift
.linear(duration: 1.0).repeatForever()
// NOT spring — use constant motion
```

---

## Comparison Table

| Scenario | API | Parameters |
|----------|-----|------------|
| Default iOS feel | `.spring()` | Default |
| No bounce | `.smooth` | bounce: 0 |
| Slight bounce | `.snappy` | bounce: ~0.15 |
| Playful bounce | `.bouncy` | bounce: ~0.3 |
| Quick tap | `.spring(duration: 0.2, bounce: 0.1)` | — |
| Slow dramatic | `.spring(duration: 0.8, bounce: 0.2)` | — |
| Gesture handoff | `.interactiveSpring(response: 0.35)` | — |
| Physics control | `.interpolatingSpring(mass:stiffness:)` | — |

---

## Visual Reference

```
BOUNCE SPECTRUM
─────────────────────────────────────────────────────────────
0.0                 0.2                 0.4                1.0
│                   │                   │                  │
▼                   ▼                   ▼                  ▼
╭──╮               ╭──╮               ╭──╮              ╭──╮
│  │               │  ╰╮              │  ╰╮╭╮          │  ╰╮╭╮╭╮
│  │               │   │              │   ╰╯│          │   ╰╯╰╯│
│  │               │   │              │     │          │      ╰╯
╰──┴────           ╰───┴───           ╰─────┴─         ╰────────┴─
No bounce          Subtle              Moderate         Very bouncy


DURATION SPECTRUM
─────────────────────────────────────────────────────────────
0.15s               0.3s                0.5s              1.0s
│                   │                   │                 │
▼                   ▼                   ▼                 ▼
Instant            Quick              Standard           Slow
toggle             button             modal              dramatic
```

---

## Debugging Springs

### Slow motion preview

```swift
// Simulator: Debug → Slow Animations (⌘T)

// Or multiply duration
.spring(duration: 2.0, bounce: 0.2)  // 4x slower for observation
```

### Print spring parameters

```swift
let spring = Spring(duration: 0.5, bounce: 0.2)
print("Stiffness: \(spring.stiffness)")
print("Damping: \(spring.damping)")
print("Settling: \(spring.settlingDuration)")
```

### Compare side-by-side

```swift
HStack {
    Circle().animation(.smooth, value: trigger)
    Circle().animation(.snappy, value: trigger)
    Circle().animation(.bouncy, value: trigger)
}
```

Primary source: [Spring duration](https://developer.apple.com/documentation/swiftui/spring/duration) and [duration/bounce animation](https://developer.apple.com/documentation/swiftui/animation/spring(duration:bounce:blendduration:)). Checked 2026-10-16 against the installed SwiftUI declarations; example timings are design choices, not Apple defaults for every interaction.
