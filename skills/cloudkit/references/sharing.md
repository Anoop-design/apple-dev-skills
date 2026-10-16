# Sharing & Collaboration

Sharing CloudKit data between users with `CKShare` — the two sharing models, permissions, the UI, accepting invitations, and real-time collaboration patterns. Remember: shared records must live in a **custom zone**, never the default zone.

## Table of Contents
- [CKShare fundamentals](#ckshare-fundamentals)
- [Hierarchical vs zone-wide sharing](#hierarchical-vs-zone-wide-sharing)
- [Permissions](#permissions)
- [Presenting the share UI](#presenting-the-share-ui)
- [Accepting a share](#accepting-a-share)
- [Real-time collaboration](#real-time-collaboration)

## CKShare fundamentals

A `CKShare` is a special record (type `cloudkit.share`) that acts as a **portal** from the owner's private database into participants' shared databases. It records what's shared, who with, and each participant's permission. It records the share's existence; the actual data stays in the owner's private DB and appears in participants' `sharedCloudDatabase`.

**Must be saved (with its shared records) in a custom zone** — default-zone records cannot be shared.

## Hierarchical vs zone-wide sharing

Two models (WWDC21 session 10086):

**Hierarchical / root-record sharing:**
```swift
let share = CKShare(rootRecord: projectRecord)
share[CKShare.SystemFieldKey.title] = "My Project" as CKRecordValue
let (saves, _) = try await db.modifyRecords(
    saving: [projectRecord, share], deleting: [], atomically: true)
for result in saves.values { _ = try result.get() }
```
- Sharing a root shares **all descendants** linked via the `parent` reference.
- Records added/removed from the hierarchy are auto-shared/unshared.
- **Multiple non-overlapping** hierarchical shares can coexist in one zone.

**Zone-wide sharing (iOS 15+):**
```swift
let share = CKShare(recordZoneID: customZone.zoneID)
```
- **Every** record in the zone is shared — no per-record manipulation.
- **Only one** zone-wide share per zone, and it **can't coexist with hierarchical shares** in the same zone.
- Detect via `recordID.recordName == CKRecordNameZoneWideShare`; `rootRecord`/`hierarchicalRootRecordID` are nil for zone shares.

Choose hierarchical when you share discrete trees (a document and its parts); choose zone-wide when an entire dataset/collection is shared as a unit.

## Permissions

- **`publicPermission`** (default `.none`) — controls anyone-with-the-link access. Keep it `.none` for private collaboration (and it's a precondition for Advanced Data Protection on shared data).
- **Per-participant permission** — `.readOnly` or `.readWrite`, set when inviting or via the UI.
- The **owner** stops sharing by deleting the `CKShare`; a **participant** leaves via "Remove Me."

## Presenting the share UI

- **`UICloudSharingController`** — system UI to invite/manage participants, set permissions, and stop sharing. Wrap in `UIViewControllerRepresentable` for SwiftUI. Set `availablePermissions` (`.allowReadOnly`, `.allowReadWrite`, `.allowPrivate`, `.allowPublic`). **It does NOT fetch an existing `CKShare` for you** — fetch/cache the share first (via the record's `share` reference) before presenting, or you'll create a duplicate.
- **`ShareLink`** / **`SWCollaborationView`** — the modern SwiftUI-era entry points for presenting a share.

## Accepting a share

Opening a supported share invitation routes through the system’s CloudKit acceptance flow:
- **Scene/app delegate:** implement `userDidAcceptCloudKitShareWith(_ metadata:)`.
- **Raw CloudKit:** run a `CKAcceptSharesOperation` with the `CKShare.Metadata`.
- **Core Data:** call `acceptShareInvitations(from:into:)`.
- Add `CKSharingSupported = true` to Info.plist or acceptance won't be offered.

After acceptance, the shared records appear in the participant's `sharedCloudDatabase` (or the Core Data `.shared` store).

## Real-time collaboration

CloudKit isn't a live socket — "real-time" means promptly reacting to change pushes:
- Subscribe to the **shared database** (`CKDatabaseSubscription`) for participant/owner updates and to **zones** (`CKRecordZoneSubscription`) where appropriate.
- Deliver **silent pushes** (`shouldSendContentAvailable = true`) and fetch changes on receipt; merge with three-way conflict resolution (`serverRecordChanged`).
- Because pushes can lag, production collaboration apps layer a **short polling timer** and an **`NSPersistentStoreRemoteChange`** bridge (Core Data) as additional triggers, plus a fetch on foreground.
- Show membership/permission state from the share's participant list (`share.participants`, each with `.role`, `.permission`, `.acceptanceStatus`).

The participant list is not live presence. Use [Apple’s hierarchical-sharing sample](https://github.com/apple/sample-cloudkit-sharing) and [zone-sharing sample](https://github.com/apple/sample-cloudkit-zonesharing) for complete acceptance flows.
