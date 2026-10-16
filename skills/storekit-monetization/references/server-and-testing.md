# Server-Side Validation & Testing

How to validate purchases and react to lifecycle events on a server, and how to test the whole IAP surface without (and with) sandbox. The server APIs are stable; the 2026 additions are the commitment-plan fields in the signed payloads.

## Table of Contents
- [Why validate server-side](#why-validate-server-side)
- [App Store Server API](#app-store-server-api)
- [App Store Server Notifications V2](#app-store-server-notifications-v2)
- [Decoding signed payloads (JWS)](#decoding-signed-payloads-jws)
- [The App Store Server Library](#the-app-store-server-library)
- [Testing without sandbox](#testing-without-sandbox)
- [Sandbox testing](#sandbox-testing)
- [Known issues](#known-issues)

## Why validate server-side

StoreKit’s on-device verification is appropriate for client-side purchases; a modified client cannot be trusted to authorize access to server resources. A server check via the App Store Server API gives you an authoritative, tamper-resistant view of entitlements, protects feature unlocks behind your backend, and lets you react to renewals/refunds even when the app isn't running. If the app gates server resources, enforce access on the server using independently verified transaction data. A client-only app does not automatically require an additional backend.

## App Store Server API

A REST API (JWT-authenticated with an App Store Connect key) to query and act on transactions:
- **Get Transaction History** / **Get Transaction Info** — full signed history for an `originalTransactionId` or `transactionId`.
- **Get All Subscription Statuses** — current status for every subscription in a group for a user.
- **Send/Consume** consumption info, **Extend** a subscription renewal date, **request a test notification**, look up an order ID, and get refund history.
- Use the **`appAccountToken`** you set at purchase to correlate Apple transactions with your own user records.

Responses contain **signed** (JWS) transaction and renewal-info objects you decode and verify.

## App Store Server Notifications V2

Apple POSTs signed event notifications to your configured URL (set per environment in App Store Connect). Handle these to keep entitlements current without polling. Notable `notificationType`s: `SUBSCRIBED`, `DID_RENEW`, `DID_CHANGE_RENEWAL_STATUS`, `DID_CHANGE_RENEWAL_PREF`, `EXPIRED`, `GRACE_PERIOD_EXPIRED`, `DID_FAIL_TO_RENEW` (with `subtype` like `GRACE_PERIOD`), `REFUND`, `REVOKE`, `OFFER_REDEEMED`, `PRICE_INCREASE`, `RENEWAL_EXTENSION`, plus `subtype`s that disambiguate (e.g. `UPGRADE`/`DOWNGRADE`).

For **commitment plans**, renewal notifications fire for **each monthly installment** across the 12-month commitment — don't assume one renewal event per year for those products.

Verify the signed notification and durably enqueue or process it before acknowledging success. Apple retries failures: deduplicate event delivery by `notificationUUID`, and deduplicate fulfillment by transaction ID. Do not discard a later refund or status change merely because its transaction ID was seen previously. Reconcile out-of-order events against current status; provide recovery for missed notifications.

## Decoding signed payloads (JWS)

Transaction and renewal objects arrive as JWS. Verify the signature chain and the expected app/bundle, environment, and relevant payload claims using Apple’s library, then process the payload. Decoding base64 alone is not verification. The 2026 commitment fields to expect:

In a decoded **`JWSTransaction`**:
- `billingPlanType` (e.g. `"MONTHLY"`).
- `commitmentInfo` → `billingPeriodNumber`, `totalBillingPeriods` (12), `commitmentExpiresDate`, `commitmentPrice`.

In a decoded **`JWSRenewalInfo`**:
- `renewalBillingPlanType`.
- `commitmentInfo` → `commitmentAutoRenewProductId`, `commitmentAutoRenewStatus`, `commitmentRenewalDate`, `commitmentRenewalPrice`, `commitmentRenewalBillingPlanType` (e.g. `"BILLED_UPFRONT"`).

Offer fields (`offerType` including `5` for retention, `offerIdentifier`, `offerDiscountType`, `offerPeriod`) also live here — see `offers-and-retention.md`.

## The App Store Server Library

Use Apple's official [App Store Server Libraries](https://developer.apple.com/documentation/appstoreserverapi) (Swift, Java, Python, Node) rather than hand-rolling JWS verification. It handles signature-chain verification, decoding, receipt/transaction-ID extraction, and request signing for the Server API. This is the recommended path and avoids subtle crypto mistakes.

## Testing without sandbox

The fastest loop is a **StoreKit configuration file** in Xcode:
- Define products, subscriptions, groups, intro/promo offers, and (Xcode 26.5+) **billing plans** including the commitment plan via the Billing Plan picker.
- Run in the simulator/device with the config enabled in the scheme; the **Transaction Manager** lets you inspect, refund, expire, advance time/renewals, and trigger billing issues — including confirming `commitmentInfo` on commitment transactions.
- SwiftUI StoreKit views render against the config in **Xcode previews**, so you can build a paywall with no network.
- The **StoreKit Testing in Xcode** framework (`SKTestSession`) drives this from unit/UI tests for deterministic CI coverage of purchase, restore, renewal, refund, and offer flows.

## Sandbox testing

For end-to-end validation against Apple's servers, use **Sandbox Apple Accounts** (App Store Connect → Users and Access → Sandbox). Sandbox exercises the real purchase pipeline, Server API, and Server Notifications (point notifications at a reachable test URL). Sandbox subscription durations are accelerated. Retention Messaging's App Store Connect-configured mode is testable in sandbox; the real-time API offers a sandbox-only performance test.

## Known issues

- When a test differs from sandbox or production, check the installed Xcode and OS release notes for that exact symptom; do not assume a historical beta issue explains it.
- Always test the **transaction listener** path (renewals/refunds arriving outside `purchase()`), not just the happy-path purchase — it's the most common source of "entitlement didn't update" bugs.

Sources: [App Store Server API](https://developer.apple.com/documentation/appstoreserverapi), [Server Notifications](https://developer.apple.com/documentation/appstoreservernotifications), and [StoreKit testing](https://developer.apple.com/documentation/storekittest). Reviewed 2026-10-16. Local StoreKit tests do not establish production notification delivery.
