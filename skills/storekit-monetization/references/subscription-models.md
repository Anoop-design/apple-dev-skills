# Subscription Packaging and Multi-user Access

Choose a model from the customer’s access requirements, then verify the currently available App Store program and APIs. A conference announcement does not establish account enrollment, storefront coverage, runtime availability, or production server payloads.

## Established decisions

- **One person, several subscription tiers:** organize mutually exclusive plans in a subscription group, with deliberate service levels and upgrade/downgrade behavior.
- **Family access:** evaluate StoreKit Family Sharing support, configure it in App Store Connect, and handle family-sharing ownership and revocation.
- **Several apps:** determine whether access comes from one app’s subscription, an account-based service, or an explicitly supported bundle program. Do not infer that a paid-app bundle is a subscription bundle.
- **Teams or organizations:** decide who pays, owns, assigns, and revokes seats, and how Apple transactions map to your account system. Never interpret consumable `quantity` as subscription seats unless a documented API explicitly provides that meaning.

## Newer bundles, suites, group and volume programs

For a task involving these programs, consult [Apple subscriptions](https://developer.apple.com/app-store/subscriptions/), [App Store Connect Help](https://developer.apple.com/help/app-store-connect/), and the current [StoreKit documentation](https://developer.apple.com/documentation/storekit). Confirm the exact client types, purchase options, server fields, and account configuration before designing code. If the program is unavailable to the account, describe that constraint and choose a supported approach with the user.

Test who keeps access after cancellation, seat reassignment, family removal, account changes, refund, and billing failure. Keep app-user identity distinct from the Apple Account responsible for billing.

Reviewed 2026-10-16 against the Xcode 27 SDK; this file makes no claim that every announced program is available to every developer.
