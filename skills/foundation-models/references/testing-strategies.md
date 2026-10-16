# Testing Foundation Models features

Checked 2026-10-16 against Xcode 27.0 (27A266a), Swift 6.4, and the iOS 27 SDK. Availability below is per API, not the skill name.

Separate deterministic integration behavior from model quality. Use the project's existing test setup; don't install a test framework or require a model-enabled CI machine merely to test UI state.

## Integration checks

Inject an app-owned availability and generation interface when deterministic tests need it. Verify available/unavailable UI, empty input, cancellation, streamed snapshots, tool failure, duplicate request handling, and the product's overflow behavior. A fake stream should contain **cumulative snapshots**, matching the real API.

Test tools directly with invalid identifiers and denied operations. Check that calling a tool twice cannot accidentally repeat a non-idempotent mutation. Tests of a generated type's shape do not prove facts are accurate or tools are authorized.

Use actual Xcode scheme controls when present to simulate model availability, but confirm state names in that toolchain. They don't replace a real eligible device with downloaded assets. Query availability at runtime instead of maintaining a list that incorrectly treats all newer iPhones or all iPads as eligible.

## Quality checks

Maintain a small representative set of inputs for the changed feature, including missing facts, long input, the supported languages, and adversarial instructions inside supplied content. Define observable acceptance criteria such as factual extraction accuracy or adherence to a required field. Repeat samples where variability matters. Don't assert exact wording, a fixed number of stream updates, or an arbitrary self-reported confidence.

Distinguish unavailable infrastructure from a quality regression in test reports. Test device behavior and latency on representative hardware. Simulator model access depends on host and runtime configuration; a successful typecheck doesn't establish inference availability.

## Performance and diagnostics

Profile when latency or memory is relevant. Measure first response, total generation duration, context usage, and tool latency against the feature's own baseline. Avoid universal targets such as “under 500 MB” or “20 tokens per second.”

Use Instruments' available Foundation Models tooling for sessions and requests. Don't log full private prompts, responses, or tool arguments by default. Redact or use privacy-aware logging. Cancellation should restore the UI without leaving a session busy.

Official sources: [Foundation Models](https://developer.apple.com/documentation/foundationmodels), [Evaluating your app’s Foundation Models features](https://developer.apple.com/documentation/foundationmodels), [Testing](https://developer.apple.com/documentation/testing).
