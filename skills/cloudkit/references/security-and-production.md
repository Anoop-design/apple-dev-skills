# Security, Encryption & Production

Per-field encryption, Advanced Data Protection, schema design, migration, the common-pitfalls list, testing/debugging, and the canonical Apple sample repos. Read before shipping a CloudKit app.

## Table of Contents
- [Per-field encryption](#per-field-encryption)
- [What can and can't be encrypted](#what-can-and-cant-be-encrypted)
- [Advanced Data Protection](#advanced-data-protection)
- [Schema design](#schema-design)
- [Migration and schema evolution](#migration-and-schema-evolution)
- [Common pitfalls](#common-pitfalls)
- [Testing and debugging](#testing-and-debugging)
- [Sample repos](#sample-repos)

## Per-field encryption

Encrypt sensitive fields with `encryptedValues` (private/shared DB):
```swift
record.encryptedValues["privateNote"] = noteText
let value = record.encryptedValues["privateNote"] as? String
```
Works for `String`, `NSNumber`, `Date`, `Data`, `CLLocation`, and `NSArray`. These fields receive encrypted storage and cannot be queried. Do not promise end-to-end encryption from `encryptedValues` alone; key protection depends on Advanced Data Protection and sharing conditions.

## What can and can't be encrypted

- **`CKReference` fields CAN'T be encrypted** — the server needs them to maintain relationships.
- **`CKAsset` is encrypted by default** — don't put it in `encryptedValues` (that value type is unsupported there).
- **Encrypted fields CAN'T be indexed, queried, or sorted.** Plan which fields you filter/sort on *before* deciding what to encrypt.
- **You can't convert an existing unencrypted field to encrypted in place** — encryption must be chosen for **new fields/records**. Migrating means writing to a new encrypted field.
- Encryption key material lives in the user's **iCloud Keychain**. A keychain reset yields `CKError.zoneNotFound` with `CKErrorUserDidResetEncryptedDataKey` — recognize the reset and follow an explicit data-recovery policy. Do not silently recreate data the user intentionally removed.

## Advanced Data Protection

Advanced Data Protection can provide end-to-end protection for encrypted fields and assets when its requirements hold; ordinary record metadata and queryable fields are not thereby encrypted. For shared data, verify these requirements:
1. You use `encryptedValues` / `CKAsset` for the sensitive data,
2. any governing `CKShare` has `publicPermission == .none`, and
3. all participants have ADP enabled.

Caveats: you **can't detect at runtime** whether condition 3 holds; "anyone with the link" shares and web (CloudKit JS) collaboration **don't** get ADP. Encrypted storage and end-to-end encryption are different guarantees. Use [encryptedValues](https://developer.apple.com/documentation/cloudkit/ckrecord/encryptedvalues) and [Encrypting User Data](https://developer.apple.com/documentation/cloudkit/encrypting-user-data) for current key-protection rules.

## Schema design

- Keep records **under 1 MB**; use `CKAsset` for large blobs.
- Add `QUERYABLE`/`SORTABLE`/`SEARCHABLE` indexes **only where needed** (every index costs storage and write time); remember encrypted fields can't be indexed.
- Model parent/child via `CKRecord.parent` **early** if you'll share hierarchies.
- **Use custom zones from day one** if sharing or delta sync is even possible later — retrofitting zones means migrating data.
- Prefer many small fields you update independently over one big blob, so change-tracking uploads stay small.

## Migration and schema evolution

- Develop schema in the **development** environment (JIT-created as you save records), verify in the Console, then **Deploy Schema Changes** to production.
- **Production schema changes are additive-only and irreversible** — you can't remove fields or change a field's type in production. Plan field names/types carefully; add new fields rather than repurposing old ones.
- For Core Data/SwiftData, re-run `initializeCloudKitSchema` after model changes and re-deploy.
- Never assume a field exists on old records — handle nils for fields added later.

## Common pitfalls

- **Default-zone records can't be shared** — use custom zones.
- **Console shows no records** until `recordName` has a `QUERYABLE` index.
- **Forgot to deploy schema** → works in dev, fails in production / for App Store users.
- **Assuming every Simulator setup has identical push support** → verify the host/runtime, APNs sandbox registration, iCloud account, and actual delivery before diagnosing sync.
- **Non-optional / non-defaulted / `.unique` properties** in SwiftData/Core Data → store load failure.
- **Unbounded asset fetching** — use `desiredKeys`, and retain required downloaded files in your own cache.
- **Relying on silent push alone** → missed updates; add foreground fetch / polling.
- **Encrypting a field you need to query/sort** → it can't be indexed.
- **Quoting old quota numbers** → verify current service terms and the container’s actual Console usage.

## Testing and debugging

- Verify private sync on **two or more devices** with the same Apple ID, and sharing with separate accounts. Supported simulators can receive APNs sandbox pushes; retain real-device release verification.
- Filter Xcode logs (the Apple samples prefix CloudKit events with "☁️"); for Core Data add `-com.apple.CoreData.CloudKitDebug 1`.
- For `CKSyncEngine`, set `configuration.automaticallySync = false` before engine creation to order events deterministically in tests and simulate device-to-device flows with multiple engine instances.
- Use the **CloudKit Console** Telemetry and Logs apps for production monitoring (error rates, throttling, push delivery).

## Sample repos

Apple's canonical CloudKit samples (cite these as reference implementations):
- [apple/sample-cloudkit-sync-engine](https://github.com/apple/sample-cloudkit-sync-engine) — `CKSyncEngine`.
- [apple/sample-cloudkit-sharing](https://github.com/apple/sample-cloudkit-sharing) — hierarchical sharing.
- [apple/sample-cloudkit-zonesharing](https://github.com/apple/sample-cloudkit-zonesharing) — zone-wide sharing.
- [apple/cloudkit-sample-encryption](https://github.com/apple/cloudkit-sample-encryption) — `encryptedValues`.


Simulator notification support: [Xcode 14 release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-14-release-notes). This establishes supported Simulator APNs delivery; it does not by itself verify CloudKit sync in a particular app.
