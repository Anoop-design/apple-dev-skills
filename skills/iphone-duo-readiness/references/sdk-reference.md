# Verified API reference

Inspected **2026-09-26**, Xcode **27.1 beta (27A9269)**, iPhoneOS 27.1 SDK.
Publication review 2026-10-16 used local Xcode 27.0, which cannot revalidate
the 27.1-only symbols below. This table preserves the earlier declaration
inspection, not a new compiler or runtime pass. Recheck the active SDK before
implementing; API availability varies across overloads and platforms.

## Find the actual declarations

Select the intended Xcode with `DEVELOPER_DIR`, then run:

```sh
xcrun --sdk iphoneos --show-sdk-path
```

The paths below are relative to the returned SDK root:

- `System/Library/Frameworks/SwiftUICore.framework/Modules/SwiftUICore.swiftmodule/arm64e-apple-ios.swiftinterface`
- `System/Library/Frameworks/SwiftUI.framework/Modules/SwiftUI.swiftmodule/arm64e-apple-ios.swiftinterface`
- `System/Library/Frameworks/UIKit.framework/Modules/UIKit.swiftmodule/arm64e-apple-ios.swiftinterface`
- `System/Library/Frameworks/UIKit.framework/Headers/`

Search symbols with `rg`; read the enclosing extension/type availability too.
`@_originallyDefinedIn` records movement between modules, not introduction on
that OS. Objective-C methods marked `NS_REFINED_FOR_SWIFT` may have a different
Swift interface. Transcript pseudocode is not a substitute for declarations.

## SwiftUI geometry and arrangements

| API | Verified iOS availability and details |
| --- | --- |
| `GeometryProxy.reservedRegions(kind:options:layoutDirectionBehavior:)` | 27.1. Returns `[ReservedRegion]`; options default to `[]`, layout direction behavior to `.mirrors`. |
| `ReservedRegion` | 27.1. `id`, `kind`, `frame`, `margins`, `isActive`; kinds `.occlusion` and `.division`; query option `.includeInactive`. |
| `ArrangementView<Primary, Secondary>` | 27.1. `init(primary:secondary:)` content closures and `arrangementViewStyle(_:)`. Built-in styles include `.automatic`, `.split`, `.overlay`. |
| `GeometryReader`, `GeometryProxy.size` / `safeAreaInsets` | 13.0. Ordinary adaptive geometry does not require raising the deployment target to 27.1. |
| `containerRelativeFrame` | 17.0. Use the relevant container rather than an assumed physical screen. |
| `onGeometryChange(for:of:action:)`, new-value action | 16.0. The one-argument action overload is back-deployable. |
| `onGeometryChange(for:of:action:)`, old/new-value action | 18.0. Do not substitute it into a lower-target code path without gating. |

Declaration anchors in the inspected SwiftUICore interface: `ReservedRegion`
near lines 4842–4899; geometry observation 7831–7849; region query 10273–10315;
`ArrangementView` 16651–16722. Line numbers will change with SDK updates.

For new region/arrangement code, use an iOS 27.1 availability branch with an
existing adaptive fallback for older systems. Convert coordinates explicitly
when moving geometry between views. Inspect active regions in the live
configuration; declarations do not establish region dimensions or prove that
an arrangement style suits a particular product.

## SwiftUI bars

| API | Verified iOS availability and details |
| --- | --- |
| `EnvironmentValues.toolbarVerticalEdge` | 27.1; `HorizontalEdge?`. |
| `ToolbarContent.axisBehavior(_:)` and customizable equivalent | 27.1; `ToolbarItemAxisBehavior` includes `.automatic`, `.horizontalOnly`, `.verticalPreferred`. |
| `ToolbarOverflowMenu`, `View.toolbarOverflowMenu(content:)` | 27.0. Available before the 27.1 Duo-specific axis additions. |
| `ToolbarContent.visibilityPriority(_:)` | 27.0; supports the declared `ToolbarItemVisibilityPriority` values. |

Declaration anchors: SwiftUICore 2548–2552; SwiftUI 17424–17452 (axis),
31125–31160 (overflow), 12892–12934 (priority). Platform availability differs;
read guards before sharing code with Catalyst or other Apple platforms.

## UIKit

| API | Verified iOS availability and details |
| --- | --- |
| `UIView.reservedRegions(kind:options:)` | 27.1. Returns `[UIView.ReservedRegion]`; default options `[]`. The Swift label is `kind:`, not a guessed `ofKind:`. |
| `UIArrangementViewController` | 27.1. Swift surface includes `updateArrangement(_:animated:)`, `state(for:)`, and `setViewController(_:for:animated:)`; placements `.primary` / `.secondary`. |
| `UISplitArrangement`, `UIOverlayArrangement` | 27.1 arrangement implementations. View state includes `zIndex`, `splitAxis`, `isHidden`. |
| `UIWindowScene.effectiveGeometry` | 16.0. Individual geometry members have their own availability. |
| `UIWindowSceneGeometry.coordinateSpace`, `isInteractivelyResizing` | 26.0. |
| `windowScene(_:didUpdateEffectiveGeometry:)` | 26.0. Callback argument is previous geometry; current geometry comes from `windowScene.effectiveGeometry`. |
| `UIWindowScene.displayLink(target:selector:)` | 27.0. Header specifies automatic retargeting when the scene changes displays. Relevant when custom display-linked animation needs scene association. |

Anchors: UIKit Swift interface 1973–2010 and 6075–6133; headers `UIView.h`,
`UIArrangementViewController.h`, `UIWindowScene.h`, `UIWindowSceneGeometry.h`.
The old scene geometry callback and scene `coordinateSpace`/`interfaceOrientation`
properties carry replacement guidance in the headers.

For expensive work such as re-rendering assets, compare relevant geometry and
avoid repeating it unnecessarily during interactive resizing. Keep ordinary
layout responsive. A resize callback is not a reason to rebuild the data model.

## Modernization precision

Optional cross-display APIs need separate guards too. SwiftUI `sceneAccessory`
and UIKit scene-accessory registration begin on iOS 27.0 and are unavailable on
Mac Catalyst and the other Apple platforms listed in those declarations.
SwiftUI `onHingeChange` / `DeviceHinge` and UIKit `UIHingeInteraction` begin at
27.1; check platform-specific availability before sharing that code. These are
optional feature APIs, not a reason to raise the app's minimum deployment OS.

Avoid `UIScreen.main` and arbitrary first-scene/window lookups for view layout
or presentation. Use local view/scene ownership. Distinguish deprecated APIs
from discouraged design assumptions: `UIDevice.userInterfaceIdiom` is not
equivalent to the deprecated legacy macro, but either is a poor proxy for
available layout space. An orientation needed for camera capture is a different
problem from an orientation used to pick a content column count.

Apple's exported App Resizability skill is useful as an audit aid. Its presence
does not replace SDK verification or demonstrate that the app actually works
on the inner display. Apply modernization advice with the surrounding code's
intent and the user's scope intact.
