# Animation Decision Tree

Visual guide for choosing the right SwiftUI animation API.

## Master Decision Flowchart

```
┌─────────────────────────────────────────────────────────────────────┐
│                    WHAT ARE YOU ANIMATING?                          │
└─────────────────────────────────────────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        ▼                       ▼                       ▼
┌───────────────┐     ┌─────────────────┐     ┌─────────────────────┐
│ VIEW PROPERTY │     │ VIEW APPEARING/ │     │ COMPLEX SEQUENCE    │
│ (opacity,     │     │ DISAPPEARING    │     │ (multi-step,        │
│  scale, etc.) │     │                 │     │  choreographed)     │
└───────┬───────┘     └────────┬────────┘     └──────────┬──────────┘
        │                      │                         │
        ▼                      ▼                         ▼
   ┌────────┐            ┌──────────┐             ┌─────────────┐
   │ How    │            │ Where?   │             │ Discrete    │
   │ many   │            │          │             │ states or   │
   │ views? │            │          │             │ precise     │
   └───┬────┘            └────┬─────┘             │ timing?     │
       │                      │                   └──────┬──────┘
   ┌───┴───┐             ┌────┴────┐               ┌────┴────┐
   ▼       ▼             ▼         ▼               ▼         ▼
┌─────┐ ┌─────┐    ┌─────────┐ ┌────────┐   ┌─────────┐ ┌──────────┐
│ ONE │ │MANY │    │ Same    │ │ Nav    │   │ States  │ │ Precise  │
│     │ │     │    │ Screen  │ │ Stack  │   │ A→B→C   │ │ Timing   │
└──┬──┘ └──┬──┘    └────┬────┘ └───┬────┘   └────┬────┘ └────┬─────┘
   │       │            │          │              │           │
   ▼       ▼            ▼          ▼              ▼           ▼
┌──────┐ ┌──────┐  ┌────────┐ ┌────────┐  ┌───────────┐ ┌───────────┐
│.anim │ │with  │  │.transi │ │.naviga │  │Phase      │ │Keyframe   │
│ation│ │Anima │  │tion()  │ │tionTra │  │Animator   │ │Animator   │
│(_:  │ │tion  │  │        │ │nsition │  │           │ │           │
│value│ │{ }   │  │        │ │(.zoom) │  │           │ │           │
│:)   │ │      │  │        │ │iOS 18  │  │           │ │           │
└──────┘ └──────┘  └────────┘ └────────┘  └───────────┘ └───────────┘
```

## Timing Curve Selection

```
┌─────────────────────────────────────────────────────────────────────┐
│                    WHAT MOTION FEELING?                             │
└─────────────────────────────────────────────────────────────────────┘
                                │
    ┌───────────────────────────┼───────────────────────┐
    ▼                           ▼                       ▼
┌─────────────┐         ┌───────────────┐       ┌───────────────┐
│  NATURAL    │         │  MECHANICAL   │       │  ATTENTION    │
│  (UI feel)  │         │  (constant)   │       │  (emphasis)   │
└──────┬──────┘         └───────┬───────┘       └───────┬───────┘
       │                        │                       │
       ▼                        ▼                       ▼
  USE SPRING               USE LINEAR             USE EASING
       │                        │                       │
   ┌───┴────┐              ┌────┴────┐             ┌────┴────┐
   ▼        ▼              ▼         ▼             ▼         ▼
┌──────┐ ┌──────┐    ┌────────┐ ┌────────┐   ┌────────┐ ┌────────┐
│Quick │ │Play- │    │Spinner │ │Progress│   │Appear  │ │Dismiss │
│resp- │ │ful   │    │        │ │bar     │   │        │ │        │
│onse  │ │      │    │        │ │        │   │        │ │        │
└──┬───┘ └──┬───┘    └────────┘ └────────┘   └───┬────┘ └───┬────┘
   │        │             │          │           │          │
   ▼        ▼             ▼          ▼           ▼          ▼
.snappy  .bouncy     .linear     .linear     .easeIn   .easeOut
.smooth  bounce:0.3  repeat     duration:X   (0.2s)    (0.2s)
                     Forever
```

## Spring Parameter Guide

```
BOUNCE PARAMETER (-1.0 to 1.0)
──────────────────────────────────────────────────────────────────────
-1.0        0.0         0.2         0.4         0.6         1.0
 │           │           │           │           │           │
 ▼           ▼           ▼           ▼           ▼           ▼
Over-     No bounce   Subtle     Moderate    Playful    Very
damped    (smooth)    bounce     bounce      bounce     bouncy
                      (snappy)   (default)   (bouncy)   (cartoon)

DURATION PARAMETER
──────────────────────────────────────────────────────────────────────
0.2s        0.3s        0.4s        0.5s        0.8s        1.0s+
 │           │           │           │           │           │
 ▼           ▼           ▼           ▼           ▼           ▼
Snappy    Quick       Standard    Default     Slow        Very
feedback  response    UI          preset      dramatic    slow
```

## Transition Selection

