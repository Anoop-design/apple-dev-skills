---
name: swiftui-widgets-ios27
description: "Adopt or migrate iOS 27-specific WidgetKit and Live Activity behavior. Use when that SDK behavior is part of the task; ordinary widget work belongs to swiftui-widgets."
license: MIT
---

# WidgetKit SDK Adoption

Identify the project's installed SDK, deployment targets, widget families, and the specific new behavior requested. A skill name or newer reference does not authorize raising the minimum OS version.

Use [version notes](references/ios27-notes.md) selectively: search for the feature, such as family sizing, rendering, App Intent execution, Dynamic Island, or migration. The notes record verified SDK availability. Recheck current service behavior and compile the specific integration when adopting a feature.

For general timelines, configuration, shared data, or Live Activity basics, use the optional `swiftui-widgets` skill or the official WidgetKit documentation. For App Intents framework details, use `app-intents-siri`. For layout guidance, use `swiftui-native-design` and the official widget-family documentation.

Implement the requested behavior with availability handling for supported targets. Verify the affected families and states, including numeric stability where values change. A focused SDK adoption task does not require migrating every widget or reviewing unrelated app features.
