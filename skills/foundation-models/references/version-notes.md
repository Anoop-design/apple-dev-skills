# Version-specific Foundation Models APIs

Checked 2026-10-16 against Xcode 27.0 (27A266a), Swift 6.4, and the iOS 27 SDK. Availability below is per API, not the skill name.

The core session, tool, guided generation, and streaming APIs start at iOS/macOS/visionOS 26. The shipped iOS 27 SDK adds model abstraction and other features; adopt them only when the requested feature needs them.

| API | Verified availability / migration |
|---|---|
| `SystemLanguageModel.contextSize` | Back-deployed to iOS/macOS/visionOS 26.0 by the checked SDK; inspect runtime limits and reserve output space |
| `SystemLanguageModel.tokenCount(for:)` | iOS/macOS/visionOS 26.4 |
| `LanguageModel` / `LanguageModelExecutor` | iOS/macOS/visionOS/watchOS 27; implementations can have different capabilities and data flows |
| `PrivateCloudComputeLanguageModel` | iOS/macOS/visionOS 27; check its own availability, quota, and errors |
| `Attachment` image input | Version 27 additions; verify the particular attachment initializer and chosen model support |
| `LanguageModelSession.DynamicProfile` | Version 27; profile changes can change model, instructions, tools, and history handling |
| `LanguageModelSession.Response.usage` | Version 27; input/output counts and cached/reasoning subcounts |
| Mutable `session.transcript` | Version 27; never mutate while the session is responding |

A symbol's presence doesn't promise service eligibility, entitlement approval, a fixed quota, a fixed context size, a model-provider package, or universal hardware/region support. Check current official service requirements for the user's account and product before choosing cloud processing. Don't embed download thresholds, pricing promises, unverified model provenance, or parameter/RAM claims in an app design.

## Error migration

For iOS 27-only paths, handle `LanguageModelError` for shared generation failures such as `.contextSizeExceeded`, `.guardrailViolation`, `.unsupportedLanguageOrLocale`, and `.refusal`; handle model-specific errors separately. `LanguageModelSession.Error.concurrentRequests` and `.transcriptMutationWhileResponding` identify session misuse. Existing iOS 26 `GenerationError` handling remains relevant for older targets but is deprecated in the iOS 27 SDK. Keep a general catch path for future errors and cancellation.

## Tools and profile changes

A required tool-calling mode needs an explicit exit condition. Before allowing a profile to change providers, enforce the product's allowed data flow in code; conversation history and tool outputs can contain sensitive content. An agent prompt is not a substitute for that enforcement.

Do not add built-in OCR/search tools, third-party providers, or an evaluation framework based on a guessed type name. Inspect the current framework/module/package and deployment requirements, then compile a minimal integration. For precise image extraction, Vision remains available independently of a generative model.

Official sources: [Foundation Models](https://developer.apple.com/documentation/foundationmodels), [PrivateCloudComputeLanguageModel](https://developer.apple.com/documentation/foundationmodels/privatecloudcomputelanguagemodel), [LanguageModelError](https://developer.apple.com/documentation/foundationmodels/languagemodelerror), [DynamicProfile](https://developer.apple.com/documentation/foundationmodels/languagemodelsession/dynamicprofile).
