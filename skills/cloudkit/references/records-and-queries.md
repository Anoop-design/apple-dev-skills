# Records, CRUD & Queries

Working directly with `CKRecord` and `CKOperation`: the data types, CRUD, querying with its real limits, the operation API, batching, partial failures, and conflict resolution. This is the layer all the higher tiers sit on.

## Table of Contents
- [CKRecord and value types](#ckrecord-and-value-types)
- [Assets](#assets)
- [References and hierarchy](#references-and-hierarchy)
- [CRUD with async/await](#crud-with-asyncawait)
- [Querying and its limits](#querying-and-its-limits)
- [The operation API](#the-operation-api)
- [Partial failures](#partial-failures)
- [Conflict resolution](#conflict-resolution)

## CKRecord and value types

`CKRecord` is a typed key-value dictionary — the "model object" of CloudKit:
```swift
let record = CKRecord(recordType: "Note")        // recordType is a string
record["title"] = "Hello"                         // fields via subscript
record["count"] = 3                               // NSNumber bridges automatically
```
Supported value types: `String`, `NSNumber` (Swift numerics bridge), `Data`, `Date`, `CLLocation`, `CKRecord.Reference`, `CKAsset`, and arrays of these. **Record fields are explicit key-value entries; save policy and change tags determine how edits merge** — which makes field-level merging practical (see conflict resolution).

Every record carries system metadata: `recordID` (`recordName` + zone), `creationDate`/`createdBy`, `modificationDate`/`modifiedBy`, and `recordChangeTag` (used for conflict detection). **1 MB per record** — anything larger must be an asset.

## Assets

`CKAsset` holds large binary files:
```swift
record["photo"] = CKAsset(fileURL: localFileURL)   // CloudKit uploads on save
// on fetch: let url = (record["photo"] as? CKAsset)?.fileURL
```
- Use a `CKAsset` for any field larger than a few KB.
- **Assets are encrypted by default** — don't put them in `encryptedValues`.
- Assets are file transfers, not an incremental byte-sync protocol. Use `desiredKeys` to omit asset fields when you only need metadata; cache copied asset files and fetch the asset field when its content changes.

## References and hierarchy

`CKRecord.Reference` is a typed pointer to another record, optionally with a delete action (`.deleteSelf`/`.none`):
```swift
record["author"] = CKRecord.Reference(record: authorRecord, action: .none)
```
The **`parent` reference** expresses parent/child hierarchy and is **essential for hierarchical sharing** — share a root and all descendants linked via `parent` are shared. Set up the hierarchy early if you plan to share trees of records. **Reference fields can't be encrypted** (the server needs them).

## CRUD with async/await

WWDC21 added async/await variants for everything:
```swift
let db = CKContainer.default().privateCloudDatabase
let saved   = try await db.save(record)
let fetched = try await db.record(for: recordID)
try await db.deleteRecord(withID: recordID)
let (saveResults, deleteResults) = try await db.modifyRecords(saving: [r1, r2], deleting: [id3])
```
Per-item results come back as `Swift.Result` so you can handle each record's success/failure independently.

## Querying and its limits

`CKQuery` = record type + `NSPredicate` + sort descriptors:
```swift
let query = CKQuery(recordType: "Note",
                    predicate: NSPredicate(format: "title BEGINSWITH %@", "He"))
query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
let (matches, cursor) = try await db.records(matching: query, resultsLimit: 50)
```
Real limits to internalize:
- **Every filtered field needs a `QUERYABLE` index; every sort field needs `SORTABLE`** (set in the Console). Missing indexes produce query errors; handle the error instead of treating it as an empty result. The infamous one: add a `QUERYABLE` index on **`recordName`** or the Console shows "No Records Found."
- **Predicates are limited** — no key paths into related records, restricted operators. Filter on fields the record owns; resolve relationships client-side.
- **Encrypted fields can't be queried or sorted** at all.
- **Page large results with cursors** (`CKQueryOperation.Cursor`): re-issue with the returned cursor until it's nil.
- `records(matching:)` is convenience; `CKQueryOperation` gives `desiredKeys`, `resultsLimit`, and cursor control.

## The operation API

`CKOperation` subclasses for production-grade control:
- `CKModifyRecordsOperation` — batch save/delete with `savePolicy`, per-record and completion callbacks.
- `CKQueryOperation` — query with cursor, `desiredKeys`, `resultsLimit`.
- `CKFetchRecordsOperation` — fetch by `recordName`(s) directly (records can have different types and zone IDs within the same database; no record-type specifier).
- `CKFetchDatabaseChangesOperation` / `CKFetchRecordZoneChangesOperation` — delta sync (see `references/sync-engine-and-push.md`).
- `CKModifySubscriptionsOperation` / `CKModifyRecordZonesOperation` — manage subscriptions/zones.
Set `qualityOfService` and `desiredKeys` to control cost and bandwidth. Many apps start with the convenience API and move to operations for batching and partial-result handling.

## Partial failures

A batched operation can partially succeed. You get **`CKError.partialFailure`** whose `userInfo[CKPartialErrorsByItemIDKey]` maps each failed `recordID` to its error. Always iterate the per-item errors rather than treating the whole batch as failed — some records saved, some didn't.

## Conflict resolution

The key conflict error is **`CKError.serverRecordChanged`** — another device wrote the record since you last fetched it. Its `userInfo` carries:
- `CKRecordChangedErrorServerRecordKey` — the current server record,
- `CKRecordChangedErrorClientRecordKey` — your attempted record,
- `CKRecordChangedErrorAncestorRecordKey` — the common ancestor.

Do a **three-way field-level merge** when an ancestor is available: start from the server record and compare each locally edited field with the ancestor. Resolve same-field conflicts with domain rules before retrying with the server change tag. Change tokens are synchronization checkpoints, not substitutes for record change tags. Honor the chosen `savePolicy` and retry limits. `CKSyncEngine` surfaces these in `sentRecordZoneChanges.failedRecordSaves` for you to resolve.

Reviewed 2026-10-16 with Xcode 27.0 / iOS 27.0 SDK. Primary reference: [CloudKit database operations](https://developer.apple.com/documentation/cloudkit/ckdatabase). Availability and runtime behavior must be checked for the app’s actual platforms.
