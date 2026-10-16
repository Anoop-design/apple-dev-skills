---
name: swiftui-widgets
description: "Build or fix WidgetKit widgets and Live Activities: timelines, configuration, shared data, rendering, and updates. Use the version-specific widget skill only for newer SDK adoption or migration."
license: MIT
---

# WidgetKit and Live Activities

Implement the requested widget behavior using the existing deployment target, data store, and configuration model. Widgets render snapshots in a system-managed process; they don't run as a continuously active mini-app. Timeline dates and reload requests are scheduling requests, not exact timers.

Read only the relevant reference:

- [Timelines and configuration](references/timelines-and-configuration.md): providers, reload policy, shared data, App Intents, and links.
- [Widget families](references/widget-families.md): platform availability, sizing, and background behavior.
- [Widget design](references/widget-design.md): rendering modes, dates, accessibility, and stable numeric layout.
- [Live Activities](references/live-activities.md): ActivityKit lifecycle, interactivity, and remote updates.
- [iOS 26 features](references/ios26-features.md): widget push tokens, CarPlay, spatial widgets, and relevance.

For iOS 27-specific adoption, the optional `swiftui-widgets-ios27` skill adds verified migration notes. App Intents details beyond widget integration belong to the optional `app-intents-siri` skill. The references here are sufficient for ordinary widget work without installing companions.

Keep shared writes persistent and safe across processes; an in-memory app singleton isn't shared with an extension. Handle missing data, stale results, configuration changes, and unavailable account state. Use `.monospacedDigit()` for numeric text and reserve enough width for changing values.

Build the affected app and extension targets. Verify relevant families/rendering modes and actual reload or interaction behavior; a successful preview doesn't establish background scheduling or APNs delivery. Scope broader device testing to the platforms and surfaces the feature supports.
