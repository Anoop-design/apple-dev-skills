# Transition Catalog

Complete reference for all SwiftUI transitions with usage examples.

## Built-in Transitions

### Opacity

Fades view in/out by changing transparency.

```swift
if showView {
    ContentView()
        .transition(.opacity)
}
```

**Best for:** Overlays, subtle content changes, layered UI
**Pair with:** Any animation, works well with .spring

---

### Scale

Grows from center (or anchor point) when appearing, shrinks when disappearing.

```swift
// Default (from center)
.transition(.scale)

// From specific point
.transition(.scale(scale: 0.5, anchor: .topTrailing))

// From zero (dramatic)
.transition(.scale(scale: 0))
```

**Best for:** Popovers, modals, menus, buttons
**Pair with:** `.combined(with: .opacity)` for polish

---

### Slide

Slides in from leading edge, out to trailing edge.

```swift
.transition(.slide)
```

**Best for:** Sidebars, navigation drawers, carousel items
**Note:** Always horizontal, follows reading direction (RTL aware)

---

### Move

Slides from specified edge.

```swift
.transition(.move(edge: .bottom))   // Slides up from bottom
.transition(.move(edge: .top))      // Slides down from top
.transition(.move(edge: .leading))  // Slides from left
.transition(.move(edge: .trailing)) // Slides from right
```

**Best for:** Sheets, toasts, notifications, slide-in panels

---

### Push (iOS 16+)

Moves in while fading, pushes out the opposite direction.

```swift
.transition(.push(from: .bottom))
.transition(.push(from: .trailing))
```

**Best for:** Page-style navigation, content replacement
**Difference from move:** Includes opacity fade for smoother feel

---

### Offset

`AnyTransition.offset` is available from iOS 13; typed Transition APIs require iOS 17.

Translates by specific amounts.

```swift
.transition(.offset(x: 0, y: 100))
.transition(.offset(CGSize(width: 50, height: 50)))
```

**Best for:** Custom positioning, fine-tuned entrances

---

### Blur Replace (iOS 17+)

Combines blur with scale for content replacement.

```swift
.transition(.blurReplace)
.transition(.blurReplace(.downUp))   // Scale down on remove, up on insert
.transition(.blurReplace(.upUp))     // Scale up in both directions
```

**Best for:** Content swaps, image transitions, dramatic reveals

---

### Symbol Effect (iOS 17+)

Applies SF Symbol animation as a transition.

```swift
.transition(.symbolEffect(.appear))
.transition(.symbolEffect(.disappear))
.transition(.symbolEffect)  // Default appear/disappear
```

**Best for:** SF Symbol icons appearing/disappearing

---

### Identity

No transition — instant change.

```swift
.transition(.identity)
```

**Best for:** Disabling inherited transitions, testing

---

## Combining Transitions

### Combined

Apply multiple effects simultaneously:

```swift
// Scale + Fade
.transition(.scale.combined(with: .opacity))

// Move + Fade
.transition(.move(edge: .bottom).combined(with: .opacity))

// Scale from corner + Fade
.transition(
    .scale(scale: 0.8, anchor: .topTrailing)
    .combined(with: .opacity)
)

// Triple combination
.transition(
    .scale
    .combined(with: .opacity)
    .combined(with: .offset(y: 20))
)
```

---

### Asymmetric

Different animations for insert vs remove:

```swift
// Slide in from right, fade out
.transition(.asymmetric(
    insertion: .move(edge: .trailing),
    removal: .opacity
))

// Scale up to enter, slide down to exit
.transition(.asymmetric(
    insertion: .scale.combined(with: .opacity),
    removal: .move(edge: .bottom).combined(with: .opacity)
))

// Carousel style
.transition(.asymmetric(
    insertion: .move(edge: .trailing).combined(with: .opacity),
    removal: .move(edge: .leading).combined(with: .opacity)
))
```

---

## Custom Transitions

### Using Transition Protocol (iOS 17+)

```swift
struct RotateTransition: Transition {
    var angle: Angle = .degrees(90)

    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .rotationEffect(phase.isIdentity ? .zero : angle)
            .scaleEffect(phase.isIdentity ? 1 : 0.8)
            .opacity(phase.isIdentity ? 1 : 0)
    }
}

// Extension for dot syntax
extension Transition where Self == RotateTransition {
    static var rotate: RotateTransition { RotateTransition() }
    static func rotate(angle: Angle) -> RotateTransition {
        RotateTransition(angle: angle)
    }
}

// Usage
.transition(.rotate)
.transition(.rotate(angle: .degrees(180)))
```

