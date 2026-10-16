---
name: cloudkit
description: "Implement or debug CloudKit and iCloud data synchronization, SwiftData/Core Data mirroring, CKSyncEngine, records and queries, sharing, encryption, and schema deployment. Use when iCloud sync or CloudKit is part of the feature; generic offline persistence or non-iCloud networking does not require this skill."
license: MIT
---

# CloudKit & the Apple Cloud-Sync Stack (iOS 27 / WWDC 2026)

Reviewed 2026-10-16 against Xcode 27.0 (27A266a), Swift 6.4, and the iOS 27.0 SDK. Check the target platform and deployment version for each API; newer SDK availability does not imply that a consumer service is enabled for every account or region. Code using app stores, routers, or model types is an integration sketch; supply those app-specific dependencies.

CloudKit is Apple's framework for storing and syncing app data and assets in iCloud across devices and the web. **It is a transport + backend, not a local database** — it gives you Apple-hosted storage, auth tied to the user's iCloud account, and push notifications, but you choose your own local store (SwiftData, Core Data, SQLite, your own cache). This skill covers the whole stack: which tier to use, the data model, reading/writing, sync, sharing, encryption, and production realities.

## Step 1 — choose your tier (decide this FIRST)

Choose a persistence and synchronization approach using the sharing requirements, existing local store, and target OS versions:

| Your need | Use | Why |
|-----------|-----|-----|
| Single-user private sync, SwiftUI greenfield, iOS 17+ | **SwiftData + CloudKit** | Near-zero code. **Private database only** — no sharing, no public DB. |
| Cross-user **sharing** or the **public** database, Core Data-shaped data | **NSPersistentCloudKitContainer** | Full local persistence + sync + sharing APIs. |
| Custom local store (SQLite/your own), full control, iOS 17+ | **CKSyncEngine** | Private/shared database sync (tokens, push, retries); you implement 2 delegate methods. |
| Maximum control / legacy / public-DB query app | **Raw `CKRecord` + `CKOperation`** | Underpins all of the above. |

The single most consequential fact: **SwiftData + CloudKit syncs to the private database only.** If a requirement for multi-user sharing or the public database exists is a firm requirement, do **not** start with SwiftData expecting to add sharing later — start with `NSPersistentCloudKitContainer` (or implement a separate, explicit synchronization layer). This is confirmed by Apple's own engineers.

## Guardrails — the CloudKit mistakes that cause "it doesn't sync"

1. **The default zone cannot be shared, and doesn't support delta sync.** Sharing (`CKShare`), zone subscriptions, and `fetchRecordZoneChanges` all require a **custom zone**. If sharing or efficient sync is even possible in your future, create a custom zone from day one. This is the #1 thing people miss.
2. **Schema must be explicitly deployed dev→production.** In development, CloudKit infers schema "just-in-time" from the first record you save; in production the schema is **fixed** and JIT is prohibited. Works-in-dev-fails-in-production almost always means you forgot to **Deploy Schema Changes** in the CloudKit Console. Deployments are additive-only and irreversible.
3. **Queried fields need a `QUERYABLE` index; sorted fields need `SORTABLE`.** The classic gotcha: the Console shows "No Records Found" until you add a **QUERYABLE index on `recordName`**. Encrypted fields can't be indexed/queried/sorted at all.
4. **SwiftData/Core Data + CloudKit require every property optional or defaulted, every relationship optional, and NO `.unique` constraints.** Violating this can fail store initialization — watch the Xcode log for "CloudKit integration requires that all attributes be optional, or have a default value."
5. **Verify cross-device sync and account behavior.** Use two devices on the same Apple ID for private-database sync, and separate accounts for sharing tests. Supported Simulator configurations can receive APNs sandbox notifications; verify the host, runtime, signing, iCloud account, and notification delivery in the actual setup. Retain real-device checks for release confidence.
6. **Don't trust silent push alone.** Pushes can be delayed/unreliable (delivery is best-effort). Add a foreground change-fetch, and consider a light polling fallback for collaboration.

## Version scope

Core CloudKit APIs are available across Apple platforms; `CKSyncEngine` requires iOS 17 / macOS 14 or later. Inspect the chosen API and database scope. SwiftData’s local query APIs and CloudKit mirroring capabilities are separate decisions; newer local-store features do not imply support for public or shared databases.

## The data model (quick reference)

