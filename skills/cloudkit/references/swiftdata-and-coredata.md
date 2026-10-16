# SwiftData + CloudKit & NSPersistentCloudKitContainer

The two "batteries-included" tiers that give you local persistence *and* iCloud sync together. SwiftData is the easy private-only path; `NSPersistentCloudKitContainer` is the full path with sharing and the public/shared database.

## Table of Contents
- [SwiftData + CloudKit setup](#swiftdata--cloudkit-setup)
- [The hard schema rules](#the-hard-schema-rules)
- [The private-database-only limitation](#the-private-database-only-limitation)
- [SwiftData version considerations](#swiftdata-version-considerations)
- [NSPersistentCloudKitContainer setup](#nspersistentcloudkitcontainer-setup)
- [Schema init and deployment](#schema-init-and-deployment)
- [Monitoring sync](#monitoring-sync)
- [Core Data sharing APIs](#core-data-sharing-apis)
- [Debugging](#debugging)

## SwiftData + CloudKit setup

Nearly zero-code for single-user private sync:
1. Enable iCloud + CloudKit + a container; add Background Modes → Remote Notifications.
2. Configure the `ModelContainer` with a CloudKit database (or rely on the default automatic configuration):
```swift
let config = ModelConfiguration(cloudKitDatabase: .private("iCloud.com.example.app"))
let container = try ModelContainer(for: Item.self, configurations: config)
```
SwiftData mirrors the model to CloudKit and syncs across the user's devices with no further code in the simple case.

## The hard schema rules

CloudKit integration **enforces** these — violate them and **store loading can fail** (watch the Xcode log):
- **Every attribute must be optional or have a default value.**
- **Every relationship must be optional.**
- **No `.unique` constraints** — "CloudKit integration does not support unique constraints."
- Relationships need inverses; avoid unsupported delete rules such as deny. Check encryption restrictions against the model’s intended query behavior.

The telltale log line: "CloudKit integration requires that all attributes be optional, or have a default value." If sync isn't working, check this first.

## The private-database-only limitation

**SwiftData + CloudKit syncs to the PRIVATE database only.** No public database, no shared database, **no built-in multi-user sharing.** This is confirmed directly by Apple's engineers: if you need the public or shared database, use `NSPersistentCloudKitContainer` instead.

Community workarounds bridge SwiftData (for private sync) to **manual `CKShare` code** for sharing, but it's involved, undocumented, and easy to get wrong. **If sharing is a requirement or even a likely future need, don't start on SwiftData expecting to bolt it on** — start with Core Data + `NSPersistentCloudKitContainer`.

## SwiftData version considerations

SwiftData local query, observation, and modeling APIs evolve separately from CloudKit mirroring. Check [SwiftData synchronization](https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices) and the deployment SDK before assuming a local feature is compatible with a mirrored store. This skill does not require installing another skill.

## NSPersistentCloudKitContainer setup

The full-stack option: local Core Data persistence mirrored to a CloudKit private database (and, with extra setup, public/shared).
```swift
let container = NSPersistentCloudKitContainer(name: "Model")
guard let desc = container.persistentStoreDescriptions.first else { fatalError() }
desc.cloudKitContainerOptions =
    NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.example.app")
desc.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
desc.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
container.loadPersistentStores { _, error in /* handle */ }
```
The same attribute rules as SwiftData apply (optional/default, optional relationships, no unique). For sharing you add a **second `.shared`-scoped `NSPersistentStoreDescription`** pointing at a `share.sqlite` store.

## Schema init and deployment

In DEBUG, push the schema to CloudKit so the Console knows your types:
```swift
#if DEBUG
try container.initializeCloudKitSchema(options: [])
#endif
```
Run once, verify the record types/fields in the **CloudKit Console**, then **Deploy Schema Changes** dev→production before TestFlight/release. Re-run after model changes. Most "relationships/new field don't sync" issues are a **stale cloud schema** — regenerate and redeploy.

## Monitoring sync

- **`NSPersistentCloudKitContainer.eventChangedNotification`** (iOS 14+) exposes `.setup` / `.import` / `.export` events with start/end dates — drive a sync-status indicator from these. A local change fires an `.export`; remote devices then `.import`.
- **`NSPersistentStoreRemoteChange`** notification — fires when the store changes from another device/extension; refresh your UI/fetched results on it.

## Core Data sharing APIs

WWDC21 session 10015, iOS 15+:
- **`share(_:to:completion:)`** — associate managed objects with a new/existing `CKShare`; Core Data moves them into a system-created custom zone (`com.apple.coredata.cloudkit.share.*`).
- **`fetchShares(in:)`** / **`fetchShares(matching:)`** — get shares for a store or specific objects.
- **`acceptShareInvitations(from:into:)`** — accept (in the scene delegate's `userDidAcceptCloudKitShareWith`).
- **`fetchParticipants`** / **`persistUpdatedShare`** — manage participants.
Refresh share state after membership or permission changes and handle removal. See `references/sharing.md` for the `CKShare`/UI layer.

## Debugging

- Launch arguments: `-com.apple.CoreData.CloudKitDebug 1` and `-com.apple.CoreData.SQLDebug 1` for verbose sync/SQL logs.
- Inspect the full error domain, code, underlying error, and CloudKit event. A numeric Core Data error alone does not establish a sync root cause.
- **Don't aggressively delete persistent history** — Apple warns it can force a full re-download.
- Test private sync across two devices on the same Apple ID. Supported simulators can receive APNs sandbox pushes; verify the actual setup and include real-device release checks.


Simulator notification support: [Xcode 14 release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-14-release-notes). This establishes supported Simulator APNs delivery; it does not by itself verify CloudKit sync in a particular app.
