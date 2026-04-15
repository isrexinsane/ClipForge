# Epic 8 — Subscription (StoreKit 2)

**Status:** ⬜ Not Started

## Scope

Integrate StoreKit 2 for App Store subscription management. Single product: $9.99/year unlimited + no watermark.

## Implementation

- **Product ID:** `com.roninartouse.clipforge.premium.yearly`
- **Entitlement:** Binary "premium" flag (user has active subscription or not)
- **Pricing:** $9.99 USD/year, localized pricing in other regions
- **Billing:** Annual auto-renewal with 3-day free trial (standard App Store promotion)

## Setup

1. Create product in App Store Connect
2. Configure entitlements in Xcode (com.apple.developer.storekit.subscription)
3. Implement StoreKit 2 SKProduct query in `SubscriptionManager`
4. Handle purchase flow: PurchaseManager wraps SKPaymentQueue
5. Listen to transaction updates (transaction.updates async sequence)

## Dependencies

- ✅ [[Epic 7 — Premium Features]] — must detect premium status

## Wikilinks

- [[Epic_Breakdown]] — Full plan
- [[Dashboard]] — Sprint tracking
- [[PRD]] — Subscription details

## Notes

StoreKit 2 is the modern replacement for StoreKit 1 (in-app purchase framework). Transactions sync automatically across user's devices via iCloud. No server-side subscription tracking needed for MVP.
