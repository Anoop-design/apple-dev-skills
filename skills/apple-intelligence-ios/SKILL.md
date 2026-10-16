---
name: apple-intelligence-ios
description: "Integrate Apple Intelligence system UI: Image Playground, Writing Tools, and Genmoji. Use foundation-models for language-model sessions and app-intents-siri for Siri integration."
license: MIT
---

# Apple Intelligence System UI

Integrate the requested Image Playground, Writing Tools, or Genmoji experience using supported APIs and the app's existing design. Respect feature availability, user consent for inputs, and an appropriate unavailable state.

Read the relevant section of [system UI examples](references/system-ai-ui.md). Consult [testing strategies](references/testing-strategies.md) when platform or device behavior needs verification. Check exact signatures and availability against the installed SDK and current Apple documentation when adopting a feature.

If available, use the `foundation-models` skill for language-model sessions, structured output, streaming, or model tool calls. Use the optional `app-intents-siri` skill for Siri, Shortcuts, and App Intents. Use `apple-intelligence-ml` for Core ML, Vision, Natural Language, or Speech. Do not load all of them for a single framework integration.


Verify the affected success, cancellation, and unavailable states. Do not add a cloud fallback or transmit private content merely because the on-device feature is unavailable; that product and data-flow decision must follow the requested design.