### TransitionPhase Values

| Phase | isIdentity | value | When |
|-------|------------|-------|------|
| `.willAppear` | false | -1 | Before view appears |
| `.identity` | true | 0 | View fully visible |
| `.didDisappear` | false | 1 | After view removed |

```swift
struct FlipTransition: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .rotation3DEffect(
                .degrees(phase.value * 90),  // -90° → 0° → 90°
                axis: (x: 0, y: 1, z: 0)
            )
            .opacity(phase.isIdentity ? 1 : 0)
    }
}
```

### Using ViewModifier (iOS 13+)

Older approach, still works:

```swift
struct SlideAndFade: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .offset(y: isActive ? 50 : 0)
            .opacity(isActive ? 0 : 1)
    }
}

extension AnyTransition {
    static var slideAndFade: AnyTransition {
        .modifier(
            active: SlideAndFade(isActive: true),
            identity: SlideAndFade(isActive: false)
        )
    }
}
```

---

## Common Transition Patterns

### Modal/Popup

```swift
.transition(
    .scale(scale: 0.9)
    .combined(with: .opacity)
)
// Animation: .spring(duration: 0.3, bounce: 0.1)
```

### Toast Notification

```swift
.transition(
    .move(edge: .top)
    .combined(with: .opacity)
)
// Animation: .spring(duration: 0.25)
```

### Bottom Sheet

```swift
.transition(.move(edge: .bottom))
// Animation: .spring(duration: 0.35, bounce: 0.15)
```

### Sidebar

```swift
.transition(.move(edge: .leading))
// Animation: .spring(duration: 0.3)
```

### Carousel Item

```swift
.transition(.asymmetric(
    insertion: .move(edge: .trailing).combined(with: .opacity),
    removal: .move(edge: .leading).combined(with: .opacity)
))
// Animation: .easeInOut(duration: 0.3)
```

### Image Crossfade

```swift
.transition(.blurReplace)
// Animation: .easeInOut(duration: 0.4)
```

### Menu Dropdown

```swift
.transition(
    .scale(scale: 0.95, anchor: .top)
    .combined(with: .opacity)
)
// Animation: .spring(duration: 0.2)
```

### Card Expand (with hero)

```swift
// On card in grid
.matchedGeometryEffect(id: item.id, in: namespace)
.transition(.scale.combined(with: .opacity))

// On expanded detail
.matchedGeometryEffect(id: item.id, in: namespace)
.transition(.scale.combined(with: .opacity))

// Animation: .spring(duration: 0.4, bounce: 0.15)
```

---

## Transition Animation Timing

Transitions need an animated insertion/removal transaction. Use `withAnimation` around the state change or a value-scoped animation on the containing view:

```swift
Button("Show") {
    withAnimation(.spring(duration: 0.3)) {  // Creates the animated transaction
        showContent = true
    }
}
```

### Recommended Timings

| Transition Type | Animation | Duration |
|-----------------|-----------|----------|
| Opacity fade | .easeInOut | 0.2-0.3s |
| Scale popup | .spring | 0.25-0.35s, bounce: 0.1 |
| Move/slide | .spring | 0.3-0.4s, bounce: 0.1 |
| Push navigation | .spring | 0.35s |
| Blur replace | .easeInOut | 0.3-0.5s |

### Attaching Animation to Transition

```swift
.transition(
    .move(edge: .bottom)
    .animation(.spring(duration: 0.35))
)
```

**Note:** This overrides any external animation for this specific transition.

---

## Debugging Transitions

### Common Issues

| Problem | Cause | Fix |
|---------|-------|-----|
| No animation | No animated insertion/removal transaction | Use withAnimation or an appropriate containing value-scoped animation |
| Animation resets | View identity changed | Use stable IDs, check `ForEach` |
| Wrong direction | Asymmetric reversed | Swap insertion/removal |
| Jarring motion | Timing too fast | Increase duration, add spring |
| Flicker | Transition conflict | Use `.transaction { $0.animation = nil }` on the intended scope |

### Slow Motion Debug

```swift
// In Simulator: Debug → Slow Animations (⌘T)

// Or programmatically
withAnimation(.spring(duration: 2.0)) {  // Slow down to observe
    showContent.toggle()
}
```

### View Identity Check

```swift
var body: some View {
    let _ = Self._printChanges()  // Logs what triggered update
    // ...
}
```
