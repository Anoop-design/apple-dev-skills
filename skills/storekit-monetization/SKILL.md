---
name: storekit-monetization
description: "Implement or debug StoreKit purchases, subscriptions, paywalls, transaction verification, entitlement state, restore, offers, server notifications, and StoreKit testing. Use for Apple in-app purchase integration and App Store monetization operations; consult live Apple terms when the task involves storefront policy or fees."
license: MIT
---

# StoreKit & App Store Monetization (iOS 27 / WWDC 2026)

Reviewed 2026-10-16 against Xcode 27.0 (27A266a), Swift 6.4, and the iOS 27.0 SDK. Check the target platform and deployment version for each API; newer SDK availability does not imply that a consumer service is enabled for every account or region. Code using app stores, routers, or model types is an integration sketch; supply those app-specific dependencies.

Use StoreKit 2 for purchase and entitlement flows. Separate technical API requirements from current App Store business programs, fees, and storefront policies. The references cover core transactions, commitment plans, offers, server integration, testing, and the source checks needed for store operations. Do not use historical rollout dates as current availability.

Use the product’s returned pricing terms and offers for the current storefront. Build advanced business models only after confirming that the account, storefront, runtime, and documented APIs support them.

## Mental model: StoreKit 2

StoreKit 2 is a modern async/await Swift API. The purchase flow is **load `Product`s → `purchase()` → verify the resulting `Transaction` → durably process delivery/entitlement changes → `finish()`**, plus a **transaction listener** for renewals/refunds/purchases made elsewhere, and **`Transaction.currentEntitlements`** as the source of truth for "what does this user own right now." Never trust an unverified transaction; never grant access from a `.unverified` result. Full patterns in `references/storekit2-core.md`.

```swift
import StoreKit

// 1. Load products by ID (configured in App Store Connect).
let products = try await Product.products(for: ["com.app.pro.annual"])

// 2. Purchase.
guard let product = products.first(where: { $0.id == "com.app.pro.annual" }) else {
    // Show unavailable/retry UI; product loading can return an empty or partial list.
    return
}
let result = try await product.purchase()

// 3. Verify, grant, finish.
switch result {
case .success(let verification):
    let transaction = try checkVerified(verification)   // throws on .unverified
    try await processVerifiedTransaction(transaction) // app-defined, idempotent delivery/reconciliation
    await transaction.finish()
case .userCancelled, .pending: break
@unknown default: break
}

// Source of truth for active entitlements (check on launch + via the listener).
var activeProductIDs: Set<String> = []
for await result in Transaction.currentEntitlements {
    if case .verified(let txn) = result,
       txn.productType == .nonConsumable || txn.productType == .autoRenewable {
        activeProductIDs.insert(txn.productID)
    }
}
// Replace the previous entitlement set, so refunds/expiry also remove access.
// Deliver consumables and track non-renewing expiry through separate durable logic.
```

```swift
func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .verified(let safe): return safe
    case .unverified(_, let error): throw error   // do NOT grant access
    }
}
```

## The headline: commitment billing plans

A one-year auto-renewable subscription can now offer a second billing plan — **monthly payments under a 12-month commitment** — to lower the entry price while keeping annual retention. Read both prices off `Product.SubscriptionInfo.pricingTerms`, purchase with `.billingPlanType(.monthly)`, and parse the new `commitmentInfo` on the server.

```swift
let plans = product.subscription?.pricingTerms ?? []
let monthly = plans.first { $0.billingPlanType == .monthly }      // installment plan
// monthly?.billingDisplayPrice            → per-month price
// monthly?.commitmentInfo.displayPrice → full-year total
let result = try await product.purchase(options: [.billingPlanType(.monthly)])
```

**Before enabling it, test monthly entitlement renewal and commitment progress separately.** If the app has a backend, update and test its transaction handling too. Verify storefront eligibility from Apple’s live documentation and returned product metadata. Full client + server + testing detail in `references/commitment-plans.md`.

## Choosing the right tool

