# Stack Decision, Architecture & Setup

How to choose among the three CloudKit tiers, the container/database/zone model they all sit on, and the setup that every CloudKit app needs — entitlements, the Console, environments, schema deployment, quotas, and account state.

## Table of Contents
- [The three-tier decision](#the-three-tier-decision)
- [Container, database, zone](#container-database-zone)
- [Entitlements and capabilities](#entitlements-and-capabilities)
- [The CloudKit Console](#the-cloudkit-console)
- [Development vs production and schema deployment](#development-vs-production-and-schema-deployment)
- [Quotas, limits, pricing](#quotas-limits-pricing)
- [Account state](#account-state)

## The three-tier decision

Decide by **sharing model** first, then by local store:

1. **SwiftData + CloudKit** — single-user private sync, SwiftUI greenfield, iOS 17+. Cheapest to build (near-zero code). **Private database only — no sharing, no public DB**, and strict schema rules. The moment a multi-user-sharing or public-DB requirement appears, this is the wrong tier.
2. **`NSPersistentCloudKitContainer`** (Core Data + CloudKit) — when you need cross-user **sharing** or the **public/shared** database, or Core Data features (compound predicates, fetched-results sectioning). Full local persistence *and* sync, with first-class sharing APIs.
3. **`CKSyncEngine`** (iOS 17+) — when you have your own local store (SQLite, a custom cache) and want system-managed sync (tokens, scheduling, push, retries, account monitoring) without hand-rolling it. You implement two delegate methods.
4. **Raw `CKRecord` + `CKOperation`** — maximum control, legacy code, or a public-database query app with no local mirror. Underpins all the tiers above.

Choose for the known requirements and document likely migration costs. A speculative sharing possibility alone does not require adding a more complex persistence stack.

## Container, database, zone

- **`CKContainer`** — created automatically when you enable CloudKit (`iCloud.<bundle-id>`). An app can use multiple containers or share a container across apps. **Cannot be renamed or deleted** once created — name carefully.
- **`CKDatabase`** — three scopes per container:
  - **Public** (`publicCloudDatabase`) — readable by everyone (even signed-out users, read-only); writable by authenticated users per your roles. Storage counts against the **developer's** quota.
  - **Private** (`privateCloudDatabase`) — the current user's private data; storage counts against the **user's** iCloud quota (free to you).
  - **Shared** (`sharedCloudDatabase`) — a read/write window into records other users have shared with the current user; the data physically lives in each owner's private database.
- **`CKRecordZone`** — a bucket within a database (loosely "a table"):
  - **Default zone** — used in public/private databases, but supports **neither sharing nor `fetchRecordZoneChanges` delta sync**.
  - **Custom zones** — create them in the private database for sharing and incremental change tracking. Participants access shared custom zones through their shared database. The public database does not support custom zones.

## Entitlements and capabilities

1. **iCloud capability** → check **CloudKit** → add/select a container. Adds `com.apple.developer.icloud-services` and the **Push Notifications** capability automatically.
2. **Background Modes → Remote Notifications** — required to receive silent sync pushes that wake the app.
3. **`CKSharingSupported = true`** in Info.plist — required for accepting share invitations.
4. **Apple Developer Program** membership and an appropriate signed-in iCloud account. Supported Simulator configurations can receive APNs sandbox notifications; verify the actual setup and retain real-device release checks.

## The CloudKit Console

Web tool: [CloudKit Console](https://icloud.developer.apple.com/).
- Browse/edit records, manage **schema** (record types, fields, indexes), view subscriptions.
- **Indexes** — add `QUERYABLE` (filter), `SORTABLE` (sort), `SEARCHABLE` (full-text, String only) per field. Index types are independent: to filter *and* sort a field, create two indexes. Add a **`QUERYABLE` index on `recordName`** or browsing a record type returns "No Records Found."
- **Telemetry** and **Logs** apps for production monitoring.
- The schema-diff view drives deployment (below).

## Development vs production and schema deployment

- **Two fully separate environments** with separate data.
- **Development:** CloudKit infers schema "just-in-time" — the first time you save a record with a new type/field, it creates the schema. Convenient but means your dev schema drifts as you code.
- **Production:** schema is **fixed**; JIT creation is **prohibited**. An app hitting production with an unmodeled field fails.
- **You must explicitly Deploy Schema Changes** (dev→production) in the Console before App Store/TestFlight release. The deploy shows a diff and is **additive-only and irreversible** — you can't remove fields or change types in production.
- For Core Data/SwiftData, regenerate the schema after model changes (`initializeCloudKitSchema` in DEBUG), verify in the Console, then deploy.

**Failure signature:** "works in dev, fails in production / for App Store users" → almost always un-deployed schema.

## Quotas, limits, pricing

- **Public-database usage counts against the developer; private-database storage counts against each user's iCloud account.** Push is free.
- **Current usage limits and pricing:** consult [CloudKit](https://developer.apple.com/icloud/cloudkit/) and the container’s CloudKit Console metrics. Do not quote historical quota tables as current service guarantees.

- **Hard technical limit: 1 MB per record.** Larger payloads must use `CKAsset`. Core Data auto-spills oversized fields into a `CD_<attr>_ckAsset` field.

## Account state

Always handle the user being signed out of iCloud:
- Observe the **`CKAccountChanged`** notification and call **`CKContainer.accountStatus()`** (`.available`, `.noAccount`, `.restricted`, `.couldNotDetermine`, `.temporarilyUnavailable`).
- `CKSyncEngine` and `NSPersistentCloudKitContainer` monitor account changes for you and emit account-change events — react by isolating caches by account, preserving unsent changes according to an explicit policy, and updating UI (e.g., a "sign in to iCloud to sync" state).
- Never assume an account is present; design the offline/no-account path first.


Simulator notification support: [Xcode 14 release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-14-release-notes). This establishes supported Simulator APNs delivery; it does not by itself verify CloudKit sync in a particular app.

Reviewed 2026-10-16 with Xcode 27.0 / iOS 27.0 SDK. Primary reference: [CloudKit setup](https://developer.apple.com/documentation/cloudkit/enabling-cloudkit-in-your-app). Availability and runtime behavior must be checked for the app’s actual platforms.
