# Offers & Retention: Offer Codes, Retention Messaging, Intro/Promo/Win-Back

The toolkit for acquisition, discounting, and churn reduction. The 2026 headline here is **Retention Messaging** (reach a subscriber at the cancellation moment) and a **reworked offer-code redemption** flow; the established offer types (introductory, promotional, win-back) continue.

## Table of Contents
- [Offer types at a glance](#offer-types-at-a-glance)
- [Introductory offers](#introductory-offers)
- [Promotional offers](#promotional-offers)
- [Win-back offers](#win-back-offers)
- [Offer codes (reworked redemption)](#offer-codes-reworked-redemption)
- [Retention Messaging](#retention-messaging)
- [Offer signaling in transactions](#offer-signaling-in-transactions)

## Offer types at a glance

| Offer | Who it targets | Configured | Eligibility |
|-------|----------------|-----------|-------------|
| **Introductory** | New subscribers (never subscribed in the group) | App Store Connect | Automatic, one per group |
| **Promotional** | Existing/lapsed subscribers, in-app | App Store Connect + signed in app | You decide; server-signed |
| **Win-back** | Lapsed subscribers, surfaced by Apple | App Store Connect | Apple surfaces on the store + your app |
| **Offer code** | Anyone with a code (acquisition, support, B2B) | App Store Connect | Code-gated |
| **Retention** (2026) | Subscribers at the cancellation moment | App Store Connect or real-time API | Triggered at cancel |

## Introductory offers

A free trial or reduced-price intro for first-time subscribers in a group, configured entirely in App Store Connect. Check eligibility before presenting:

```swift
if let sub = product.subscription,
   let intro = sub.introductoryOffer,
   await sub.isEligibleForIntroOffer {
    // present the trial / intro price (intro.paymentMode: .freeTrial / .payAsYouGo / .payUpFront)
}
```

## Promotional offers

Discounts for **existing or lapsed** subscribers, presented inside your app. These require a **server-signed** offer (a JWS signature your backend produces with your subscription key) passed as a purchase option:

```swift
// iOS 26+ JWS API. The backend supplies the offer ID and compact JWS.
let options = Set(Product.PurchaseOption.promotionalOffer(offerID, compactJWS: signedOffer))
let result = try await product.purchase(options: options)
```

Use these for targeted retention/upsell when you know who the user is.

## Win-back offers

Introduced in the 2024 cycle: discounts targeting **lapsed** subscribers that **Apple can surface on the App Store** (subscription page, etc.) as well as in your app. Configure in App Store Connect; present in-app via the subscription's available win-back offers. No major 2026-specific change beyond the broader retention work — but pair them with Retention Messaging below.

## Offer codes (reworked redemption)

Offer codes work for consumables, non-consumables, auto-renewable and non-renewing subscriptions. The **2026 change is the in-app redemption sheet now behaves like a purchase** — on completion it returns a `VerificationResult`, and the API accepts a set of `RedeemOption`s.

```swift
// SwiftUI
.offerCodeRedemption(options: [], isPresented: $presenting) { result in
    switch result {
    case .success(let verificationResult):
        if case .verified(let txn) = verificationResult {
            Task {
                do {
                    try await processVerifiedTransaction(txn) // durable, idempotent app logic
                    await txn.finish()
                } catch {
                    handle(error) // leave unfinished for recovery
                }
            }
        }
    case .failure(let error):
        handle(error)
    }
}
```

The `options:` parameter selects the iOS 27+ overload. Its completion closure is synchronous, so use a task for asynchronous processing. Keep the transaction listener and deduplicate delivery, because the same transaction can be observed through more than one path. The older overload without `options:` returns `Result<Void, Error>`.

## Retention Messaging

New in 2026 (session 309). When a subscriber goes to **cancel**, the App Store can present custom messaging about the subscription's value (with imagery) and optionally an offer — **without adding friction to the cancellation flow itself**. Two modes:

**1. App Store Connect-configured.** Author messages (text + Asset Library imagery) and optionally attach a **retention offer**; the App Store delivers them automatically at cancellation. Testable in sandbox. Lowest effort — start here.

**2. Real-time Retention Messaging API.** For dynamic, per-user decisions. When a subscriber moves to cancel, the App Store makes a **server-to-server call to your configured endpoint** and you respond in real time.

Use the current [Retention Messaging API](https://developer.apple.com/documentation/retentionmessaging) schemas for endpoint registration, authenticated payloads, message/alternate-plan/promotional-offer responses, deadlines, and fallback behavior. Confirm program access and test in sandbox before enabling production messages. Do not block cancellation if your service is unavailable.

Choose App Store Connect-configured messages when they meet the need. Use a real-time endpoint when the feature needs account-specific decisions and the service can meet Apple’s documented response requirements.

## Offer signaling in transactions

Offers surface in signed transactions so your backend can attribute them:
- `offerType`: `1` introductory, `2` promotional, `3` offer code, `4` win-back, and `5` retention; tolerate unknown future values and verify against the current server schema.
- `offerIdentifier`, `offerDiscountType` (e.g. `FREE_TRIAL`, `PAY_AS_YOU_GO`, `PAY_UP_FRONT`), and `offerPeriod` (e.g. `"P3M"`).

Parse these to measure offer performance and to avoid double-granting.

Sources: [offer-code redemption overload](https://developer.apple.com/documentation/swiftui/view/offercoderedemption(options:ispresented:oncompletion:)), [Retention Messaging](https://developer.apple.com/documentation/retentionmessaging), and the Xcode 27 StoreKit interfaces. Reviewed 2026-10-16.
