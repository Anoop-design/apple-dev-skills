# Release audit

Reviewed October 16, 2026 for the initial public `apple-dev-skills` collection.

## Scope and result

The collection contains **23 custom Apple development skills** with their bundled references and MIT license notices. Review covered every included skill's entrypoint and supporting material, with focused SDK inspection and compiler probes for consequential API and concurrency changes. Private component-library guidance, third-party plugin skills, and Apple's exported skills are excluded; see [provenance](PROVENANCE.md).

The reviewed toolchain is **Xcode 27.0 (27A266a), Swift 6.4, iOS 27.0 SDK**. Newer APIs retain availability conditions. Examples are guidance for integration into a real project, not a claim that every Markdown fragment is an independently buildable program.

## Technical corrections

| Area | Corrections and verification |
| --- | --- |
| Camera | Authorization precedes startup; configuration and start/stop share one serialized owner; partial configuration rolls back; capture state lives through terminal callbacks. Corrected dimensions, rotation, deferred-photo handling, pressure observation, and capability checks. A Swift 6 probe typechecks at an iOS 17 deployment target. |
| SwiftUI and UIKit | Corrected Liquid Glass, toolbar, scroll-edge, animation, keyframe, and layer APIs. Removed a layer hierarchy cycle and broad rasterization recommendations. Preserved tabular numeric glyphs and stable widths. A representative UI probe typechecks at an iOS 15 deployment target with newer APIs availability-gated. |
| App Intents | Corrected entity collection labels, execution targets, asynchronous queries, value representations, and version availability. Narrowed mandatory adoption language to requested integrations. |
| HealthKit | Corrected medication availability, read/write authorization semantics, workout route typing, and privacy guidance. Empty reads are not evidence that permission was denied. |
| CloudKit | Corrected encryption claims, supported Simulator notifications, account handling, sharing and synchronization guidance. Encryption guarantees depend on the documented configuration; `encryptedValues` alone is not a blanket promise of end-to-end encryption. |
| StoreKit and MapKit | Corrected API examples, optional subscription information, offer redemption, refund/revocation handling, and current map integration guidance. Removed time-sensitive commercial or regional snapshots in favor of primary-source checks. |
| Foundation Models and system AI | Corrected response/tool/error APIs, request serialization, structured generation, Image Playground signatures, and unsupported capability assumptions. Consolidated Foundation Models references under their own skill. |
| Widgets | Corrected push-handler APIs, timelines, rendering, and version-specific behavior. Reload requests are not exact scheduling guarantees. |
| Xcode | Replaced remembered tool contracts with discovery of installed schemas; corrected skill-export syntax and removed broad global setup or exhaustive verification mandates. |
| Skill structure | Shortened oversized entrypoints and linked detailed references. Removed hidden cross-folder dependencies and narrowed activation to the task. Preserved the user's architecture, deployment targets, and visual direction. |

Consequential claims link to Apple documentation within the affected references. Compiler probes are in [tests/swift](../tests/swift). The [source manifest](source-manifest.json) records original hashes and release-copy changes, including consolidation and deletions.

## Reproducible checks

```sh
python3 -m venv .venv
.venv/bin/python -m pip install -r requirements-dev.txt
.venv/bin/python scripts/validate.py
.venv/bin/python -m unittest discover -s tests -v

# macOS with Xcode 27+ selected
python3 scripts/check_swift.py
```

The release checks passed:

- All 23 skills pass metadata, matching license, directory-name, and standalone local-reference checks.
- Installer/validator regression tests cover collisions, rollback after a failed copy, dry runs, missing files, symlinks, path traversal, and cross-skill dependencies.
- A complete installation of all 23 folders into a temporary destination matched the source bytes.
- `AIAndWidgets.swift`, `Camera.swift`, `Frameworks.swift`, and `UI.swift` typecheck with Swift 6 and warnings treated as errors. The compiler script records its toolchain and deployment targets when run.
- A heuristic release-content scan found no personal absolute paths, private keys, or common credential-shaped strings. This is a limited scan, not a security certification.

GitHub Actions repeats the portable packaging and Python regression checks. Swift checks are local because they require the selected Apple SDK and compiler plugins.

Routing walkthroughs covered structured note extraction, editor image creation, OCR, a stale widget, SwiftUI state ownership, glass with an older deployment target, interrupted layer animation, a growing numeric badge, and building without connected Xcode tools. These checked that the entrypoints direct the agent to relevant guidance without requiring unrelated migrations or setup; they were review walkthroughs, not full app evaluations.

## Runtime and environment limits

No end-to-end app or physical-device testing was performed for this collection. Camera hardware, HealthKit authorization/workouts, StoreKit transactions, CloudKit synchronization/sharing, model availability/output quality, widget scheduling/APNs, VoiceOver interaction, and visual rendering must be checked in the consuming app.

The Metal recipe probe is included as `tests/swift/UIShaders.metal`, but the installed Xcode lacks the optional Metal Toolchain, so it was not compiled. With that component installed, run `python3 scripts/check_swift.py --metal`. Swift shader-call signatures were typechecked; that does not validate GPU output or sampling bounds visually.

Duo-specific 27.1 guidance includes primary-source checks, but this review used the available 27.0 SDK and did not run a physical fold/display transition or compile a complete 27.1 integration. References label that evidence boundary. No unsupported beta claim is treated as a completed device test.

External sources were checked selectively for technical corrections; the validation script does not crawl every URL. App Store policy, regional availability, service limits, and future SDK changes require current-source verification when used.

## Coverage

Coverage is strongest in iOS, iPadOS, SwiftUI, UIKit animation, and shared Apple frameworks. macOS, watchOS, tvOS, and visionOS are covered where the included frameworks apply; this is not a complete platform handbook. Dedicated AppKit/macOS distribution, Swift concurrency, testing, localization, and standalone watchOS/visionOS workflows are future additions rather than prerequisites for this release.
