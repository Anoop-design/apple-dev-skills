# Families, layout, and platform support

Checked 2026-10-16 against Xcode 27.0 (27A266a), Swift 6.4, and the iOS 27 SDK. Availability below is per API, not the skill name.

Use `context.displaySize`, the actual view proposal, and the `widgetFamily` environment. Sizes vary by device, display settings, location, and OS; don't hardcode tables of point dimensions as a contract.

| Family | Typical supported surface |
|---|---|
| `systemSmall`, `systemMedium`, `systemLarge` | iOS/iPadOS Home Screen and macOS widgets; other surfaces depend on platform/version |
| `systemExtraLarge` | Larger supported surfaces including iPad and macOS; not “iPad only” |
| `systemExtraLargePortrait` | iOS/macOS 27 and visionOS 26; gate when supporting older OS versions |
| `accessoryCircular`, `accessoryRectangular` | iOS Lock Screen and supported watch complications/Smart Stack contexts |
| `accessoryInline` | The inline Lock Screen area above the clock and supported watch complications |
| `accessoryCorner` | watchOS only; don't include in an unguarded iOS switch |

Circular and rectangular iPhone Lock Screen widgets are generally below the clock, unlike inline widgets. Family availability differs by platform even when the names match. Compile shared switches under platform guards and use a default branch for future values.

Build a useful layout for each supported family. Smaller families need less content, not just scaled-down large views. Use adaptive stacks/grids and test long localized strings and relevant Dynamic Type sizes. Avoid an arbitrary universal 20-character or 16-point inset rule.

## Backgrounds and margins

On supported targets, identify a widget's background with `containerBackground(for: .widget)` so the system can remove or adapt it. This is important for supported locations; an “Unable to Load” error can also have many other causes, including crashes, invalid data, entitlement problems, and excessive resources.

Read `showsWidgetContainerBackground` when foreground styling needs to adapt. Standard content margins already apply; don't add `widgetContentMargins` a second time unless deliberately replacing the defaults with `contentMarginsDisabled()`.

`containerBackgroundRemovable(false)` affects eligible placements and should reflect a real content need. It is not a universal way to force a background on every surface. Use `disfavoredLocations` only when a supported location cannot provide a useful experience.

For CarPlay and StandBy, verify readability and behavior in that environment; no single Home Screen preview covers them. Spatial mounting/texture modifiers describe visionOS presentation even where iOS availability permits configuration for an iPhone widget.

Official sources: [WidgetFamily](https://developer.apple.com/documentation/widgetkit/widgetfamily), [Preparing widgets for additional platforms, contexts, and appearances](https://developer.apple.com/documentation/widgetkit/preparing-widgets-for-additional-platforms-contexts-and-appearances), [Widgets HIG](https://developer.apple.com/design/human-interface-guidelines/widgets).
