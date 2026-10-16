# Liquid Glass design adoption

Checked 2026-10-16 against Xcode 27.0 (27A266a), iPhoneOS 27 SDK. Use iOS 26 availability guards where needed. Standard navigation and controls adopt the system appearance when built with a supporting SDK; inspect custom appearance settings before changing them.

Keep glass in the navigation/control layer. Preserve a deliberate brand treatment and remove custom toolbar or sheet backgrounds only when restoring the system surface is part of the requested work. Ordinary content materials remain valid; avoid stacking a custom glass effect on an already-glass native control.

```swift
// iOS 26+
Button("Action") { }
    .buttonStyle(.glass)

Text("Label")
    .padding()
    .glassEffect(.regular.tint(.blue), in: Capsule())

ScrollView { Text("Content") }
    .scrollEdgeEffectStyle(.hard, for: .top)
```

Shapes belong in `glassEffect(_:in:)`; there is no `Glass.shape` or `Glass.prominence`. Use `.glassProminent` for a prominent native glass button. Put nearby custom glass in `GlassEffectContainer` and use a shared namespace plus stable `glassEffectID` values for morphing. Keep conditional morphing branches inside the container and animate their state change; disable nonessential motion with Reduce Motion.

`ToolbarSpacer(.fixed, placement: .primaryAction)` belongs directly inside `.toolbar`, not inside a `ToolbarItem`. Use `Tab(role: .search)` when a dedicated search tab suits the product. For background extension use `backgroundExtensionEffect()` when appropriate, not an assumed equivalence with `ignoresSafeArea`.

Verify light/dark and busy backgrounds, larger text, Reduce Transparency, Increase Contrast, VoiceOver and keyboard. Native adaptation helps but does not guarantee your custom content is readable or interactive.

Sources: [custom glass](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views), [adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass).
