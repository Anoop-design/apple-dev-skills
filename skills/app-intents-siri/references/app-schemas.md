# App Schemas & Domains (iOS 27)

App Schemas are the highest-leverage way to make an app understood by Siri AI. A schema is a **system-defined contract** — a pre-shaped intent, entity, or enum that Siri already knows how to reason about. Adopt one and the assistant understands the action with **no trigger phrases** and keeps understanding it as Apple expands language and feature support, with no further code changes.

WWDC 2026 sessions: **240 "Build intelligent Siri experiences with App Schemas"**, **344 "Code-along: Make your app available to Siri"**, **343 "Explore advanced App Intents features for Siri and Apple Intelligence"**.

## Table of Contents
- [The macros](#the-macros)
- [Domains and schemas](#domains-and-schemas)
- [Adoption workflow](#adoption-workflow)
- [Xcode Fix-Its and complete schema sets](#xcode-fix-its-and-complete-schema-sets)
- [The system search schema](#the-system-search-schema)
- [Risk metadata and confirmation](#risk-metadata-and-confirmation)

## The macros

The current SDK provides the following macros; the macro declarations back-deploy to iOS 18, while individual schemas may require newer OS versions. The older `@AssistantIntent` / `@AssistantEntity` / `@AssistantEnum` names are deprecated aliases:

```swift
@AppIntent(schema: .mail.createDraft)      // shape an intent to a schema
@AppEntity(schema: .mail.message)    // shape an entity to a schema
@AppEnum(schema: .mail.category)     // shape an enum to a schema
```

If older code uses `@AssistantIntent(schema:)`, update it to `@AppIntent(schema:)`. The schema path (e.g. `.mail.createDraft`) names the domain (`mail`) and the specific contract (`createDraft`).

## Domains and schemas

A **domain** is a category of contracts between the app and Siri. Documented domains in the iOS 27 cycle include:

| Domain | Representative schemas / purpose |
|--------|-------------------------------|
| `messages` | `sendMessage`, `draftMessage` — send/compose messages |
| `mail` | `createDraft`, `sendDraft`, draft/message entities, category enum |
| `photos` | create album, search/open assets, `deleteAssets` (destructive) |
| `calendar` | create/open events |
| `clock` | alarms, timers, stopwatches |
| `camera` | open camera, capture modes |
| `books` | open/read books |
| `browser` | open URLs, tabs |
| `fileManagement` | open/move/manage files |
| `presentation` | presentation editing |
| `spreadsheet` | spreadsheet editing |
| `whiteboard` | whiteboard editing |
| `wordProcessor` / document editing | create/edit documents |
| `documentReader` | open/read documents |
| `audio` / media | play/queue/control media |
| `system` | cross-cutting system contracts incl. `searchInApp` |

The exact schema set and availability vary by SDK — let Xcode autocomplete reveal what's available for the current SDK rather than hard-coding from memory.

### Mail and messaging contracts

Mail separates creating/updating a draft, saving it, and sending it (`createDraft`, `updateDraft`, `saveDraft`, `sendDraft`). Its `.mail.draft` path is an **entity** schema, not an intent. Messaging has its own `draftMessage` and `sendMessage` schemas. Model the actual workflow and inspect each schema’s required parameters, return value, related entity schemas, and availability in the SDK. Do not invent a generic recipients/content shape and assume every schema accepts it.

## Adoption workflow

1. **Find the domain** that matches the app's category (a journaling app → `wordProcessor`/document editing; a music app → `audio`; a to-do app → often custom intents plus `system`).
2. **Type `@AppIntent(schema: .`** and let Xcode autocomplete list schemas grouped by domain.
3. **Conform the intent**, matching the schema's required parameters (the compiler enforces the shape — wrong/missing parameters won't build).
4. **Conform the related entities and enums** with `@AppEntity(schema:)` / `@AppEnum(schema:)`.
5. **Build** and resolve any Fix-Its for missing related schemas.
6. **Test** in Shortcuts first (the intent shows up there), then Spotlight, then Siri.

## Xcode Fix-Its and complete schema sets

Siri conversations work best when an app adopts a *complete* set of related schemas. If `sendMessage` is adopted but not `draftMessage`, Xcode 27 surfaces a build-time Fix-It pointing at the missing schema. Review related schemas and implement only those that match real app capabilities; test multi-step conversations end to end.

## The system search schema

`.system.searchInApp` (check the schema supported by your deployment target) lets Siri re-run a search **inside the app's own search UI**, regardless of which domains are adopted or whether entities are indexed. It uses `StringSearchCriteria`:

```swift
@AppIntent(schema: .system.searchInApp)
struct SearchInAppIntent: AppIntent {
    @Parameter var criteria: StringSearchCriteria

    static var openAppWhenRun: Bool { true }

    @MainActor
    func perform() async throws -> some IntentResult {
        Router.shared.showSearch(query: criteria.term)
        return .result()
    }
}
```

This is a good baseline even for apps that can't model rich entities yet — it makes "search X in <app>" work.

## Risk metadata and confirmation

Schemas communicate action semantics, and the system may request confirmation. Independently enforce the app’s authentication, authorization, ownership checks, and destructive-action policy inside the operation. All invocation surfaces must preserve those rules. Model shared content with `OwnershipProvidingEntity` where appropriate, and test confirmation behavior in the actual system surface.

[App schemas](https://developer.apple.com/documentation/appintents/app-schemas) and [App Intent adoption](https://developer.apple.com/videos/play/wwdc2026/240/) provide the current contracts. Examples here show the integration structure; copy the exact required fields and related schema conformances from your SDK rather than assuming the illustrative mail/chat entities satisfy a schema.
