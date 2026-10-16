---
name: ios-polished-apps
description: "Review an iOS app or feature for release readiness, accessibility, and native polish. Use for an explicit quality audit or pre-release review, not every implementation task."
license: MIT
---

# iOS Release Readiness

Review the requested app, feature, or release candidate against its supported platforms and acceptance criteria. When fixes are requested, implement and verify them; a review-only request ends with actionable findings.

Read only the relevant checklist:

- [App Store review checklist](references/review-checklist.md): submission readiness, permissions, required product behavior, and metadata. Verify current Apple requirements before relying on a policy claim.
- [Performance checklist](references/performance-checklist.md): a requested performance or pre-release assessment. Use `swiftui-performance-profiling` when diagnosis needs Instruments measurements.
- [HIG patterns](references/hig-patterns.md): native navigation, controls, and interactions. Use `swiftui-native-design` for a visual design task.

Assess the relevant user journeys, including loading, empty, error, Dynamic Type, VoiceOver, and reduced-motion states. Scope device and state coverage to the feature and supported deployment targets. Do not turn a focused review into unrelated redesign, dependency migration, or deployment work.

Base findings on observed behavior, code, or current requirements. Distinguish defects from optional improvements and unverified concerns. Report evidence and impact, and rerun affected checks after a fix; repeat broader checks only when necessary.

Technical review: 2026-10-16, Xcode 27.0 (27A266a), iPhoneOS 27.0 SDK. Preserve the active project’s minimum OS; this date is not a runtime certification. Use current [Apple documentation](https://developer.apple.com/documentation/) and [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/) for version-dependent decisions. Numeric UI uses tabular glyphs and stable field widths, preserving the chosen font’s letters.
