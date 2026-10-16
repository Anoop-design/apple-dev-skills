# StoreKit 2 Core: Purchases, Entitlements, Verification & SwiftUI Views

The stable foundation of in-app purchase. StoreKit 2 is an async/await Swift API; the shape below is unchanged in iOS 27 (the 2026 cycle extends it rather than replacing it). Prefer StoreKit 2 where the deployment target supports it; migrate legacy StoreKit integrations according to the APIs and platforms the app actually uses.

## Table of Contents
- [The lifecycle](#the-lifecycle)
- [Loading products](#loading-products)
- [Purchasing](#purchasing)
- [Verification](#verification)
- [Entitlements (source of truth)](#entitlements-source-of-truth)
- [The transaction listener](#the-transaction-listener)
- [Restore](#restore)
- [Subscription status and renewal info](#subscription-status-and-renewal-info)
- [AppTransaction](#apptransaction)
- [SwiftUI StoreKit views](#swiftui-storekit-views)

## The lifecycle

Every purchase follows the same path: **load → purchase → verify → grant → finish**, with an app-lifetime **listener** for events that happen outside the purchase call (renewals, refunds, Ask-to-Buy approvals, purchases on another device) and **`currentEntitlements`** as the authoritative "what is owned now."

## Loading products

```swift
import StoreKit

let ids: Set<String> = ["com.app.pro.monthly", "com.app.pro.annual", "com.app.coins.100"]
let products = try await Product.products(for: ids)   // returns only valid, available products
```

`Product` exposes `id`, `displayName`, `description`, `displayPrice`, `price` (Decimal), `type` (`.consumable`, `.nonConsumable`, `.autoRenewable`, `.nonRenewable`), and `subscription` (a `Product.SubscriptionInfo?`). Cache nothing about price/availability across storefronts — read it from the loaded `Product`.

## Purchasing

```swift
let result = try await product.purchase()           // add options: for offers / billing plans
switch result {
case .success(let verification):
    let transaction = try checkVerified(verification)
    try await processVerifiedTransaction(transaction) // app-defined durable, idempotent work
    await transaction.finish()                       // only after successful processing
case .userCancelled:
    break
case .pending:
    break                                            // Ask-to-Buy / SCA — resolved later via the listener
@unknown default:
    break
}
```

Purchase options (`Product.PurchaseOption`) include `.appAccountToken(UUID)` (tie a purchase to your user for server correlation — strongly recommended), `.quantity(Int)` (consumables), `.promotionalOffer(...)`, `.introductoryOfferEligibility(...)`, and the 2026 `.billingPlanType(.monthly)` (see `commitment-plans.md`).

## Verification

StoreKit signs transactions (JWS); the framework verifies them on-device and hands you a `VerificationResult`. **Granting access from `.unverified` is the most common security mistake.**

```swift
func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .verified(let safe):
        return safe
    case .unverified(_, let error):
        throw error                                  // never grant access here
    }
}
```

For higher assurance, also validate server-side via the App Store Server API (see `server-and-testing.md`); the on-device check is necessary but a server check defends against jailbroken/tampered clients.

## Entitlements (source of truth)

Don't persist "is premium" in your own flag and trust it. Ask StoreKit:

```swift
func refreshEntitlements() async {
    var active: Set<String> = []
    for await result in Transaction.currentEntitlements {
        guard case .verified(let txn) = result else { continue }
        guard txn.productType == .nonConsumable || txn.productType == .autoRenewable else { continue }
        active.insert(txn.productID)
    }
    self.activeProductIDs = active
}
```

`currentEntitlements` includes non-consumables and auto-renewable subscriptions in subscribed or grace-period states. It also yields non-renewing subscription transactions, whose expiry policy your app must implement; it does not supply a consumable balance. The sample above deliberately handles only non-consumables and auto-renewables. Replace the set at launch, after purchases, on foreground, and on transaction updates; do not add a simple expiry-date filter that accidentally removes billing-grace access.

## The transaction listener

Start this **once, at app launch, before showing UI**, and keep it for the app's lifetime. It delivers transactions that originate outside your `purchase()` call.

```swift
import Combine
import StoreKit

// Handles only non-consumables and auto-renewable subscriptions.
@MainActor
final class Store: ObservableObject {
    @Published private(set) var activeProductIDs: Set<String> = []
    private var updates: Task<Void, Never>?

    init() {
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                guard !Task.isCancelled else { return }
                guard case .verified(let txn) = result,
                      txn.productType == .nonConsumable || txn.productType == .autoRenewable
                else { continue }
                guard let self else { return }
                await self.refreshEntitlements() // adds AND removes access
                await txn.finish()
            }
        }
        Task { [weak self] in await self?.refreshEntitlements() }
    }

    func refreshEntitlements() async {
        var active: Set<String> = []
        for await result in Transaction.currentEntitlements {
            guard case .verified(let txn) = result,
                  txn.productType == .nonConsumable || txn.productType == .autoRenewable
            else { continue }
            active.insert(txn.productID)
        }
        activeProductIDs = active
    }

    deinit { updates?.cancel() }
}
```

For consumables, deliver exactly once through a durable transaction-ID ledger before finishing. For non-renewing subscriptions, reconcile the app’s defined access period. If fulfillment fails, keep the event unfinished and retry; surface/log verification failures without granting access.


Without this, renewals, family-shared purchases, refunds (`txn.revocationDate`), and Ask-to-Buy approvals won't be reflected until next launch.

## Restore

Most "restore" needs are met by `currentEntitlements` + the listener. For an explicit user-triggered restore (provide a restore mechanism for restorable products), call:

```swift
try await AppStore.sync()      // forces a refresh from the App Store, may prompt for Apple Account
await refreshEntitlements()
```

Use `AppStore.sync()` sparingly (it can prompt for authentication) — it's for the explicit button, not routine checks.

## Subscription status and renewal info

```swift
guard let sub = product.subscription else { return }
let statuses = try await sub.status               // [Product.SubscriptionInfo.Status]
for status in statuses {
    let renewal = try checkVerified(status.renewalInfo)   // RenewalInfo
    let txn = try checkVerified(status.transaction)
    // status.state: .subscribed / .expired / .inBillingRetryPeriod / .inGracePeriod / .revoked
    // renewal.willAutoRenew, renewal.autoRenewPreference (the productID it will renew to),
    // renewal.expirationReason, renewal.gracePeriodExpirationDate
}
```

Use `status.state` to drive UI (active vs in billing retry vs grace period) and `renewalInfo.autoRenewPreference` to detect a pending plan change (e.g. upgrade/downgrade/cross-grade) before it takes effect. Group statuses share a subscription group.

## AppTransaction

`AppTransaction` represents the app purchase itself (useful for paid apps and for "was this app originally bought before date X" gating).

```swift
let result = try await AppTransaction.shared
let appTransaction = try checkVerified(result)
// appTransaction.originalAppVersion, .originalPurchaseDate,
// .appTransactionID (available with AppTransaction on iOS 16+), .originalPlatform
```

`appTransactionID` and `originalPlatform` were added in the 18.4 cycle. Check the concrete type: the SDK back-deploys `Transaction.appTransactionID` to iOS 15, while `AppTransaction` itself requires iOS 16.

## SwiftUI StoreKit views

For paywalls, prefer the built-in views — they handle layout, localization, pricing display, purchase, and offers, and adopt the current design automatically.

```swift
import StoreKit

// Full subscription paywall for a group, with your marketing content.
SubscriptionStoreView(groupID: "ABCD1234") {
    MyMarketingHeader()
}
.subscriptionStoreButtonLabel(.multiline)
.storeButton(.visible, for: .restorePurchases)
.onInAppPurchaseCompletion { product, result in
    // verify + grant
}

// A single product (consumable / non-consumable / one plan).
ProductView(id: "com.app.coins.100")

// A grid/list of products.
StoreView(ids: productIDs)
```

Related modifiers/sheets:
- `.manageSubscriptionsSheet(isPresented:)` — present the system manage-subscriptions UI; the iOS 17+ overload accepts `subscriptionGroupID:` to scope it to one group.
- `.offerCodeRedemption(options:isPresented:onCompletion:)` — the iOS 27+ overload returns a `VerificationResult`; the older overload without `options:` returns `Void` (see `offers-and-retention.md`).
- `.subscriptionStoreControlStyle(...)`, `.subscriptionStorePolicyDestination(...)` for terms/privacy links.
- `.preferredSubscriptionPricingTerms { ... }` (2026) to choose which billing plan a `SubscriptionStoreView` displays (see `commitment-plans.md`).

These views work with your StoreKit configuration file in Xcode previews, so you can build and iterate a paywall without sandbox.

Sources: [current entitlements](https://developer.apple.com/documentation/storekit/transaction/currententitlements), [updates](https://developer.apple.com/documentation/storekit/transaction/updates), and the StoreKit / _StoreKit_SwiftUI interfaces in Xcode 27.0. Reviewed 2026-10-16.