```
┌─────────────────────────────────────────────────────────────────────┐
│              VIEW APPEARING/DISAPPEARING                            │
└─────────────────────────────────────────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        ▼                       ▼                       ▼
┌───────────────┐     ┌─────────────────┐     ┌─────────────────────┐
│ SUBTLE        │     │ DIRECTIONAL     │     │ HERO/MORPH          │
│               │     │                 │     │                     │
└───────┬───────┘     └────────┬────────┘     └──────────┬──────────┘
        │                      │                         │
    ┌───┴───┐             ┌────┴────┐               ┌────┴────┐
    ▼       ▼             ▼         ▼               ▼         ▼
.opacity  .scale    .slide    .move(edge:)   matchedGeo  .zoom
                    .push     .offset        metryEffect (iOS18)

COMBINED PATTERNS:
──────────────────────────────────────────────────────────────────────
Modal popup     → .scale.combined(with: .opacity)
Toast message   → .move(edge: .top).combined(with: .opacity)
Sidebar         → .move(edge: .leading)
Bottom sheet    → .move(edge: .bottom)
Carousel item   → .asymmetric(insertion: .move(.trailing),
                              removal: .move(.leading))
```

## Multi-Step Animation Selection

```
┌─────────────────────────────────────────────────────────────────────┐
│              COMPLEX ANIMATION NEEDED                               │
└─────────────────────────────────────────────────────────────────────┘
                                │
                    ┌───────────┴───────────┐
                    ▼                       ▼
          ┌─────────────────┐     ┌─────────────────────┐
          │ DISCRETE STATES │     │ PRECISE TIMING      │
          │                 │     │                     │
          │ A → B → C       │     │ Multiple properties │
          │ (each has       │     │ with independent    │
          │  distinct look) │     │ timing curves       │
          └────────┬────────┘     └──────────┬──────────┘
                   │                         │
                   ▼                         ▼
          ┌─────────────────┐     ┌─────────────────────┐
          │ PhaseAnimator   │     │ KeyframeAnimator    │
          │                 │     │                     │
          │ enum Phase {    │     │ KeyframeTrack(\     │
          │   case a, b, c  │     │   .scale) {...}     │
          │ }               │     │ KeyframeTrack(\     │
          │                 │     │   .rotation) {...}  │
          └─────────────────┘     └─────────────────────┘

WHEN TO USE WHICH:

PhaseAnimator:
✓ Button press feedback (idle → pressed → released)
✓ Success animation (grow → shrink → settle)
✓ Attention shake (left → right → left → center)
✓ Loading dots (dot1 active → dot2 active → dot3 active)

KeyframeAnimator:
✓ Celebration confetti (precise timing on many elements)
✓ Character animation (walk cycle with exact poses)
✓ Complex logo animation (scale, rotate, translate independently)
✓ Music visualizer (sync to beat with exact timing)
```

## SF Symbol Effect Selection

```
┌─────────────────────────────────────────────────────────────────────┐
│              ANIMATING SF SYMBOL                                    │
└─────────────────────────────────────────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        ▼                       ▼                       ▼
┌───────────────┐     ┌─────────────────┐     ┌─────────────────────┐
│ ONE-SHOT      │     │ CONTINUOUS      │     │ SYMBOL CHANGE       │
│ (on event)    │     │ (while active)  │     │ (A → B)             │
└───────┬───────┘     └────────┬────────┘     └──────────┬──────────┘
        │                      │                         │
        ▼                      ▼                         ▼
.symbolEffect(      .symbolEffect(           .contentTransition(
  .bounce,            .pulse,                   .symbolEffect(
  value: trigger)     isActive: bool)             .replace))

EFFECT OPTIONS:
──────────────────────────────────────────────────────────────────────
User action feedback  → .bounce, .bounce.up
Loading indicator     → .pulse, .variableColor.iterative
Sync in progress      → .rotate (iOS 18)
Download complete     → .bounce.byLayer
Toggle state          → .contentTransition(.symbolEffect(.replace))
Activity indicator    → .variableColor.reversing.iterative
```

## Quick Reference Matrix

| Scenario | API | Timing | Example |
|----------|-----|--------|---------|
| Button tap | `.animation(.spring, value:)` | .snappy | Scale bump |
| Toggle switch | `withAnimation(.spring)` | .smooth | State flip |
| Modal appear | `.transition(.scale.opacity)` | .spring(0.3) | Popup |
| Sheet dismiss | `.transition(.move(.bottom))` | .spring(0.25) | Slide down |
| Pull refresh | `.interactiveSpring` | response: 0.3 | Gesture-driven |
| Loading spin | `.linear.repeatForever` | duration: 1 | Constant rotation |
| Success check | `PhaseAnimator` | 3 phases | Scale→bounce→settle |
| Confetti | `KeyframeAnimator` | Multi-track | Complex paths |
| Tab icon | `.symbolEffect(.bounce)` | default | SF Symbol bounce |
| Photo zoom | `.navigationTransition(.zoom)` | default | iOS 18 nav |
| Card expand | `matchedGeometryEffect` | .spring(0.5) | Hero transition |
