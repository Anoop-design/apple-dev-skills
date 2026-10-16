---
name: swiftui-modern
description: "Implement or refactor SwiftUI state, navigation, data flow, and framework-dependent behavior. Use when these decisions need guidance; simple text or styling edits need not load it."
license: MIT
---

# SwiftUI Implementation

Use the repository's deployment target, installed SDK, and existing architecture. Choose APIs compatible with that environment. Version-specific notes are reference material: verify availability and signatures against the installed SDK and current Apple documentation when adopting an unfamiliar or newer API. Do not upgrade the target or rewrite unrelated state management by default.

For the affected code, preserve stable view identity, keep view rendering inexpensive, and handle cancellation and accessibility where the change touches them. Apply the user's numeric typography preference to numeric UI.

## Read for the decision at hand

- [State and architecture](references/state-and-architecture.md): state ownership, Observation, bindings, dependency tracking, and view identity.
- [Performance](references/performance.md): expensive view updates, lists, and scrolling. Use `swiftui-performance-profiling` when measurement with Instruments is needed.
- [Data and SwiftData](references/data-and-swiftdata.md): SwiftData queries, persistence, and observation.
- [Newer API notes](references/whats-new-ios27.md): SDK-specific adoption or migration. Check each relevant claim against the actual toolchain.
- [Glass and design](references/liquid-glass-and-design.md): SwiftUI-facing material and chrome behavior.
- [Testing and accessibility](references/testing-and-accessibility.md): requested test work or relevant accessibility verification. Use the project's existing tools; do not add a test framework merely because it appears in an example.

For motion technique use `ios-animations-guide`; for UIKit/Core Animation use `core-animation-uikit`; for visual design use `swiftui-native-design`; for widgets use `swiftui-widgets`. Load those skills only when their workflow is needed.

Complete the requested behavior and relevant project checks. Read or test more when failures, shared-code effects, or unresolved compatibility questions justify it.
