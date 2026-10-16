# Task-sized verification workflows

Checked 2026-10-16 against Xcode 27.0 (27A266a), Swift 6.4, and the iOS 27 SDK. Availability below is per API, not the skill name.

## Implementation

Read the affected code, repository instructions, and project configuration. For a substantial change, organize the work around the observable behavior and checks that can demonstrate it. Existing authorization covers routine implementation and fixes; don't insert a mandatory approval stage solely because an IDE offers a planning mode.

Build the affected target using available Xcode tools or the established CLI. Inspect errors and warnings introduced by the change. Run the relevant tests once the implementation is ready; broaden only for shared-code risk, failures, or required repository checks. Don't add tests that merely mirror trivial edits.

For UI changes, inspect a preview or running view in the relevant size/appearance. For interaction or lifecycle behavior, exercise the actual flow in a supported simulator/device when available. A preview cannot prove camera permission, purchase handling, background scheduling, or an APNs integration.

Report the changed behavior, verification performed, and any limitation. Distinguish a successful typecheck, build, unit test, visual check, and device run; they establish different things.

## Crash diagnosis

Use the supplied or accessible crash report, symbolication, build version, and reproduction. Locate the failing path and form a concrete hypothesis before editing. If Organizer access isn't available through tools, use an existing exported report or another supported read path. Don't invent crash evidence.

Verify the fix against a meaningful reproduction or regression test. Stop repeated attempts when the environment is the blocker and report the missing input or capability.

## Localization and design

Use the app's existing String Catalogs and requested locales. Preserve format specifiers, plural rules, accessibility text, and comments. Review the affected layouts with representative long strings; a full-project translation is outside a focused text fix.

For visual implementation, match the supplied design while retaining appropriate platform behavior. Use available previews or screenshots as evidence and iterate only on observed differences. Do not install a design connector, change global agent settings, or rewrite the architecture just to follow this workflow.

Official sources: [Xcode testing](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode), [Previews](https://developer.apple.com/documentation/xcode/previewing-your-apps-interface), [String Catalogs](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog).
