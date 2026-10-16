# Release review checklist

Checked 2026-10-16. This is a scoped preparation checklist, not a guarantee of acceptance. Recheck current Apple rules for the app’s distribution channel, storefronts, business model and SDK before asserting a policy finding.

## Product and evidence

Verify the critical journeys in the actual release configuration, including loading, empty/error states, denied permissions and interrupted work. Check supported OS/device coverage and use isolated data for fresh-install testing; do not delete the owner’s app data to simplify a review. Keep device verification, archive validation, TestFlight and App Store approval as distinct outcomes.

## Submission policy

- Provide a complete app, accurate metadata and working support/privacy links. Give reviewers access to account-gated functionality and explain non-obvious features.
- Check current payment rules and exceptions for the relevant storefronts and product type. Digital goods, physical goods, reader services and other permitted categories do not have identical payment rules; external links are not universally forbidden.
- Review guideline 4.8’s login-service scope and exceptions before requiring Sign in with Apple. Check in-app account-deletion requirements where the app supports account creation.
- Review moderation/reporting/blocking needs for user-generated content and confirm asset rights.

Source: [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/).

## Privacy and permissions

Inspect first- and third-party code for required-reason APIs, data collection and tracking, and ensure the built bundle includes the declarations that apply. A privacy manifest is not a blanket requirement solely because the deployment target is iOS 17. Audit included SDK manifests and signatures where Apple requires them. Explain permissions accurately and request them in the relevant user flow. ATT concerns tracking as Apple defines it; analytics alone is not sufficient evidence that ATT is needed.

Sources: [Privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files), [required-reason APIs](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api), [App Tracking Transparency](https://developer.apple.com/documentation/apptrackingtransparency).

## Purchases

Verify the actual transaction/entitlement flow, cancellation, pending status, renewal where applicable and a restore mechanism for restorable purchases. Do not require a restore operation for consumables or assume a successful simulator StoreKit test proves production purchasing. Check displayed price, period and subscription terms against returned product information.

Source: [In-app purchase](https://developer.apple.com/in-app-purchase/).

## Quality and distribution

- Verify VoiceOver names/order/actions, large text, contrast, Reduce Motion and meaningful alternatives to gesture-only controls.
- Numeric labels use tabular glyphs and stable changing-value widths while preserving the chosen letterforms.
- Check the built app’s identity, version, entitlements, privacy resources, supported orientations and release configuration.
- Resolve warnings according to their impact; a deprecation warning alone is not automatically a rejection. Avoid private APIs.
- Check current accepted SDK/Xcode versions and required metadata/assets. Screenshots must accurately show the app; Apple permits explanatory overlays in appropriate assets.

Sources: [Accessibility HIG](https://developer.apple.com/design/human-interface-guidelines/accessibility), [Upcoming requirements](https://developer.apple.com/news/upcoming-requirements/), [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/).

Report observed failures with evidence and impact, optional improvements separately, and unsupported or untested requirements as open verification gaps. Upload/submission is a separate external action and follows the user’s actual authorization.
