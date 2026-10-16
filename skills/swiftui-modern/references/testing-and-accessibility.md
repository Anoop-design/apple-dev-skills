# Testing and accessibility

Checked 2026-10-16 against Xcode 27.0 (27A266a), Swift 6.4, and the iOS 27 SDK. Availability below is per API, not the skill name.

Verify observable behavior relevant to the change using the project's existing tools. Logic and persistence tests are usually cheaper and more stable than view-tree inspection. Swift Testing supports ordinary unit tests; XCTest remains supported and is used for UI automation. Don't migrate a test suite or add third-party reflection/snapshot packages to make a small change.

Use parameterized tests for meaningful input cases. For async UI-owned models, respect actor isolation and control time/dependencies where possible. A test that merely repeats the implementation does not establish correctness.

For snapshots already in the project, fix simulator/runtime, locale, time, data, appearance, and text size. Review changed baselines instead of automatically accepting them. Add visual verification when the affected layout or interaction warrants it, not as a mandatory full-device matrix for every edit.

Use built-in controls for their accessibility and interaction semantics. An icon-only button needs a meaningful label. Adding an `isButton` trait to a tap gesture is not a complete substitute for a button's keyboard, focus, and activation behavior. Test grouping and actual reading order; don't assume source declaration order always determines VoiceOver traversal.

Support useful Dynamic Type sizes without clipped primary content. Avoid color-only status. Respect Reduce Motion for nonessential movement and test increased contrast when color/materials change. For iOS touch interfaces, aim for the platform's 44-by-44-point target guidance, adapting to the actual platform and context.

`XCUIApplication.performAccessibilityAudit()` (iOS 17+) can detect several issues, but automatic checks do not replace reading order, focus, and VoiceOver verification. Use Accessibility Inspector and a real assistive-technology pass where the change affects those behaviors. This engineering guidance makes no blanket legal-compliance or penalty claim.

Official sources: [Swift Testing](https://developer.apple.com/documentation/testing), [UI testing](https://developer.apple.com/documentation/xctest/user-interface-tests), [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility), [performAccessibilityAudit](https://developer.apple.com/documentation/xctest/xcuiapplication/performaccessibilityaudit(for:_:)).
