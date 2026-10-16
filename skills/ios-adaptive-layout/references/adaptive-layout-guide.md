# Adaptive iOS layouts: implementation and verification guide

A reusable playbook for existing SwiftUI and UIKit apps, distilled from practical iPad and iPhone adaptive-layout work. The objective is consistent, usable layouts across available sizes while preserving the app's identity and the user's current task.

This is engineering guidance, not Apple certification. The project observations below describe tested examples; they do not establish that every screen, device, or transition passed.

## Start with the app's constraints

Inspect repository instructions and the current checkout before editing. Record the scheme, configurations, minimum OS, phone/tablet support, bundle IDs, shared design system, build location, and existing uncommitted work. Preserve unrelated changes. Check whether app state and onboarding must survive updates.

Use the project's configured build cache. Select Xcode per command with `DEVELOPER_DIR` when several installations exist. Verify its actual version, SDKs, runtime availability, and complete installation; a filename or higher version number is not sufficient evidence. Discover device identifiers on the current machine rather than copying them from another project.

Inventory screens by layout family:

| Family | Typical failure to look for |
| --- | --- |
| Root dashboard and collection | Cards stretch too far; header has a different leading edge |
| Detail and long-form content | Hero title sits outside the body column; fixed overlays cover the last section |
| Native list or form | Narrow host distorts system chrome; custom rows use different margins |
| Sheet or editor | Content assumes full device width; keyboard hides the completion action |
| Onboarding | Fixed illustration and spacers leave no room for the button at short height |
| Sharing or poster preview | Minimum preview height consumes the space reserved for controls |
| Charts and maps | Cached global geometry becomes stale; selection disappears during resizing |

Follow the user's requested paths first. Search with `rg` for screen/window access, fixed frames, size-class/device branches, and custom overlays, then inspect their purpose. A fixed exported image size is not automatically a layout bug.

## Readable columns

### Center the content group, retain its internal alignment

A maximum width belongs to the page's content boundary. Apply it consistently to custom page headings, date rows, sections, charts, and controls that belong together. Individually centering each label produces ragged edges; a centered column containing leading-aligned text gives a stable reading edge.

Define a shared width token in the app's existing design system. Pick its value from the app's content and typography. One project used a 760-point outer page column and a narrower 520-point onboarding column; these are examples, not Apple requirements or universal defaults.

SwiftUI pattern, where the width includes page padding:

```swift
ScrollView {
    VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
        customHeader
        pageSections
    }
    .padding(.horizontal, Layout.pagePadding)
    .frame(maxWidth: Layout.readablePageWidth, alignment: .leading)
    .frame(maxWidth: .infinity, alignment: .center)
}
```

The first frame caps the column; the second centers it within the available width. Match modifier ordering to the token's definition. If padding is already applied elsewhere, do not apply it again. Avoid nesting several readable-width modifiers on the same content path.

For full-bleed artwork or a map, keep the visual canvas full width when appropriate and constrain its title/metadata overlay separately. The overlay and the following content should share the same reading edge. Do not constrain continuous backgrounds, native bars, or exports merely because body text is constrained.

Native navigation titles belong to the system's navigation layout. Do not reach into private bar subviews to force a title to match a custom column. If a custom hero heading is part of scroll content, align that heading with its body.

### Lists and forms

Keep a native List/Form host sized to its scene and adjust the scroll content, using APIs available at the deployment target. On a wide container, a useful starting calculation is:

```text
extra centering margin = max(0, (available width - readable outer width) / 2)
row content margin = extra centering margin + intended page padding
```

Measure in the correct local coordinate space and account for the container's existing safe-area/content margins. On compact widths, preserve appropriate native defaults instead of accidentally replacing them with zero. Verify section headers, separators, scroll indicators, and rows together. Do not mirror one edge's safe-area inset onto the other.

UIKit equivalents can use a constrained content view, layout margins/readable content guides, and scroll-view content/frame layout guides. Preserve the navigation and presentation controller's full scene-sized host.

## Short height and large text

Available height can shrink through rotation, resizing, a sheet detent, a keyboard, or folding. A width-only audit misses these failures.

