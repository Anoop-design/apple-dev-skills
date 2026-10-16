# iOS Animations Complete Guide

Master when and how to use every SwiftUI animation API.

## Animation Decision Framework

### Quick Decision Tree

```
Need animation? → What's changing?
│
├─ View appearing/disappearing → Use TRANSITION
│   ├─ Simple fade/slide → Built-in (.opacity, .slide, .move)
│   ├─ Navigation push/pop → NavigationTransition (iOS 18)
│   └─ Custom effect → Custom Transition protocol
│
├─ Property changing (opacity, scale, position) → Use ANIMATION
│   ├─ Single property, simple → Implicit .animation(_:value:)
│   ├─ Multiple views coordinated → Explicit withAnimation { }
│   ├─ Need completion callback → withAnimation(completionCriteria:)
│   └─ Interactive gesture → .interactiveSpring
│
├─ Multi-step sequence → Use PHASE/KEYFRAME ANIMATOR
│   ├─ Discrete states (A→B→C) → PhaseAnimator
│   └─ Precise timing control → KeyframeAnimator
│
├─ SF Symbol → Use SYMBOL EFFECT
│   ├─ One-shot feedback → .symbolEffect(.bounce, value:)
│   ├─ Continuous activity → .symbolEffect(.pulse, isActive:)
│   └─ Symbol swap → .contentTransition(.symbolEffect(.replace))
│
└─ Hero/morphing between views → Use MATCHED GEOMETRY
    ├─ Same screen → matchedGeometryEffect
    └─ Navigation stack → matchedTransitionSource + navigationTransition
```

### When to Use Each Animation Type

| Scenario | Use This | Why |
|----------|----------|-----|
| Button tap feedback | `.spring()` implicit | Natural, handles interruption |
| Loading spinner | `.linear.repeatForever` | Constant mechanical motion |
| Card expand/collapse | `withAnimation(.spring)` | Coordinates multiple views |
| Swipe-to-dismiss | `.interactiveSpring` | Preserves gesture velocity |
| Success checkmark | `PhaseAnimator` | Multi-step: scale→bounce→settle |
| Complex celebration | `KeyframeAnimator` | Precise timing across properties |
| Tab bar icon | `.symbolEffect(.bounce)` | Native SF Symbol animation |
| List item insert | `.transition(.move.combined(.opacity))` | View hierarchy change |
| Photo grid → detail | `matchedGeometryEffect` | Hero transition |
| Navigation zoom | `navigationTransition(.zoom)` | iOS 18 stack transition |

---

## Timing Curves vs Springs

### Springs for responsive state changes

```swift
// iOS 17+ defaults to spring — just use this
withAnimation {
    isExpanded.toggle()
}

// Or be explicit
withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
    isExpanded.toggle()
}
```

**Why springs?**
- Velocity preservation (no jarring stops when interrupted)
- Natural deceleration (like real objects)
- Handles gesture handoff smoothly

### Spring Presets

```swift
.smooth              // No bounce — general UI, 0.5s
.smooth(duration: 0.3)

.snappy              // Tiny bounce — responsive feel, 0.5s
.snappy(duration: 0.2, extraBounce: 0.1)

.bouncy              // Visible bounce — playful UI, 0.5s
.bouncy(duration: 0.4, extraBounce: 0.2)

.spring(duration: 0.4, bounce: 0.3)  // Full control
// bounce: -1.0 (overdamped) to 1.0 (undamped)
```

### Use Timing Curves For

| Use Case | Timing Curve | Why |
|----------|--------------|-----|
| Loading progress | `.linear` | Constant predictable motion |
| Fade in on appear | `.easeIn(duration: 0.2)` | Start slow, end crisp |
| Fade out/dismiss | `.easeOut(duration: 0.2)` | Start crisp, end soft |
| Attention pulse | `.easeInOut.repeatForever` | Smooth continuous loop |
| Mechanical rotation | `.linear.repeatForever` | No acceleration variation |

