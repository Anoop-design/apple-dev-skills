# Storefront Rules, Fees, and Compliance

Reviewed 2026-10-16. Business terms, court decisions, program enrollment, and storefront rules can change independently of the SDK. This reference deliberately does not freeze commission rates or legal deadlines into reusable implementation instructions.

## Determine the applicable rules

1. Identify the product: digital content or functionality, physical goods/services, reader access, enterprise access, or another documented category.
2. Identify each storefront, distribution channel, developer agreement/program, and customer/account eligibility that affects the flow.
3. Read the current agreement and the matching Apple support page. Record the source URL, effective date, and date checked alongside the decision.
4. Check required capabilities, entitlements, disclosures, reporting, and permitted combinations of payment methods. Do not extrapolate one region’s external-payment rules globally.
5. For a pricing model, include payment processing, applicable Apple fees, tax handling, refunds, subscription retention, and implementation/support costs using verified inputs.

## Primary sources

- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) — permitted purchase flows and review requirements.
- [Agreements and Guidelines](https://developer.apple.com/support/terms/) — governing agreements and program terms.
- [App Store Small Business Program](https://developer.apple.com/app-store/small-business-program/) — enrollment and current eligibility.
- [Auto-renewable subscriptions](https://developer.apple.com/app-store/subscriptions/) — subscription business rules.
- [App Store Connect Help](https://developer.apple.com/help/app-store-connect/) — product setup, agreements, pricing, tax, and submissions.
- [Upcoming requirements](https://developer.apple.com/news/upcoming-requirements/) — dated submission requirements; verify applicability to the app.
- [Apple Developer support](https://developer.apple.com/support/) — current regional distribution and payment documentation.

## Implementation boundaries

Keep entitlement logic independent of display prices and marketing copy. Use the current `Product` and storefront, and re-fetch when storefront context changes. A permitted payment link does not imply an exemption from fees, reporting, age restrictions, or regional disclosures. Explain unresolved policy interpretation with its precise source and scope; do not treat a stale summary as legal authority.