| Goal | Reach for | Reference |
|------|-----------|-----------|
| Implement/verify a purchase or restore | StoreKit 2 core + transaction listener | `storekit2-core.md` |
| Build a paywall fast | SwiftUI StoreKit views (`SubscriptionStoreView` etc.) | `storekit2-core.md` |
| Lower entry price on an annual plan | Commitment billing plan | `commitment-plans.md` |
| Reduce churn at cancellation | Retention Messaging | `offers-and-retention.md` |
| Discount/trial/win-back acquisition | Intro / promotional / win-back offers, offer codes | `offers-and-retention.md` |
| Sell to teams / orgs / education | Group Purchases, Volume Purchasing | `subscription-models.md` |
| Combine subscriptions across apps | Bundles / Suites | `subscription-models.md` |
| Validate on a server, handle notifications | App Store Server API / Notifications V2 | `server-and-testing.md` |
| Test without sandbox | StoreKit config files, Transaction Manager | `server-and-testing.md` |
| Refresh store creative / submit IAPs | Creative Assets, Asset Library, submission flow | `app-store-connect-ops.md` |
| Understand fees / external links / compliance | Current Apple terms and storefront requirements | `commission-and-compliance.md` |

## When to read each reference

- **`references/storekit2-core.md`** — the foundation: `Product`, `Transaction`, `currentEntitlements`, verification/JWS, the purchase + restore + listener flow, `Status`/`RenewalInfo`, `AppTransaction`, and the SwiftUI StoreKit views (`SubscriptionStoreView`, `ProductView`, `StoreView`, manage/redeem sheets). Read for any purchase, entitlement, or paywall work.
- **`references/commitment-plans.md`** — the 2026 headline end to end: `pricingTerms`, `billingPlanType`, the `.monthly` purchase option, the `preferredSubscriptionPricingTerms` SwiftUI modifier, server `commitmentInfo` fields, testing, and availability/exclusions.
- **`references/offers-and-retention.md`** — Retention Messaging (App Store Connect-configured + real-time API), the reworked offer-code redemption, introductory/promotional/win-back offers, and `offerType: 5`.
- **`references/subscription-models.md`** — subscription grouping, family access, multi-app and organization requirements, and how to verify newer program availability.
- **`references/server-and-testing.md`** — App Store Server API, App Store Server Notifications V2, decoding `JWSTransaction`/`JWSRenewalInfo` (incl. commitment fields), and the full testing toolkit (config files, Transaction Manager, sandbox, environment differences).
- **`references/app-store-connect-ops.md`** — product configuration, review submissions, assets, and current release checks.
- **`references/commission-and-compliance.md`** — a workflow and authoritative sources for checking storefront rules, fees, external links, and submission requirements.

## Critical gotchas

- Verify every transaction before granting access, including updates and server payloads.
- Start `Transaction.updates` early and retain its task. Recompute active entitlements on changes; a refund notification must not grant access again.
- Finish only after successful durable processing. Deduplicate consumable delivery by transaction ID. Do not finish an event your app has not handled.
- `currentEntitlements` does not implement a consumable balance or the expiry rules for non-renewing subscriptions. Rebuild the supported product entitlement set, rather than only adding to it.
- Commitment end dates describe the contractual period; access is based on the current billing-period entitlement and applicable grace-period status.
- Use StoreKit’s localized prices, tabular digits for custom numeric UI, and stable widths for changing amounts or periods.
- Check the deployment target for each overload. The iOS 27 redemption overload requires `options:`; the older overload returns `Void` on success.

## Primary references

- [StoreKit](https://developer.apple.com/documentation/storekit)
- [Current entitlements](https://developer.apple.com/documentation/storekit/transaction/currententitlements)
- [Transaction updates](https://developer.apple.com/documentation/storekit/transaction/updates)
- [Monthly subscriptions with a 12-month commitment](https://developer.apple.com/documentation/storekit/supporting-monthly-subscriptions-with-a-12-month-commitment)
- [App Store Server API](https://developer.apple.com/documentation/appstoreserverapi)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
