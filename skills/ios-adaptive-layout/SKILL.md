---
name: ios-adaptive-layout
description: Fix iPhone and iPad layouts that break with width, rotation, or resizing. Use for adaptive-layout audits, readable columns, short-height controls, and screenshot readiness in SwiftUI or UIKit apps.
license: MIT
---

# iOS Adaptive Layout

Adapt the existing app's design to the space its scene actually receives. Preserve the product's visual language, navigation, minimum OS support, and user data. This skill supports implementation and verification; it does not authorize publication or an unrelated redesign.

Read the [implementation and verification guide](references/adaptive-layout-guide.md) for a substantial cross-device pass. For a focused fix, read its relevant section: **Readable columns**, **Short height**, **Continuity**, **Testing**, or **Release evidence**.

## Working method

1. Establish the active checkout, repository instructions, dirty changes, shared components, supported OS versions, scheme, bundle IDs, and build-output location. Inspect effective build settings and built plist when configuration is generated. Reuse existing build caches and suitable simulators.
2. Inventory the requested journeys, including detail pages, forms, sheets, onboarding, editing, and sharing. Find global screen/window sizing, fixed heights, inconsistent page widths, independently aligned headings, and identity changes tied to geometry. Interpret matches before editing: fixed export canvases and intentional artwork dimensions may be correct.
3. Fix shared layout boundaries first. Put custom headings, body content, and related fixed controls on a common readable column. Keep the column centered and text naturally aligned within it. Respect native navigation titles and bar placement. Apply equivalent scroll-content margins to native List/Form rather than squeezing their entire hosts.
4. Use local scene/container geometry and current safe areas. Reflow at insufficient width or height, keep completion actions reachable, and support large text. Use the app's spacing and numeric typography conventions. Do not impose example measurements or artwork treatments on another app.
5. Preserve the ongoing task through resizing. Navigation, selection, drafts, focus, presented sheets, and control values should not reset because layout changes. Coordinate shared chrome with native transitions, including cancellation and Reduce Motion; don't patch timing with arbitrary delays.
6. Build and exercise the affected paths. Verify standard and accessibility type, small and large windows, supported rotation, and stateful transitions. Keep one UI driver per simulator and do not run UI manipulation against a device while its test runner is using it. Capture and inspect actual pixels, not only accessibility trees.
7. Deliver verified screenshots and a concise evidence report. Label each result passed, failed, or unverified, including device/runtime, SDK, configuration, data source, and relevant limits. Separate screenshot readiness, behavior verification, distribution-archive validation, and App Store submission readiness.

## Conditional workflows

- **Duo requested:** use the installed `iphone-duo-readiness` skill when available for current SDK/API guidance and real outer/inner/fold testing. If unavailable, verify current Apple documentation directly. A wide preview or rotation is not a fold test.
- **Release preparation requested:** verify current Apple distribution requirements and toolchain eligibility. Simulator behavior and a signed archive do not prove purchase, HealthKit, or physical-device behavior. Do not upload or submit merely to validate a layout change.
- **Screenshots need data:** use an existing isolated fixture or an explicitly authorized data source. Keep fixtures debug/simulator-only and out of production. Wait for repository bootstrap before exposing navigable sample cards. Do not erase onboarding or overwrite the user's data to simplify captures.
- **Tooling fails:** record the failed operation, distinguish it from an app defect, and finish independent code/build work. Try a bounded recovery and retain the gap rather than inventing passing evidence.

The companion guide includes a reusable test matrix and report template. Use the smallest matrix that covers the actual risks; no blanket redesign or exhaustive Cartesian product is required.

Technical review: 2026-10-16, Xcode 27.0 (27A266a), iPhoneOS 27.0 SDK. Preserve the active project’s minimum OS; this date is not a runtime certification. Use current [Apple documentation](https://developer.apple.com/documentation/) and [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/) for version-dependent decisions. Numeric UI uses tabular glyphs and stable field widths, preserving the chosen font’s letters.
