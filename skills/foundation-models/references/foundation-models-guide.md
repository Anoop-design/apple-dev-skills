# Prompting and model adaptation

Checked 2026-10-16 against Xcode 27.0 (27A266a), Swift 6.4, and the iOS 27 SDK. Availability below is per API, not the skill name.

Use the selected model for bounded tasks that can be evaluated: extraction from supplied material, classification, summarization, and short generation. Provide the relevant source content; don't rely on an on-device model for current facts. Test the specific language and task rather than assuming broad world knowledge.

- Put stable app behavior in session instructions. Put user input and retrieved material in prompts or tool results. Instructions do not enforce permissions or protect secrets.
- Explain the desired output and relevant constraints succinctly. If the app needs structured fields, use guided generation instead of increasingly complicated formatting prompts.
- Reuse a session for related turns. Use separate sessions for unrelated work so stale context does not influence new results.
- Splitting work can improve a difficult prompt, but each stage adds latency and tokens. Compare output quality with the simpler version before adding a pipeline.
- Tool output should be bounded and relevant. Retrieve a small result set instead of dumping a database into the transcript.
- A summary used to restart a conversation is lossy and untrusted model output. Retain authoritative records separately; never turn a generated summary into permissions or secret-bearing instructions.

## Adapters

Consider a custom adapter only when measured task quality requires it and the current Apple program, entitlement, training assets, and deployment rules fit the app. The adapter must match a compatible system base model. Track version compatibility and a usable unavailable path.

The legacy iOS 26 surface used `SystemLanguageModel.Adapter` and the corresponding model initializer. The checked SDK marks that adapter surface deprecated in 26.4 and **obsoleted in 27.0**; do not recommend it for new version-27 deployments. `LanguageModelSession(adapter: URL)` is not an API. Consult current Apple training/deployment guidance for any supported replacement before investing in a pipeline. Prompting and tools may solve the task with less maintenance. Do not add training or remote model delivery to an ordinary prompt fix.

On-device execution describes the selected model's inference. App tools, analytics, downloaded resources, or a different provider may still send data off-device. Document the actual data flow rather than claiming the entire feature is automatically private.

Official sources: [Generating content and performing tasks](https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models), [Expanding generation with tool calling](https://developer.apple.com/documentation/foundationmodels/expanding-generation-with-tool-calling), [SystemLanguageModel.Adapter](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter).
