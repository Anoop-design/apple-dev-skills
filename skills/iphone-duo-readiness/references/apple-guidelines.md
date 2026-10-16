# iPhone Duo: Apple guidance and implementation decisions

Design research dated **26 September 2026**; toolchain/distribution status refreshed **16 October 2026**. These are concise paraphrases of Apple sources,
with an independent SDK check and practical engineering interpretation. They
are not copied transcripts. **Capability** means a condition for a described
platform feature; **recommendation** means Apple's design/engineering advice;
**practice** means this skill's implementation or verification approach. None
should be turned into an App Store submission requirement without a current
submission-policy source.

## Current toolchain and beta limits

**Capability / dated fact, refreshed 2026-10-16.** Apple’s resource hub now lists
Xcode 27.1 Release Candidate. The 27.2 beta release notes still direct Duo
work to the 27.1 toolchain; select by actual SDK/runtime support rather than
version number alone. Use per-command `DEVELOPER_DIR` with multiple Xcodes.
[Duo resource hub](https://developer.apple.com/iphone-duo/),
[Xcode 27.2 release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-27_2-release-notes).

The 27.1 RC notes retain initial simulator startup delays, unavailable StandBy,
and unavailable execution/debugging of most app extensions in the Duo runtime.
They also describe Catalyst limitations for iOS 27.1-specific code and targets.
Check only the limits relevant to the app and recheck notes for newer builds.
[Xcode 27.1 release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-27_1-release-notes).

As of its 2026-10-05 update, App Store Connect accepts Xcode 27.1 RC builds for
App Store submission and TestFlight. Older beta-only distribution notes are
historical. Check current eligibility again before a release.
[App Store Connect release notes](https://developer.apple.com/help/app-store-connect/release-notes/).

## Preserve the same app across displays

**Recommendation.** Retain functionality, state, and information hierarchy
between displays. The extra space can expose an additional level of content,
such as list and detail together. Adapt using size classes and current available
space rather than hard-coded display widths. Make small fold adjustments that
keep related controls near their content. Standard components supply much of
the adaptation. Grids can benefit from even column counts when that divides
content naturally; don't blindly reshape a semantically meaningful grid.
Use system toolbar grouping rather than manual spacer widths. Keep the same
actions available when a bar overflows.
[Designing for iPhone Duo — HIG](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo).

The HIG was verified through its official
[DocC data](https://developer.apple.com/tutorials/data/design/human-interface-guidelines/designing-for-iphone-duo.json)
when the HTML page returned a JavaScript shell. Its recorded update is
9 September 2026. An unreadable page should not be reported as reviewed.

## Build prerequisites and configuration

**Submission requirement.** TN3208 says apps built with the iOS 27 SDK or later
must include a launch-screen configuration in the built plist: `UILaunchScreen`,
`UILaunchScreens`, `UILaunchStoryboardName`, or `UILaunchStoryboards`. An existing
valid configuration needs no replacement; Xcode can generate it for SwiftUI.
Check the build product rather than merely searching a source plist.
[TN3208: launch screens](https://developer.apple.com/documentation/technotes/tn3208-preparing-your-apps-launch-screen-to-meet-app-store-requirements).

**Recommendation / scope caution.** TN3192 covers iPad full-screen compatibility,
orientation support and resize migration. Its platform wording differs from the
Duo talk's description of compatibility behavior. Do not flatten these into a
universal claim that every full-screen preference is ignored on Duo. First
validate resizing, then deliberately migrate relevant settings while retaining
older-system support where needed. Verify the scene lifecycle actually used by
the app; a SwiftUI `App`/`WindowGroup` should not be mechanically rewritten into
a UIKit scene delegate.
[TN3192: iPad full-screen migration](https://developer.apple.com/documentation/technotes/tn3192-migrating-your-app-from-the-deprecated-uirequiresfullscreen-key),
[TN3187: UIKit scene lifecycle](https://developer.apple.com/documentation/technotes/tn3187-migrating-to-the-uikit-scene-based-life-cycle).

## Adaptive layout and safe areas

**Capability.** Existing binaries can run in compatibility layouts; building
with iOS 27.1 enables the demonstrated full-edge content and adaptive vertical
standard bars. This is not an instruction to raise the minimum deployment OS.

**Recommendation.** Outer display uses compact width; its height class changes
with orientation. Inner display uses regular width and height. Use these traits
and local geometry instead of treating an orientation mask as a layout boundary.
Read each safe-area inset and margin independently: controls can occupy either
side during multitasking. Keep interactive foreground clear and let background
artwork extend underneath system chrome. Prefer native navigation, tab and
presentation containers. Obtain a screen from the owning window scene only
when screen information is actually needed. Test open/close even with
`UIRequiresFullScreen` set; the flag does not prevent that resizing.
[Prepare your app for iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111461/).

**Practice.** Orientation compatibility/scaling behavior and newer resizability
rules vary by configuration. Inspect the effective settings and current runtime
rather than deleting orientation/full-screen keys as a mechanical migration.

## Vertical toolbars, tab bars and overflow

**Recommendation.** Use system navigation containers and bars. Provide both a
title and a suitable symbol for toolbar actions: compact presentation can use
the symbol, and overflow uses the title. Keep genuinely text-dependent controls
horizontal. Custom views should participate in vertical bars only if they have
a usable compact representation. Preserve logical action order and prioritize
frequent actions or important status when space is scarce. Let navigation-heavy
screens preserve destinations; task-focused screens may prioritize actions.
Consolidate secondary actions in the system overflow menu, reserving ellipsis
for that meaning. Opting out can suit some single-page or one-button-sheet
designs, but it is a contextual choice rather than a general fix.
[Raise the bar with iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111462/).

**Practice.** Verify the actual overflow menu with the keyboard and reduced
height, including action labels and enabled states. Don't recreate the system's
side rail with absolute positioning. Check current API spelling in the
[SDK reference](sdk-reference.md).

## Fold regions and arrangement views

**Recommendation.** Consider camera occlusions and the conditional fold
division region. Prefer natural content flow; move discrete related controls
together only when necessary. Continuous documents, feeds and scrolling lists
should retain continuity rather than being displaced around the fold. A grid
can widen its center gutter while preserving outside margins. Inactive region
information may help plan layout without creating a permanent empty strip.

Use a split arrangement when primary and secondary content must both remain
visible; use overlay when layered content can tolerate covering. Arrange content
inside the existing navigation hierarchy, not navigation infrastructure inside
an arrangement. Avoid arrangements inside scrolling containers. Query real
region geometry and active state instead of assuming a permanent crease width.
[Strike a pose with adaptive layouts on iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111463/).

**Practice.** `ArrangementView` is optional. A successful native container or
single-pane design does not need another wrapper solely because Duo exists.

## Positioning, poses and visual consistency

**Recommendation.** A tabletop layout is optional: it may separate display
content above from reachable controls below while retaining the feature set.
The system generally places bars at the side, with horizontal bars on the inner
portrait display. Center most foreground within the usable area rather than
the entire physical display. Immersive, non-scrolling content can use the full
width when it avoids system controls; artwork can bleed while text stays inset.
Native sheets and contextual presentations adapt their placement across poses.
[Design for iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111466/).

## Scenes, multiple instances and optional camera features

**Capability / recommendation.** Split View participation and support for creating
multiple app instances are different concerns. If the app supports multiple
scenes, handle unavailable activation requests on the outer display. Observe
availability for optional cross-display SceneAccessories. Hinge interaction APIs
are useful for interactive effects; use region/arrangement APIs for layout.
These features are not prerequisites for a normal single-scene app to resize.
[Leverage multiple displays and scenes on iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111464/).

**Optional camera work.** Apps that capture media should review virtual-front-
camera switching and capture-direction handling. The camera talk's example of
a view moving between displays does not prescribe a new scene architecture for
every app. Paired camera UI on both displays is a separate feature.
[Build a great camera experience for iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111465/).

**Practice, grounded in scene restoration guidance.** Keep per-scene navigation,
selection and restorable UI separate from the durable model. Use `SceneStorage`
only for appropriate small UI values; it is not guaranteed durable storage or
a place for sensitive data. A fold or resize should not clear a draft or reset
a selected date.
[Restoring your app's state with SwiftUI](https://developer.apple.com/documentation/swiftui/restoring-your-app-s-state-with-swiftui).

## Accessibility and input

**Recommendation.** Support Dynamic Type, readable contrast, meaningful labels,
adequate touch targets and alternatives to gesture-only operations. Keep motion
purposeful and respect Reduce Motion. Preserve standard keyboard navigation.
[Accessibility HIG](https://developer.apple.com/design/human-interface-guidelines/accessibility),
[Motion HIG](https://developer.apple.com/design/human-interface-guidelines/motion),
[Keyboards HIG](https://developer.apple.com/design/human-interface-guidelines/keyboards).

**Practice.** Test enlarged text, VoiceOver focus/order, software keyboard and
hardware keyboard in the actual configurations used by the feature. A target
can exist in the accessibility tree yet remain visually covered by an overlay;
combine interaction checks with screenshots. Adopt project-specific numeric
typography requirements without presenting them as Duo platform rules.

## Further official entry points

- [Preparing your app for iPhone Duo](https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo): maintained engineering overview; its article body could not be retrieved in this research, so no independent claims rely on it.
- [Apple Design Resources](https://developer.apple.com/design/resources/): current design kits and device templates; these are design references, not runtime layout constants.
- [Duo resource hub](https://developer.apple.com/iphone-duo/): refresh Tech Talks, labs, HIG links and tooling notices before future releases.
- [Design guidance updates](https://developer.apple.com/design/whats-new/): check for revisions after this document's research date.
