---
name: foundation-models
description: "Implement Apple Foundation Models sessions, structured generation, streaming, and tool calling. Use for app language-model features; verify SDK-specific providers and capabilities before adoption."
license: MIT
---

# Foundation Models

Work within the project's installed SDK, deployment target, and intended privacy/data-flow design. Check model availability and handle cancellation, generation failures, and unavailable states relevant to the feature. Do not add cloud processing, change providers, or raise deployment targets merely to follow an example.

## Read for the requested feature

- [Session and API patterns](references/foundation-models-api.md): model availability, sessions, streaming, and tool calls.
- [Guided generation](references/guided-generation-patterns.md): structured outputs and schema patterns.
- [Prompting and adapters](references/foundation-models-guide.md): specialized prompting and adapter guidance.
- [Testing strategies](references/testing-strategies.md): representative inputs and device-dependent behavior.
- [Version notes](references/version-notes.md): verified SDK availability and error migration; check current service requirements when changing model providers.

Read only what the task needs. The linked references are bundled with this skill, so it can be installed independently.

Check current official Apple documentation for unfamiliar or version-sensitive symbols, availability, entitlements, and service limits. Use output quality examples and affected integration checks to verify the requested behavior. Do not impose a new evaluation framework or CI pipeline on a small change unless the task requires it.