- **`CKContainer`** — one per app by default (`iCloud.<bundle-id>`); created when you enable the CloudKit capability; can't be renamed or deleted.
- **`CKDatabase`** — three scopes per container: **public** (all users, counts against the *developer's* quota), **private** (the signed-in user, counts against the *user's* iCloud quota), **shared** (a window into records others shared with you; data physically lives in the owner's private DB).
- **`CKRecord`** — a typed key-value dictionary; `recordType` is a string, fields set by subscripting. Value types: `String`, `NSNumber`, `Data`, `Date`, `CLLocation`, `CKRecord.Reference`, `CKAsset`, and arrays. **1 MB per record** — use `CKAsset` for anything larger than a few KB.
- **`CKRecord.Reference`** — typed pointer to another record; the `.parent` reference expresses hierarchy (essential for sharing).
- **`CKRecordZone`** — a bucket in a database. The **default zone** is used by public/private databases but supports neither sharing nor delta sync; **custom zones** unlock both in private/shared databases. Public databases do not support custom zones.
- **System metadata** on every record: `recordName` (ID), creation/modification dates and users, and a **change tag** (`recordChangeTag`) used for conflict detection.

## Setup (every CloudKit app)

1. Add the **iCloud** capability → check **CloudKit** → add/select a container (this also adds **Push Notifications** automatically).
2. Add **Background Modes → Remote Notifications** (so the app can receive silent sync pushes).
3. For sharing, add `CKSharingSupported = true` to Info.plist.
4. Configure the development team, container entitlements, and a signed-in iCloud account for private/shared access. Public reads depend on schema roles and may work without an account. Test the actual device/account matrix.

## Reading & writing (quick start)

Use the modern async/await convenience API for UI apps; reach for the operation API (`CKModifyRecordsOperation`, `CKQueryOperation`, `CKFetchRecordZoneChangesOperation`) for batching, cursors, `desiredKeys`, and delta sync.

```swift
import CloudKit

let db = CKContainer.default().privateCloudDatabase

// save
let record = CKRecord(recordType: "Note")
record["title"] = "Hello"
let saved = try await db.save(record)

// query (needs a QUERYABLE index on the queried field)
let query = CKQuery(recordType: "Note", predicate: NSPredicate(value: true))
query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
let (results, cursor) = try await db.records(matching: query)
// Inspect each Result and continue with records(continuingMatchFrom:) while cursor != nil.
```

Handle **partial failures** (`CKError.partialFailure` with a per-record error dict) and the key conflict error **`CKError.serverRecordChanged`** (carries `serverRecord`/`clientRecord`/`ancestorRecord` for three-way merge). Full CRUD, query limits, cursors, and conflict resolution → `references/records-and-queries.md`.

## When to read each reference

- **`references/stack-decision-and-setup.md`** — the three-tier decision in depth, container/database/zone architecture, entitlements, the CloudKit Console, dev-vs-production environments and schema deployment, quotas/limits/pricing (with sourcing caveats), and account-state handling. Read before choosing an approach or wiring up a container.
- **`references/records-and-queries.md`** — `CKRecord` CRUD, value types, `CKAsset`, references/hierarchy, `CKQuery` + predicate limits + indexes, cursors, the operation API, async/await, batching, partial failures, and conflict resolution. Read for any direct CloudKit read/write.
- **`references/sync-engine-and-push.md`** — `CKSyncEngine` (the two delegate methods, the event `switch`, state serialization, conflict/zone handling), lower-level change tracking (`CKServerChangeToken`, fetch-database/zone-changes), and the three subscription types + silent push. Read for custom sync.
- **`references/swiftdata-and-coredata.md`** — SwiftData + CloudKit (setup, the hard schema rules, the private-only limitation, local SwiftData version considerations) and `NSPersistentCloudKitContainer` (setup, schema init/deploy, sync monitoring, the sharing APIs, debugging). Read when syncing a persistence layer.
- **`references/sharing.md`** — `CKShare`, hierarchical vs zone-wide sharing, permissions, `UICloudSharingController`/`ShareLink`, accepting shares, and real-time collaboration patterns. Read for any multi-user feature.
- **`references/security-and-production.md`** — per-field encryption (`encryptedValues`), what can/can't be encrypted, Advanced Data Protection, schema design, migration/evolution, the common pitfalls list, testing/debugging, and the Apple sample repos. Read before shipping.

## Critical gotchas

- **SwiftData + CloudKit is private-database only** — don't plan sharing/public-DB on it (guardrail / stack choice).
- **Default zone can't be shared or delta-synced** — use custom zones (guardrail 1).
- **Deploy schema dev→production** before TestFlight, or it fails in production (guardrail 2).
- **Diagnose index errors explicitly** and add the appropriate query/sort indexes; an empty result can also reflect environment, account, or data scope (guardrail 3).
- **All attributes optional/defaulted, relationships optional, no `.unique`** for SwiftData/Core Data sync (guardrail 4).
- **Verify sync on the actual device/account matrix**, including real devices for release confidence. Simulator push support depends on its host and runtime (guardrail 5).
- **Don't rely on silent push alone** — add foreground fetch / polling (guardrail 6).
- **Encrypted fields can't be indexed/queried/sorted**; `CKReference` can't be encrypted; `CKAsset` is encrypted by default (don't double-encrypt).
- **Control asset fetches with `desiredKeys`** and copy downloaded asset files into app-managed storage if needed.

## Primary references

- [CloudKit](https://developer.apple.com/documentation/cloudkit)
- [CKSyncEngine](https://developer.apple.com/documentation/cloudkit/cksyncengine)
- [Apple’s sync-engine sample](https://github.com/apple/sample-cloudkit-sync-engine)
- [SwiftData synchronization](https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices)
- [Encrypted record values](https://developer.apple.com/documentation/cloudkit/ckrecord/encryptedvalues)
- [Preparing a Core Data app for CloudKit](https://developer.apple.com/documentation/coredata/setting-up-core-data-with-cloudkit)
