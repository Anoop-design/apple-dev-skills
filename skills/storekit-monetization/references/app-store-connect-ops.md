# App Store Connect Operations

Use the live [App Store Connect Help](https://developer.apple.com/help/app-store-connect/) and [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi) for release operations. Console workflows and submission endpoints can change independently of StoreKit.

## Product setup and submission

- Confirm the Paid Applications agreement, tax/banking setup, product identifiers, availability, pricing, localization, subscription group, and required review metadata.
- Product loading can return only a subset of requested identifiers. Diagnose missing products using the active environment and product configuration, rather than indexing the first array element.
- Follow the current first-IAP submission requirements and app-version association rules. Use supported API resources for review submissions only after checking their documented relationship types and permissions.
- Distinguish saving a draft, submitting to review, and making an approved product available. Perform external mutations only within the user’s requested release scope.

## Assets and merchandising

Use supported screenshot, preview, event, custom-product-page, and other asset workflows for the account. Check which assets require review and whether approval can occur independently of an app version. Inspect localized prices and offer disclosures in the actual paywall and store preview before release.

## Release checks

Test product discovery, purchase, pending approval, cancellation, restore, renewal, refund, revocation, and storefront changes. Use sandbox for server integration; a StoreKit configuration file does not validate App Store Connect setup. Check [upcoming requirements](https://developer.apple.com/news/upcoming-requirements/) for current declarations and deadlines that apply to the app.

Reviewed 2026-10-16. This workflow does not embed historical launch dates or assume new merchandising programs are enabled for every account.
