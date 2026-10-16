# Guided generation

Checked 2026-10-16 against Xcode 27.0 (27A266a), Swift 6.4, and the iOS 27 SDK. Availability below is per API, not the skill name.

Use a generated schema when the app consumes fields or choices. This constrains representable structure; it does not establish factual correctness, calibrated confidence, valid contact details, or permission to execute an action.

```swift
import FoundationModels

@available(iOS 26.0, macOS 26.0, *)
@Generable
struct NoteSummary {
    @Guide(description: "Facts explicitly present in the supplied note", .count(1...5))
    var facts: [String]
    @Guide(description: "A concise summary based only on those facts")
    var summary: String
    @Guide(description: "A due date only if the note states one; otherwise nil")
    var dueDate: String?
}
```

Read the generated value with:

```swift
let summary = try await session.respond(
    to: note, generating: NoteSummary.self).content
```

`@Guide` takes `description:` first and generation guides as unlabeled arguments, such as `.range(1...5)`, `.count(3)`, or `.anyOf(["low", "high"])`. It has no `range:` or `count:` labeled argument. Use a generated enum for a fixed set of domain choices.

Order fields so later values can use earlier generated context; summaries often belong after extracted facts. Optional fields are appropriate for missing information: forcing every extracted field to exist encourages invented data. Keep schemas as small as the feature permits; large descriptions, nested arrays, and tool schemas all consume context. Test quality rather than imposing an arbitrary maximum nesting depth.

For streaming, assign `snapshot.content` to `NoteSummary.PartiallyGenerated?`. Render optional fields as they become available. Array elements may also be partial. Use stable display identity and avoid treating a not-yet-generated property as a final decision. Don't assume partial types are `Equatable` or use unfinished text as a `ForEach` identity.

A model-generated confidence score is prose encoded as a number, not a calibrated probability. Validate classification accuracy on representative labeled examples; don't gate consequential actions on an arbitrary self-reported threshold.

When schemas are only known at runtime, use `DynamicGenerationSchema` and validate schema construction errors before generation. Static `@Generable` types are simpler when the schema is known at compile time.

Official sources: [Generating Swift data structures with guided generation](https://developer.apple.com/documentation/foundationmodels/generating-swift-data-structures-with-guided-generation), [Guide](https://developer.apple.com/documentation/foundationmodels/guide(description:_:)), [DynamicGenerationSchema](https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema).