- Derive preview sizes from both available width and height. Account for labels, format selectors, paging indicators, and other controls as well as the artwork.
- Keep a vertical scrolling fallback when content cannot fit. A smaller preview alone does not solve accessibility text growth.
- Prefer intrinsic or measured control sizes where practical. Treat any fixed reserved-height estimate as something to verify at large text sizes and with localization.
- Verify horizontal preview paging still works inside vertical scrolling. Gestures must not become mutually unusable.
- Let label/value groups stack at large text sizes; do not solve all overflow by shrinking text.
- Use native safe-area placement for fixed actions. Check the final scroll endpoint and the keyboard-present state.

Example preview-sizing idea, not a drop-in component:

```text
preview width = min(available width,
                    available height after controls × artwork aspect ratio)
```

Guard against nonpositive geometry and still allow scrolling. Export resolution is a separate concern: a small on-screen preview must not reduce the intended exported image quality.

Use the app's vertical rhythm and shared spacing. One project's 8/16/24-point grouping worked for its design; another app's established tokens take priority. Numeric UI should follow the tabular-numeral convention (`.monospacedDigit()` or the UIKit equivalent), with stable field widths for changing values. Keep letters in the chosen text font.

## Continuity

Read geometry from the view, scroll viewport, or initiating scene that owns the UI. Avoid selecting an arbitrary `connectedScenes.first` or key window for layout. Such code can use the wrong scene and does not track the active container reliably. Review export-only scale queries separately from layout measurements.

Keep navigation and editing state independent of geometry. Avoid recreating the feature with a new identity or independent models in compact/regular branches. Preserve:

- Selected tab, destination, list item, calendar day, and chart point.
- Draft text, focus, pending save, and retry state.
- Presented editor/share sheet and personalization choices.
- Gesture state and the settled result after interruption.

A viewport-driven expanded map or poster must update with its own container. Check that expansion itself does not change the geometry being used in a feedback loop. Verify expand, rotate/resize, collapse, and interrupted gestures with actual content.

Use native animated bar visibility and transition coordination. Verify push, Back, completed swipe-back, cancelled swipe-back, and Reduce Motion when changing shared chrome. A final screenshot cannot prove that no intermediate flash occurred. Avoid delayed appearance toggles, arbitrary sleeps, and private system-glass subview manipulation.

## Testing

Select representative high-risk flows, then broaden when failures or shared changes justify it. Do not claim all screens were tested after inspecting only the home page.

| Coverage | Task to exercise | Evidence |
| --- | --- | --- |
| Small iPhone portrait | Root → detail → Back | No clipping, working controls and correct navigation |
| Supported phone landscape | Share/editor plus scrolling | Controls remain reachable at short height |
| Small and large iPad | Root, detail, list/form, sheet | Common content edge and intentional width |
| Large Dynamic Type | Dense settings and key actions | Reflow without overlapping or clipped labels |
| Keyboard | Edit a draft, resize, finish/cancel | Field and completion actions remain accessible |
| State continuity | Select an item/value, resize, return | Same destination, draft, selection and presentation |
| Reduce Motion | Affected pushes, pops, expansions | Coherent visibility and settled state |
| VoiceOver | Focus, activate and navigate critical controls | Understandable labels, order and usable actions |
| Duo, when requested | Outer → inner → outer during a task | Actual display change and preserved state |
| Duo, when requested | Book/tabletop and both Split View sides | Per-edge layout and controls avoid reserved regions |

Use actual supported device models. “iPad mini” and “11-inch iPad” are different classes; don't silently label an 11-inch simulator as a mini. Choose the relevant small and medium/large tablet coverage from installed devices and clarify only if the distinction affects the user's requested deliverable.

For Duo SDK-specific behavior, consult the installed `iphone-duo-readiness` skill or current official Apple documentation. Verify symbol availability in the active SDK before adding new APIs, preserve older OS fallbacks, and adopt specialized arrangements only for an observed need.

One agent/tool driver should own a simulator at a time. Keep test-runner interaction separate from manual UI driving. Prefer a small active device set to reduce contention. Reacquire accessibility state after UI mutations; element identifiers may change. If a click did not change the intended state, don't mark the action passed.

### Fixtures and test isolation

Install Debug updates over the existing app when data preservation is required. Do not uninstall, reset onboarding, or touch the release app just to make testing easier.

For screenshot fixtures:

1. Isolate the data, preferably in memory or a dedicated test store.
2. Compile-gate fixture entry points to Debug and the intended test environment.
3. Finish repository seeding before showing cards that navigate by identifier.
4. Surface fixture preparation failures instead of swallowing them and showing broken destinations.
5. Avoid unrelated HealthKit/network waits when the fixture does not need them.
6. Label sample data in the evidence report. Do not represent it as the owner's actual history.

