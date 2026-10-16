---
name: iphone-duo-readiness
description: Prepare, audit, and verify SwiftUI or UIKit apps for iPhone Duo, including adaptive sizing, vertical bars, reserved regions, scene continuity, and actual display/fold transitions. Use for Duo compatibility work, not unrelated iOS styling changes.
license: MIT
---

# iPhone Duo Readiness

Help the existing app remain usable and recognizable across Duo configurations.
Preserve its product direction and minimum OS support. Compatibility work does
not imply adding sidebars, multiwindow features, camera accessories, or a separate
design for every pose.

## Sources and freshness

Release-status links rechecked **2026-10-16**: Apple’s hub currently lists
Xcode 27.1 Release Candidate for Duo. The symbol table records a historical
2026-09-26 inspection of Xcode 27.1 beta (27A9269); the current local Xcode 27.0
SDK cannot independently revalidate its iOS 27.1 declarations. Before implementing,
check the chosen 27.1 SDK and runtime. A higher Xcode version alone is not proof
of Duo support. See [Apple guidelines](references/apple-guidelines.md).

Read the reference relevant to the work:

- [Apple guidelines](references/apple-guidelines.md): design and engineering
  decisions, source links, capability requirements versus recommendations.
- [SDK reference](references/sdk-reference.md): verified symbol names,
  availability, and how to check declarations before implementing new APIs.
- [Verification](references/verification.md): runtime matrix, state-preservation
  checks, and simulator/tooling limitations.

## Workflow

1. **Establish the baseline.** Inspect repository instructions, dirty changes,
   app architecture, deployment target, and current verification evidence. Read
   effective build settings and the built plist, including launch screen, scene
   manifest, supported orientations, and full-screen preferences. Treat source
   plist absence as inconclusive when Xcode generates keys. Preserve current
   values until a scoped fix is justified.
2. **Audit actual assumptions.** Follow the requested screens and their
   presentation boundaries. Search for global screen/first-window access,
   layout branching by model/idiom/orientation, fixed canvas dimensions, mirrored
   safe-area insets, absolute overlays, stale cached geometry, and UI state that
   resets during layout changes. Interpret each occurrence; a rendering/export
   size, decorative overlay, or orientation-sensitive capture operation can be
   intentional. Don't blindly rewrite every match.
3. **Choose the smallest useful adaptation.** Use the decision guidance in the
   references. Adopt newer APIs only where an observed layout or interaction
   benefits. Check availability in the active SDK; gate newer code and preserve
   older-system fallbacks. Local SwiftUI/UIKit geometry is preferable to device
   classification. Present from the initiating view/scene rather than an
   arbitrary connected scene.
4. **Protect the ongoing task.** Keep selection, navigation, drafts, focus,
   presentation state, and custom-control values independent of transient
   geometry. Preserve durable data separately from restorable per-scene UI
   state. Recalculate layout when space changes without resetting the feature.
5. **Verify and report the evidence.** For implementation or runtime-verification
   requests, build affected targets/configurations and exercise the relevant
   behavior using the verification matrix. Keep read-only audits within their
   requested scope. Use one
   coordinated simulator session; do not let concurrent agents manipulate the
   same device. Record actual transitions and current test results, distinguish
   old results from new runs, and state any remaining gaps precisely.

## Completion standard

A successful build, a declaration in the SDK, or an orientation command alone
does not establish Duo layout or fold readiness. Confirm real layout changes and task continuity
on the active outer/inner displays and during folding before claiming that scope
is verified. If device controls fail, finish independent work and identify the
specific remaining interaction; don't replace missing evidence with a synthetic
screenshot, inactive display capture, or unrelated simulator run.

For a research-only request, deliver the findings without changing app code,
launching simulators, or making release configuration changes. For implementation,
stay within the user's authorized feature scope and follow repository preferences,
including numeric typography rules where provided.