```swift
// Progress bar — constant fill
.animation(.linear(duration: 2.0), value: progress)

// Spinner — continuous rotation
.rotationEffect(.degrees(rotation))
.animation(.linear(duration: 1).repeatForever(autoreverses: false), value: rotation)
.onAppear { rotation = 360 }

// Breathing pulse
.scaleEffect(isPulsing ? 1.1 : 1.0)
.animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isPulsing)
```

---

## Implicit vs Explicit Animations

### Implicit Animation

Animates property changes on a single view subtree:

```swift
Circle()
    .scaleEffect(isActive ? 1.5 : 1.0)
    .opacity(isActive ? 0.5 : 1.0)
    .animation(.spring(duration: 0.3), value: isActive)  // Value-scoped modifier; closure-scoped animation is another option
```

**Use when:**
- Animating one view's properties
- Animation is self-contained
- Don't need coordination with other views

Prefer the value-scoped modifier over the deprecated unscoped overload. The iOS 17 closure-scoped `.animation(_:body:)` is another valid choice. A value-triggered modifier animates animatable changes in its scope in that transaction, not only the named value.

### Explicit Animation

Creates an animated transaction for the state changes; local transactions and animation modifiers can override it:

```swift
Button("Toggle") {
    withAnimation(.spring(duration: 0.4)) {
        isExpanded.toggle()
    }
}

// All these animate together
HeaderView(isExpanded: isExpanded)
ContentView(isExpanded: isExpanded)
FooterView(isExpanded: isExpanded)
```

**Use when:**
- Multiple views should animate together
- Animation logic belongs with the action, not the view
- Need completion callback

### Completion Callbacks (iOS 17+)

```swift
withAnimation(.spring(duration: 0.4), completionCriteria: .logicallyComplete) {
    showOverlay = true
} completion: {
    // Runs when animation logically finishes (may still be settling)
    loadContent()
}

// Or wait for full removal
withAnimation(.spring, completionCriteria: .removed) {
    showOverlay = false
} completion: {
    // Runs when animation fully removed from system
    cleanupResources()
}
```

---

## Transitions

### When Views Appear/Disappear

Transitions animate view insertion/removal from hierarchy:

```swift
if showDetail {
    DetailView()
        .transition(.move(edge: .bottom))  // Slides up from bottom
}
```

**Key rule:** The insertion or removal needs an animated transaction. Use `withAnimation` around the state change, or an appropriate `.animation(_:value:)` on the containing view. For example:

```swift
Button("Show") {
    withAnimation(.spring) {  // Creates an animated transaction
        showDetail = true
    }
}
```

### Built-in Transitions

| Transition | Effect | Best For |
|------------|--------|----------|
| `.opacity` | Fade in/out | Overlays, subtle changes |
| `.scale` | Grow from center | Popovers, modals |
| `.scale(scale: 0.5, anchor: .top)` | Grow from point | Menus, dropdowns |
| `.slide` | Slide from leading | Sidebars, drawers |
| `.move(edge: .bottom)` | Slide from edge | Sheets, toasts |
| `.push(from: .trailing)` | Push + fade | Page navigation feel |
| `.blurReplace` | Blur + scale | Content swap (iOS 17+) |
| `AnyTransition.offset(x:y:)` | Translate | Custom positions (iOS 13+); the typed `Transition` overload is newer |

### Combined Transitions

```swift
// Slide + fade
.transition(.move(edge: .bottom).combined(with: .opacity))

// Scale from corner + fade
.transition(.scale(scale: 0.8, anchor: .topTrailing).combined(with: .opacity))
```

### Asymmetric Transitions

Different animation for insert vs remove:

```swift
.transition(.asymmetric(
    insertion: .move(edge: .trailing).combined(with: .opacity),
    removal: .move(edge: .leading).combined(with: .opacity)
))
```

**Common patterns:**
- Carousel: slide in from right, out to left
- Stack: push up to enter, fade to exit
- Modal: scale up to enter, fade to exit

### Custom Transitions (iOS 17+ Protocol)

```swift
struct RotateTransition: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .rotationEffect(.degrees(phase.isIdentity ? 0 : 90))
            .scaleEffect(phase.isIdentity ? 1 : 0.5)
            .opacity(phase.isIdentity ? 1 : 0)
    }
}

extension Transition where Self == RotateTransition {
    static var rotate: RotateTransition { RotateTransition() }
}

// Usage
.transition(.rotate)
```