A review fixture exposed a race: root cards appeared before their repository records were ready, causing “Workout Not Found.” Gating the review root on bootstrap completion fixed that test path. This is a reusable diagnosis, not a reason to skip production authorization or fabricate production data.

### Evidence that does not establish a pass

A build establishes compilation. Accessibility text establishes exposed semantics, not visible geometry. A black capture of an inactive display establishes neither rendering nor usability. A generic wide preview or rotation is not a real fold. Hardware typing does not establish software-keyboard avoidance. Simulator purchases do not establish success in the final physical TestFlight build.

If tooling fails, record the exact operation and environment. Use a bounded recovery such as refreshing the UI connection or restoring the active display. Do not continually reset devices or reinterpret a tooling failure as a successful test. Complete independent checks and report what still needs a supported environment.

## Screenshots

Capture from the current active display and inspect the resulting file. Discover current display IDs rather than assuming `1` or `3` across machines. Keep raw captures and a simple manifest recording device, runtime, active display/pose, app configuration, data source, and observed result.

For an App Store screenshot request, verify current Apple pixel dimensions and asset rules, remove alpha only with an appropriate permitted image workflow if necessary, and ensure the images depict the distributable UI. A debug-fixture review pack is not automatically a submission asset set. Avoid claiming a pending render or placeholder is a finished screenshot.

Useful file naming: `device-screen-pose-textsize.png`. Group by device so baseline iPhone screenshots cannot be mistaken for Duo evidence. Package reviewed captures with the manifest when a portable handoff is useful.

## Release evidence

Keep these outcomes distinct:

1. **Layout implemented:** source changes address identified defects.
2. **Runtime verified:** named flows passed on recorded devices/configurations.
3. **Screenshot ready:** inspected images exist for the requested layouts.
4. **Archive validated:** the chosen distribution toolchain built the production configuration and its local signature/configuration checks passed.
5. **Submission ready:** required metadata/assets, physical critical flows, distribution eligibility, and outstanding product gates are resolved.

Check the built archive's bundle ID, version/build number, deployment target, device families, orientation declarations, privacy manifest, and absence of test catalogs or fixture entry paths. Generated plist keys may have `~iphone` or `~ipad` suffixes. A locally valid archive with an old/default build number is a validation artifact, not necessarily an upload candidate.

Verify current Apple SDK eligibility at the time of release. Checked 2026-10-16: Apple’s October 5 release notes allow Xcode 27.1 RC builds for the App Store and TestFlight. Earlier beta-only guidance is historical. See [App Store Connect release notes](https://developer.apple.com/help/app-store-connect/release-notes/). An archive built with one SDK does not inherit every native behavior observed in a different-SDK simulator build.

“Make ready” authorizes preparation within the task; it is not by itself a request to submit for review. Preserve the user's existing authorization and do not invent another approval requirement for routine local fixes.

## Handoff template

```markdown
# Adaptive-layout verification

Environment: checkout, scheme, configuration, Xcode/SDK/runtime, device IDs.
Data: production / preserved local data / isolated fixture.

Changes: identified problem, shared implementation, affected screens.

| Flow / configuration | Passed, failed, or unverified | Evidence / limitation |
| --- | --- | --- |

Tests: commands, result bundle, pass/failure counts, scope.
Screenshots: paths, devices/poses, inspection status.
Archive: path, toolchain, version/build, signature/configuration results.
Remaining gates: concrete missing evidence, required environment or owner action.
External actions: what was actually uploaded/submitted, if anything.
```

Report limitations prominently enough that the next agent cannot mistake a partial pass for full release approval. Preserve older evidence as historical, but put one current status section at the top instead of accumulating contradictory conclusions.

## Official references to recheck

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Designing for iPhone Duo](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo)
- [iPhone Duo developer resources](https://developer.apple.com/iphone-duo/)
- [Xcode release notes](https://developer.apple.com/documentation/xcode-release-notes)
- [App Store Connect release notes](https://developer.apple.com/help/app-store-connect/release-notes/)
- [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)

Use current official documentation and installed SDK declarations for version-dependent claims. This guide deliberately does not freeze beta command syntax, device identifiers, or submission policy.
