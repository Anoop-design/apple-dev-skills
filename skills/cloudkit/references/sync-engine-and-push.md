# CKSyncEngine, Change Tracking & Push

How to sync a custom local store with `CKSyncEngine` (the recommended modern path, iOS 17+), the lower-level change-tracking primitives it's built on, and the subscription/silent-push mechanics that drive sync.

## Table of Contents
- [CKSyncEngine overview](#cksyncengine-overview)
- [The two delegate methods](#the-two-delegate-methods)
- [State serialization](#state-serialization)
- [Handling sent-change failures](#handling-sent-change-failures)
- [Lower-level change tracking](#lower-level-change-tracking)
- [Subscriptions](#subscriptions)
- [Silent push](#silent-push)
- [Testing sync deterministically](#testing-sync-deterministically)

## CKSyncEngine overview

`CKSyncEngine` (WWDC23, iOS 17+) syncs a local store to a **private or shared** database (not public). It manages token caching, scheduling, silent-push listening, automatic retry of transient errors, and account-change monitoring. Apple dogfoods it in Freeform and `NSUbiquitousKeyValueStore`.

Lifecycle:
1. Initialize **early** in the app launch with a `CKSyncEngine.Configuration` (database, last-known serialized state, delegate).
2. Keep a state token cached locally (you persist it).
3. Create your **custom zone**.
4. Add pending changes to `syncEngine.state`.
5. Supply record contents via the delegate when the engine is ready to upload.
6. React to fetched server changes in the delegate.

Create **one engine per database** — one for private, one for shared if you sync both.

## The two delegate methods

```swift
func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
    switch event {
    case .stateUpdate(let update):
        persist(update.stateSerialization)            // SAVE on every state update
    case .accountChange(let change):
        handleAccountChange(change)                   // isolate caches by account; preserve unsynced work
    case .fetchedDatabaseChanges(let changes): ...
    case .fetchedRecordZoneChanges(let changes):
        apply(changes.modifications, changes.deletions) // merge into local store
    case .sentRecordZoneChanges(let sent):
        handleSentChanges(sent)                       // resolve conflicts (below)
    case .willFetchChanges, .didFetchChanges,
         .willSendChanges, .didSendChanges: ...
    @unknown default: break
    }
}

func nextRecordZoneChangeBatch(_ context: CKSyncEngine.SendChangesContext,
                               syncEngine: CKSyncEngine) async
    -> CKSyncEngine.RecordZoneChangeBatch? {
    let scope = context.options.scope
    let pending = syncEngine.state.pendingRecordZoneChanges.filter { scope.contains($0) }
    return await CKSyncEngine.RecordZoneChangeBatch(pendingChanges: pending) { recordID in
        self.record(for: recordID)                    // return the record to upload, or nil
    }
}
```

- `handleEvent` is a big `switch` over `CKSyncEngine.Event`.
- `nextRecordZoneChangeBatch` returns the next batch of records to upload, filtered by the context scope against `state.pendingRecordZoneChanges`.

## State serialization

Persist `stateSerialization` to disk on **every** `.stateUpdate` event — it is a sync checkpoint, separate from your local records. On crash or relaunch you resume from the last persisted state. Pass it back via the configuration on next launch. Coordinate committing fetched changes and persisting checkpoints so a crash cannot advance a checkpoint past unsaved local changes. If state is lost, reconcile a fresh fetch without discarding unsent local edits.

Persist record system fields/change tags alongside your local model so conflict detection survives relaunch. Keep upload asset files accessible until CloudKit finishes reading them; copy downloaded files to app-managed storage before retaining them beyond the fetch lifecycle.

## Handling sent-change failures

In `.sentRecordZoneChanges`, inspect `failedRecordSaves`:
- **`.serverRecordChanged`** → conflict; do a three-way merge (server/client/ancestor) and re-add the record to pending.
- **`.zoneNotFound`** → the zone is unavailable. Distinguish first-time creation from intentional deletion, a revoked share, or an encrypted-data reset. Do not automatically resurrect deleted data; recreate only when the app’s recovery policy permits it.
- Transient errors (`networkFailure`, `networkUnavailable`, `serviceUnavailable`, `requestRateLimited`) are **retried automatically**, respecting `retryAfter` — you don't handle these yourself.

## Lower-level change tracking

If you're not using `CKSyncEngine`, sync with the primitives it wraps:
- **`CKFetchDatabaseChangesOperation`** → which zones changed (returns a database change token).
- **`CKFetchRecordZoneChangesOperation`** → record deltas per zone using a **`CKServerChangeToken`**. Pass `nil` for a full fetch; store the returned token to fetch only subsequent changes. `moreComing` indicates more pages.
Persist tokens like `CKSyncEngine` persists its state — lose them and you re-fetch everything.

## Subscriptions

Three subscription types generate APNs pushes when data changes:
- **`CKQuerySubscription`** — fires on create/update/delete matching a predicate. **Public and private databases only.**
- **`CKRecordZoneSubscription`** — any change within a specific zone.
- **`CKDatabaseSubscription`** — any change in a database. **Private and shared databases only** — the right choice for the **shared** DB, where you don't know zones in advance.

Create them once (track that you did, e.g., a saved flag) and re-create after account changes.

## Silent push

For background sync, set the subscription's notification info to silent:
```swift
let info = CKSubscription.NotificationInfo()
info.shouldSendContentAvailable = true     // silent push — wakes the app, no alert
subscription.notificationInfo = info
```
Handle the wake in `application(_:didReceiveRemoteNotification:)` (or the scene equivalent) by fetching changes. **Requirements:** Background Modes → Remote Notifications and working APNs registration/delivery. Supported Simulator configurations receive APNs sandbox notifications; verify the actual host/runtime and retain real-device release checks.

**Reliability caveat:** silent pushes can be delayed or dropped. Don't depend on push alone — also fetch changes on app foreground, and consider a light polling fallback for collaboration-critical features.

## Testing sync deterministically

Set `configuration.automaticallySync = false` before constructing the engine to control event ordering in unit tests, drive `fetchChanges`/`sendChanges` manually, and simulate device-to-device flows with multiple engine instances against the same database. The Apple sample (`apple/sample-cloudkit-sync-engine`) logs events with a "☁️" prefix — mirror that for greppable logs.


Simulator notification support: [Xcode 14 release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-14-release-notes). This establishes supported Simulator APNs delivery; it does not by itself verify CloudKit sync in a particular app.

Reviewed 2026-10-16 with Xcode 27.0 / iOS 27.0 SDK. Primary reference: [CKSyncEngine](https://developer.apple.com/documentation/cloudkit/cksyncengine). Availability and runtime behavior must be checked for the app’s actual platforms.