**TransitionPhase values:**
- `.willAppear` — About to insert (phase.value = -1)
- `.identity` — Fully visible (phase.value = 0)\
- `.didDisappear` — Requested removal (phase.value = 1)

---

## Navigation Transitions (iOS 18+)

### Zoom Transition

Creates App Store-style hero animation between navigation levels:

```swift
struct GalleryView: View {
    @Namespace var namespace

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(photos) { photo in
                        NavigationLink(value: photo) {
                            PhotoThumbnail(photo: photo)
                                .matchedTransitionSource(id: photo.id, in: namespace)
                        }
                    }
                }
            }
            .navigationDestination(for: Photo.self) { photo in
                PhotoDetail(photo: photo)
                    .navigationTransition(.zoom(sourceID: photo.id, in: namespace))
            }
        }
    }
}
```

**Requirements:**
1. `@Namespace` shared between source and destination
2. `.matchedTransitionSource(id:in:)` on the source view
3. `.navigationTransition(.zoom(sourceID:in:))` on destination

---

## Matched Geometry Effect

### Hero Animations (Same Screen)

```swift
struct ExpandableCard: View {
    @Namespace private var animation
    @State private var isExpanded = false

    var body: some View {
        ZStack {
            if !isExpanded {
                // Compact state
                CompactCard()
                    .matchedGeometryEffect(id: "card", in: animation)
                    .onTapGesture {
                        withAnimation(.spring(duration: 0.5, bounce: 0.2)) {
                            isExpanded = true
                        }
                    }
            } else {
                // Expanded state
                ExpandedCard()
                    .matchedGeometryEffect(id: "card", in: animation)
                    .onTapGesture {
                        withAnimation(.spring(duration: 0.4)) {
                            isExpanded = false
                        }
                    }
            }
        }
    }
}
```

For separate title movement, put the title match on the actual title subview, not a second identity on the whole card.

**Rules:**
- Same `id` and `namespace` on matched views
- Exactly one inserted view should be the source (`isSource: true`) for a matched identity; destinations can coexist with `isSource: false`. Conditional replacement is a common pattern.
- Use `properties: .position` for text to avoid size glitches

---

## Phase Animator (iOS 17+)

### Multi-Step Discrete Animations

For animations with distinct states (idle → active → settled):

```swift
enum BouncePhase: CaseIterable {
    case rest, up, down

    var scale: Double {
        switch self {
        case .rest: 1.0
        case .up: 1.3
        case .down: 0.9
        }
    }

    var offsetY: Double {
        switch self {
        case .rest: 0
        case .up: -20
        case .down: 5
        }
    }
}

struct BounceButton: View {
    @State private var trigger = 0

    var body: some View {
        Button("Tap Me") {
            trigger += 1
        }
        .phaseAnimator(BouncePhase.allCases, trigger: trigger) { content, phase in
            content
                .scaleEffect(phase.scale)
                .offset(y: phase.offsetY)
        } animation: { phase in
            switch phase {
            case .rest: .spring(duration: 0.2)
            case .up: .spring(duration: 0.15, bounce: 0.5)
            case .down: .spring(duration: 0.25)
            }
        }
    }
}
```

### Continuous Looping

Without `trigger`, loops forever:

```swift
PhaseAnimator([false, true]) { phase in
    Circle()
        .scaleEffect(phase ? 1.2 : 1.0)
        .opacity(phase ? 0.6 : 1.0)
} animation: { _ in
    .easeInOut(duration: 0.8)
}
```

---

## Keyframe Animator (iOS 17+)

### Precise Multi-Track Timing

For complex choreographed animations with independent property timing:

```swift
struct CelebrationValues {
    var scale: Double = 1.0
    var rotation: Angle = .zero
    var yOffset: Double = 0
    var opacity: Double = 1.0
}

struct CelebrationView: View {
    @State private var trigger = false

    var body: some View {
        Text("🎉")
            .font(.system(size: 60))
            .keyframeAnimator(
                initialValue: CelebrationValues(),
                trigger: trigger
            ) { content, value in
                content
                    .scaleEffect(value.scale)
                    .rotationEffect(value.rotation)
                    .offset(y: value.yOffset)
                    .opacity(value.opacity)
            } keyframes: { _ in
                // Scale track
                KeyframeTrack(\.scale) {
                    SpringKeyframe(1.5, duration: 0.2, spring: .bouncy)
                    SpringKeyframe(1.0, duration: 0.3, spring: .bouncy)
                    SpringKeyframe(1.3, duration: 0.2, spring: .bouncy)
                    SpringKeyframe(1.0, duration: 0.3, spring: .smooth)
                }

                // Rotation track (independent timing)
                KeyframeTrack(\.rotation) {
                    LinearKeyframe(.zero, duration: 0.1)
                    CubicKeyframe(.degrees(15), duration: 0.15)
                    CubicKeyframe(.degrees(-15), duration: 0.15)
                    CubicKeyframe(.degrees(10), duration: 0.1)
                    CubicKeyframe(.degrees(-10), duration: 0.1)
                    CubicKeyframe(.zero, duration: 0.2)
                }

                // Y offset track
                KeyframeTrack(\.yOffset) {
                    SpringKeyframe(-30, duration: 0.3, spring: .bouncy)
                    SpringKeyframe(0, duration: 0.5, spring: .smooth)
                }
            }
            .onTapGesture { trigger.toggle() }
    }
}
```

### Keyframe Types

| Type | Interpolation | Use For |
|------|---------------|---------|
| `LinearKeyframe` | Constant speed | Holding values, mechanical motion |
| `CubicKeyframe` | Bezier curve | Smooth organic motion |
| `SpringKeyframe` | Physics spring | Bouncy, settling effects |
| `MoveKeyframe` | Instant jump | Discontinuous changes |

```swift
KeyframeTrack(\.scale) {
    LinearKeyframe(1.0, duration: 0.5)      // Hold at 1.0 for 0.5s
    CubicKeyframe(1.5, duration: 0.3)       // Smooth curve to 1.5
    SpringKeyframe(1.0, spring: .bouncy)    // Bounce back to 1.0
}
```

---

## SF Symbol Effects (iOS 17+)

### Discrete Effects (One-Shot)

Triggered on value change:

```swift
Image(systemName: "heart.fill")
    .symbolEffect(.bounce, value: likeCount)

Image(systemName: "bell.fill")
    .symbolEffect(.bounce.up.byLayer, options: .repeat(2), value: notificationCount)
```

### Indefinite Effects (Continuous)

Active while boolean is true:

```swift
Image(systemName: "wifi")
    .symbolEffect(.variableColor.iterative, isActive: isConnecting)

Image(systemName: "arrow.trianglehead.2.clockwise")
    .symbolEffect(.rotate, isActive: isSyncing)  // iOS 18
```

### All Symbol Effects

| Effect | iOS | Behavior |
|--------|-----|----------|
| `.bounce` | 17 | Quick scale bounce |
| `.bounce.up/down/byLayer` | 17 | Directional variants |
| `.pulse` | 17 | Opacity fade |
| `.variableColor` | 17 | Layer-by-layer color |
| `.scale.up/down` | 17 | Size change |
| `.appear/.disappear` | 17 | Show/hide |
| `.wiggle` | 18 | Shake motion |
| `.breathe` | 18 | Subtle pulse |
| `.rotate` | 18 | Spin |

### Symbol Content Transitions

```swift
// Animate between different symbols
Image(systemName: isPlaying ? "pause.fill" : "play.fill")
    .contentTransition(.symbolEffect(.replace))

// Directional replace
Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
    .contentTransition(.symbolEffect(.replace.offUp))
```

---

## Gesture-Driven Animations

### Interactive Spring

A responsive spring for gesture completion. Direct assignment of translation does not establish a general velocity-transfer guarantee; use the gesture’s predicted end/velocity where the interaction needs explicit momentum:

