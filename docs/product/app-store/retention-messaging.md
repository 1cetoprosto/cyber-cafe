# Retention Messaging (App Store Connect)

Issue: [#291](https://github.com/1cetoprosto/cyber-cafe/issues/291)  
Roadmap: `v1.2.x` in [`docs/internal/ROADMAP.md`](../../internal/ROADMAP.md)  
Apple help: [Configure retention messages](https://developer.apple.com/help/app-store-connect/manage-subscriptions/configure-retention-messages/)

## Status (2026-11-12)

| Item | Status |
|---|---|
| Repo docs | Done |
| ASC message + EN/UK + offer (no image) | Done (via ASC API) |
| App Review | **WAITING_FOR_REVIEW** (submission `465a8f1a-a0b3-4ee7-964d-29740bef51e1`, image removed 2026-11-12) |
| Sandbox cancel check | After approval |

### ASC IDs

| Resource | ID |
|---|---|
| App | `6753102351` (`ICSOFT.TrackMyCafe`) |
| Retention message | `8c42c653-d724-4783-9c1a-8178df8d38e8` |
| Message version | `135679cd-d46c-4239-8361-8f3dd73126c7` |
| Subscription | `6759736107` (`icsoft.trackmycafe.pro.monthly`) |
| Offer | `retention_50_3m` |
| Image / placement | **None** (offer-first; ineligible → text only) |

## Purpose

Show a value reminder (and optional retention offer) when a subscriber starts canceling TrackMyCafe Pro in the **system** App Store cancel flow.

- **No iOS binary / StoreKit /** `IAPManager` **changes.**
- **No** real-time Retention Messaging API (no IAP server).
- Static configuration in App Store Connect only.

## Products

| Env | Product ID | ASC |
|---|---|---|
| Prod | `icsoft.trackmycafe.pro.monthly` | Linked |
| Beta | `icsoft.trackmycafe.beta.pro.monthly` | **Not present** in ASC subscription groups (skip until created) |

## Subscriber views

| Condition | What they see |
|---|---|
| Eligible for associated retention offer | Header + body **+ offer** |
| Not eligible / no offer | Header + body only (no image attached) |

## Message metadata

| Field | Value |
|---|---|
| Reference name (ASC only) | `Pro Monthly Stay — Value + Offer` |
| Localizations required | English, Ukrainian (add any other live storefronts) |

### Copy rules (App Review)

- Header and body must **not** mention prices, discounts, “50%”, “free”, “offer”, or specific promo terms.
- Factual “you lose Pro features if you cancel” is OK.
- Align tone with [`POSITIONING_AND_COPY.md`](../POSITIONING_AND_COPY.md): profit isn’t revenue.

### Length limits (safe for ASC + Retention Messaging API)

Keep header ≤ **66** characters and body ≤ **144** characters (UTF-8). Counts below are within those caps.

### English (`en-US`)

**Header:** Stay with profit, not just revenue  
*(34 chars)*

**Body:** Pro shows what’s left after supplies, rent, and payroll — not just sales. If you cancel, you lose access to these tools when the period ends.  
*(141 chars)*

### Ukrainian (`uk`)

**Header:** Залишайтеся з прибутком, а не лише з виручкою  
*(45 chars)*

**Body:** Pro показує, що залишається після закупок, оренди й зарплат. Якщо скасуєте підписку, доступ до цих інструментів зникне наприкінці періоду.  
*(138 chars)*

## Image

**Not used in ASC** (placement removed). Reason: message already has offer `retention_50_3m`; eligible cancel flow shows offer instead of image, and a single shared image can’t be localized EN/UK cleanly.

Optional assets kept in repo for later: [`retention/retention-pro-value-3840x2160.jpg`](retention/retention-pro-value-3840x2160.jpg).

## Retention offer

| Parameter | Value |
|---|---|
| Reference name | `Pro Monthly Retention 50% x3` |
| Offer identifier | `retention_50_3m` |
| Type | Pay as you go |
| Discount | 50% of current monthly price |
| Duration | 3 months, then regular price |
| Paid Subscription Duration (eligibility) | 1 month paid minimum |
| Wait Between Offers | 12 months |
| Territories | USA base price $4.99 (≈50% of $9.99); equalize other storefronts in ASC UI if needed after approve |
| Associate with | Prod monthly (beta product absent in ASC) |

Offer identifier and reference name cannot be changed after create — double-check before saving.

## ASC checklist

1. [x] Create retention message `Pro Monthly Stay — Value + Offer`.
2. [x] EN + UK header/body.
3. [x] No image (intentionally; offer-first).
4. [x] Assign `icsoft.trackmycafe.pro.monthly`.
5. [x] Create/link retention offer `retention_50_3m`.
6. [x] Submit for App Review (`WAITING_FOR_REVIEW`).
7. [х] After approve: Sandbox eligible cancel → text+offer; ineligible → text only.
8. [ ] Optional: equalize offer prices beyond USA; add beta product if/when it exists in ASC.

## DoD

- [x] Message submitted (EN + UK) — awaiting App Review.
- [x] Image not attached (offer-first).
- [x] Offer created, eligibility/wait set, linked to prod monthly.
- [ ] App Review approved.
- [ ] Sandbox paths verified (offer vs text-only).

## Out of scope

- Swift code, SwiftyStoreKit, paywall UI.
- Real-time Retention Messaging API / server endpoint.
- Requiring a new app version binary to ship this.
