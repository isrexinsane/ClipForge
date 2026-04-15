# Epic 7 — Premium Features

**Status:** ⬜ Not Started

## Scope

Implement freemium gate and premium unlock features.

**Free tier:** 1 GIF per day (resets at midnight UTC)
**Premium ($9.99/year):** Unlimited GIFs + no watermark

## Features

- **Daily limit gate:** Count GIFs created per calendar day, block export on free tier after 1/day limit reached
- **Premium detection:** StoreKit 2 query on app launch
- **Watermark toggle:** Logomark applied in free tier; removed for premium users
- **Settings screen:** Display current subscription status, option to manage subscription in app

## Implementation

- `SubscriptionManager` service wraps StoreKit 2 entitlement queries
- `GIFEncoder` accepts premium flag; skips watermark if true
- `HomeViewModel` checks daily count before allowing encode

## Dependencies

- ✅ [[Epic 5 — GIF Encoding Engine]] — watermark system must exist
- ✅ [[Epic 6 — Export & Gallery]] — daily count tracking needs persistent storage

## Wikilinks

- [[Epic_Breakdown]] — Full plan
- [[Dashboard]] — Sprint tracking
- [[PRD]] — Freemium model details
- [[Design_Decisions]] — Monetization decisions

## Notes

StoreKit 2 binds subscription to iCloud account. No user login UI needed. Premium state persists automatically across devices via iCloud.