```swift
struct SwipeCard: View {
    @State private var offset: CGSize = .zero
    @State private var isDragging = false

    var body: some View {
        Card()
            .offset(offset)
            .rotationEffect(.degrees(Double(offset.width) / 20))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = value.translation
                        isDragging = true
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 150
                        if abs(value.translation.width) > threshold {
                            // Swipe away
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                offset.width = value.translation.width > 0 ? 500 : -500
                            }
                        } else {
                            // Snap back
                            withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.7)) {
                                offset = .zero
                            }
                        }
                        isDragging = false
                    }
            )
            .animation(.interactiveSpring, value: isDragging)
    }
}
```

### Scroll-Driven Effects

```swift
ScrollView {
    LazyVStack {
        ForEach(items) { item in
            ItemCard(item: item)
                .scrollTransition { content, phase in
                    content
                        .opacity(phase.isIdentity ? 1 : 0.5)
                        .scaleEffect(phase.isIdentity ? 1 : 0.9)
                        .blur(radius: phase.isIdentity ? 0 : 2)
                }
        }
    }
}
```

---

## Custom Animatable Properties

### Animatable Protocol

Make custom properties animate:

```swift
struct AnimatableGradient: View, Animatable {
    var progress: Double  // 0 to 1

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        LinearGradient(
            colors: [
                .blue.opacity(1 - progress),
                .purple.opacity(progress)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// Usage
AnimatableGradient(progress: isActive ? 1.0 : 0.0)
    .animation(.spring(duration: 0.5), value: isActive)
```

### AnimatablePair for Multiple Properties

```swift
struct AnimatableRing: Shape {
    var startAngle: Double
    var endAngle: Double

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(startAngle, endAngle) }
        set {
            startAngle = newValue.first
            endAngle = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                    radius: min(rect.width, rect.height) / 2,
                    startAngle: .degrees(startAngle), endAngle: .degrees(endAngle),
                    clockwise: false)
        return path
    }
}
```

---

## Performance Tips

### Do This

```swift
// Extract animated subviews
struct ParentView: View {
    var body: some View {
        VStack {
            AnimatedHeader()  // Keep frequently changing dependencies here
            StaticContent()   // Check actual evaluation cost with Instruments
        }
    }
}

// Use built-in animatable modifiers
.scaleEffect(scale)
.opacity(opacity)
.offset(x: offsetX)

// Respect reduced motion
@Environment(\.accessibilityReduceMotion) var reduceMotion

.animation(reduceMotion ? nil : .spring, value: isActive)
```

### Avoid This

```swift
// DON'T: Animation without value (unpredictable)
.animation(.spring)

// DON'T: Complex computation in body during animation
var body: some View {
    let sorted = items.sorted { ... }  // Repeated whenever this body evaluates
}

// Avoid unnecessary geometry dependencies and layout feedback loops.
// GeometryReader inside scrolling content is valid when its sizing is deliberate.
// Prefer local geometry observation and only publish the values a view needs.
```

---

## Quick Reference: Animation APIs

| API | iOS | Purpose |
|-----|-----|---------|
| `.animation(_:value:)` | 15 | Implicit animation on value change |
| `withAnimation { }` | 13 | Explicit animation block |
| `.transition(_:)` | 13 | View insert/remove animation |
| `@Namespace` | 14 | Hero animation coordination |
| `.matchedGeometryEffect` | 14 | Hero transitions |
| `PhaseAnimator` | 17 | Multi-step discrete animations |
| `KeyframeAnimator` | 17 | Precise multi-track timing |
| `.symbolEffect` | 17 | SF Symbol animations |
| `Transition` protocol | 17 | Custom transition with phases |
| `.scrollTransition` | 17 | Scroll-driven effects |
| `NavigationTransition` | 18 | Navigation stack transitions |
| `.matchedTransitionSource` | 18 | Zoom transition source |

## See Also

- `animation-decision-tree.md` — Visual flowchart for choosing animations
- `transition-catalog.md` — All transitions with visual examples
- `keyframe-patterns.md` — Copy-paste keyframe recipes
- `spring-tuning.md` — Spring parameter reference


State-driven animation routes: [SwiftUI animations](https://developer.apple.com/documentation/swiftui/animations).
