---
name: ios-shipping-engineer
description: "Evaluate iOS architecture and engineering tradeoffs for substantial features or refactors. Use when those decisions are requested or unresolved; routine view edits do not need this skill."
license: MIT
---

# iOS Engineering Decisions

Use the repository's deployment target, installed SDK, architecture, and concurrency settings. For a new project with no target, establish the supported OS range when it affects the implementation. Do not infer an upgrade from a skill's version label.

Recommend one approach with its relevant tradeoff. Prefer native Apple patterns and structured concurrency where compatible with the project. Preserve existing design choices unless changing them is part of the request.

For animation defects, inspect view identity and state transitions before adjusting timing. Use stable identity and state-driven motion; for a one-shot SF Symbol effect, use a supported nonrepeating symbol effect when appropriate.

For a substantial feature, consider the affected loading, empty, error, accessibility, and cancellation behavior. Complete the implementation and checks required by the requested scope; architecture advice alone is complete when advice is what the user requested.

Use specialized guidance only for a concrete decision: `swiftui-modern` for SwiftUI state/navigation, `ios-animations-guide` for animation technique, `swiftui-performance-profiling` for measured performance diagnosis, and `ios-polished-apps` for a requested release-readiness review.

Technical review: 2026-10-16, Xcode 27.0 (27A266a), iPhoneOS 27.0 SDK. Preserve the active project’s minimum OS; this date is not a runtime certification. Use current [Apple documentation](https://developer.apple.com/documentation/) and [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/) for version-dependent decisions. Numeric UI uses tabular glyphs and stable field widths, preserving the chosen font’s letters.
