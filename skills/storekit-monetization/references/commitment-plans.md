# Commitment Billing Plans (Monthly with a 12-Month Commitment)

The headline StoreKit change of the 2026 cycle (WWDC26 session 210, "What's new in Apple In-App Purchase"). A one-year auto-renewable subscription can offer a second billing plan where the customer **commits to a full year but pays in 12 monthly installments** — lowering the entry price while preserving annual-style retention. This is end-to-end: App Store Connect setup, client API, SwiftUI, server fields, and testing.

## Table of Contents
- [Availability and exclusions](#availability-and-exclusions)
- [App Store Connect setup](#app-store-connect-setup)
- [Reading pricing terms](#reading-pricing-terms)
- [Purchasing a commitment plan](#purchasing-a-commitment-plan)
- [SwiftUI: choosing the plan to show](#swiftui-choosing-the-plan-to-show)
- [Server-side fields](#server-side-fields)
- [Testing](#testing)
- [Rollout checklist](#rollout-checklist)

## Availability and exclusions

- **Runtime:** iOS, iPadOS, macOS Tahoe, tvOS, and visionOS **26.4 or later** — this is **not** iOS-27-only; it back-deploys to the 26.4 generation.
- **Build requirement:** use the **Xcode 26.5 SDK or later**, per Apple’s feature documentation; verified here with Xcode 27.0.
- **Geographic exclusion:** available **worldwide except the United States and Singapore.** Plan your merchandising and rollout around that — in those storefronts only the up-front annual plan exists.

## App Store Connect setup

On an existing **one-year** auto-renewable subscription: open the subscription → "Set Up Availability" / billing → add a billing plan of type **"monthly with a 12-month commitment."** Configure the monthly price; the full-year total is derived. You can attach offers per billing plan. The classic plan remains as the **up-front** billing plan; the new one is the **monthly** plan.

## Reading pricing terms

`Product.SubscriptionInfo` gains a `pricingTerms` array. Every auto-renewable subscription has at least one entry (`.upFront`); a configured commitment plan adds a `.monthly` entry. Billing-plan data only returns when available in the customer's storefront.

```swift
guard let sub = product.subscription else { return }
let plans = sub.pricingTerms

let upFront = plans.first { $0.billingPlanType == .upFront }   // pay-now annual
let monthly = plans.first { $0.billingPlanType == .monthly }   // 12 installments

// Merchandise both numbers:
let perMonth   = monthly?.billingDisplayPrice                  // e.g. "$4.99 / mo"
let yearTotal  = monthly?.commitmentInfo.displayPrice // full-year commitment total
let commitPrice = monthly?.commitmentInfo.price
```

Show the per-month price as the headline with the full-year commitment total as the disclosure, so customers understand they're committing to 12 payments. `commitmentInfo` in `PricingTerms` is non-optional; `monthly` in this example is optional. Use the localized `displayPrice` for the total, not a nonexistent `totalCommitmentPrice` field.

## Purchasing a commitment plan

Pass the billing-plan purchase option:

```swift
let result = try await product.purchase(options: [.billingPlanType(.monthly)])
```

Before the **first-time** commitment subscribe, the system shows a disclosure sheet explaining the 12-month commitment. Handle the `result` exactly like any other purchase (verify → grant → finish).

## SwiftUI: choosing the plan to show

`SubscriptionStoreView` displays a billing plan per product; pick which one with the new `preferredSubscriptionPricingTerms` modifier:

```swift
SubscriptionStoreView(groupID: "3F19ED53") {
    MyMarketingContent()
}
.preferredSubscriptionPricingTerms { _, subscriptionInfo in
    // Prefer the installment plan where it exists; the view falls back otherwise.
    subscriptionInfo.pricingTerms.first { $0.billingPlanType == .monthly }
}
```

This lets you A/B the entry experience (lead with the lower monthly number) without separate products.

## Server-side fields

If the app has a backend, parse and test the signed commitment fields before enabling the feature. Access depends on each current billing-period entitlement, including applicable grace rules. The commitment end date describes the overall obligation; it must not unlock the entire year regardless of payment status.

In the decoded **`JWSTransaction`**:
- `billingPlanType` (e.g. `"MONTHLY"`).
- `commitmentInfo`: `billingPeriodNumber` (which of the 12), `totalBillingPeriods` (12), `commitmentExpiresDate`, `commitmentPrice`.

In the decoded **`JWSRenewalInfo`**:
- `renewalBillingPlanType`.
- `commitmentInfo`: `commitmentAutoRenewProductId`, `commitmentAutoRenewStatus`, `commitmentRenewalDate`, `commitmentRenewalPrice`, `commitmentRenewalBillingPlanType` (e.g. `"BILLED_UPFRONT"` — note a commitment plan can renew into an up-front plan).

**A subscription notification fires for every monthly renewal** throughout the 12-month commitment, not just once a year — make sure your notification handling and analytics don't assume one event per year for these products.

## Testing

You can exercise the whole feature locally in Xcode 26.5+ without sandbox:
1. Open the StoreKit configuration file, select a one-year auto-renewable subscription.
2. Use the new **Billing Plan picker** to add "monthly with a 12-month commitment"; set the monthly price; attach per-billing-plan offers if needed.
3. Run the purchase with `.billingPlanType(.monthly)`.
4. In the **Transaction Manager**, inspect the transaction and confirm `commitmentInfo` (period number, total periods, commitment expiry) appears as expected; advance time to simulate monthly renewals.

Test with the installed Xcode’s release notes when a specific failure reproduces; do not retain a point-release workaround without its exact issue and supported versions.

## Rollout checklist

1. **Backend, if used** — parse and store the new `commitmentInfo` fields in both transaction and renewal info; handle a monthly-renewal notification cadence for these products; verify expiry/grace logic across a full simulated 12-month cycle.
2. **Client** — read `pricingTerms`, display per-month + full-year-total clearly, purchase with `.billingPlanType(.monthly)`.
3. **Paywall** — use `preferredSubscriptionPricingTerms` to surface the installment plan where it exists.
4. **Geography** — gate/adjust merchandising for the **US and Singapore**, where the plan isn't offered.
5. **Only then** enable the billing plan in App Store Connect.

Sources: [Apple’s commitment-plan implementation guide](https://developer.apple.com/documentation/storekit/supporting-monthly-subscriptions-with-a-12-month-commitment) and [server commitment information](https://developer.apple.com/documentation/appstoreserverapi/transactioncommitmentinfo). Reviewed 2026-10-16. Recheck storefront eligibility when enabling the plan.
