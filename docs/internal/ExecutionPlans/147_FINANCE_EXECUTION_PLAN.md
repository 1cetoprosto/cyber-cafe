# Finance #147 Execution Plan

Project: `TrackMyCafe`
Parent issue: `#147`
Release: `v1.0.8`
Approach: `Firestore-only`
Branches: `4 PR flow`

## 1. Global Context

We are implementing issue `#147` for `TrackMyCafe`.

### Goal

Implement trustworthy and fast `cash/card balances` using:

- `journal_entries`
- `daily_balances`

### Accepted Interpretation

- Firestore collections: `journal_entries`, `daily_balances`
- Offline: rely on Firestore local persistence
- Realm: no new models, no new sync layer

### Why

Current Home balances are not true balances.
They are derived too simplistically from `OrderModel.cash` / `OrderModel.card`.
`OpexExpenseModel` currently does not affect cash/card balances correctly because it has no payment method.
We need correctness for historical edits and fast Home refresh without full scans.

### Architectural Constraints

- Platform: iOS 15+
- UI: UIKit only
- Architecture: MVVM
- ViewModels must not import UIKit
- Async: prefer async/await
- Logging: OSLog / Logger only
- No force unwraps
- Firestore is the source of truth
- Do not introduce new Realm-based finance infrastructure

### Domain Direction

We want:

- `PaymentAccount` enum: `cash`, `card`
- `JournalEntry`
- `DailyBalance`
- Opex payment method
- Storno-based updates for historical edits
- Home reading balances from `DailyBalance(today)`

### Out Of Scope

- Full P&L
- Reports UI
- ABC / Trends
- New Realm migration/sync work
- Large inventory workflow

### General Implementation Rules

- Keep business logic out of ViewControllers
- Do not duplicate finance formulas in UI
- Prefer finance-specific services over scattered mutation logic
- Every PR must be mergeable and testable on its own
- Keep changes aligned with existing docs and issue `#147`

---

## 2. Branch Strategy

### Branch 1

Name: `feat/147-pr1-contracts-persistence`
Covers: `#210 + #211`

### Branch 2

Name: `feat/147-pr2-journal-engine`
Covers: `#212 + #213`

### Branch 3

Name: `feat/147-pr3-home-ui-daily-balance`
Covers: `#214`

### Branch 4

Name: `feat/147-pr4-backfill-hardening`
Covers: `#215 + #216`

### Merge Order

1. PR1
2. PR2
3. PR3
4. PR4

Each new branch must be created from fresh `main` after previous PR merge.

---

## 3. PR1 Context

Branch: `feat/147-pr1-contracts-persistence`
Issues: `#210`, `#211`

### PR1 Objective

Define the domain contracts and Firestore persistence needed for journal-based balances.

### PR1 What Must Be Implemented

- Add `PaymentAccount` enum with `cash` and `card`
- Extend `OpexExpenseModel` with payment method
- Add domain model(s):
  - `JournalEntryModel`
  - `DailyBalanceModel`
- Add supporting enums:
  - `JournalSourceType`
- Add Firestore DTO/models for:
  - `journal_entries`
  - `daily_balances`
- Add collection constants for:
  - `journal_entries`
  - `daily_balances`
- Add storage/repository methods in the domain/data layer needed for:
  - save journal entry
  - fetch journal entries
  - save daily balance
  - fetch daily balance(s) by account/date or range

### PR1 Expected Files To Touch

Likely areas:

- `TrackMyCafe/Data Layer/Models/Domain/`
- `TrackMyCafe/Data Layer/Models/Firestore/`
- `TrackMyCafe/Data Layer/Models/Domain/OpexExpenseModel.swift`
- `TrackMyCafe/Data Layer/Utils/Constants.swift`
- `TrackMyCafe/Services/Domain/DomainDB.swift`
- `TrackMyCafe/Services/Domain/DomainDatabaseService.swift`

### PR1 Important Constraints

- No Realm additions
- No UI changes yet
- No business mutation logic yet
- Keep storage contracts clean enough for PR2

### PR1 Definition Of Done

- Domain types compile
- Firestore persistence types compile
- No new Realm code
- PR is mergeable independently
- Code reflects `Firestore-only` interpretation of `#147`

### PR1 Prompt For New AI Chat

You are working on `TrackMyCafe` issue `#147`, branch `feat/147-pr1-contracts-persistence`.

Goal:
Implement domain contracts and Firestore persistence for journal-based balances.

Accepted interpretation:

- Firestore collections: `journal_entries`, `daily_balances`
- Offline: rely on Firestore local persistence
- Realm: no new models, no new sync layer

Do:

- Add `PaymentAccount`
- Extend `OpexExpenseModel` with payment method
- Add domain models for `JournalEntry` and `DailyBalance`
- Add Firestore DTO/models
- Add collection constants
- Add repository/service contracts needed for saving/fetching journal entries and daily balances

Do not:

- Implement full journal logic yet
- Change Home UI yet
- Add Realm models
- Add reporting logic

Need:

- Follow UIKit + MVVM project rules
- Prefer async/await where practical
- Keep ViewModels free of UIKit
- Show a concrete implementation plan before edits

---

## 4. PR2 Context

Branch: `feat/147-pr2-journal-engine`
Issues: `#212`, `#213`

### PR2 Objective

Implement the journal engine, storno logic, daily balance materialization, and wire it into order/opex mutations.

### PR2 What Must Be Implemented

- Add finance-specific service(s), for example:
  - `BalanceJournalService`
  - `DailyBalanceMaterializer`
- Implement logic for:
  - order create -> journal entries
  - order update -> storno old entries + add new entries
  - order delete -> reversal/storno
  - opex create -> journal entry using payment account
  - opex update -> storno + new entry
  - opex delete -> reversal/storno
- Materialize/update `DailyBalance` incrementally
- Recompute only affected dates/accounts
- Move balance mutation ownership away from scattered UI logic

### PR2 Expected Files To Touch

Likely areas:

- `TrackMyCafe/Services/Domain/`
- new finance service files
- `TrackMyCafe/View Layer/Flow/Orders/.../OrderDetailsViewModel.swift`
- `TrackMyCafe/Services/Domain/DomainCostDataService.swift`
- `TrackMyCafe/View Layer/Flow/Costs/.../CostListViewModel.swift`
- `TrackMyCafe/Services/Domain/DomainDatabaseService.swift`

### PR2 Important Constraints

- No big Home/UI rework here
- No reporting work
- No Realm additions
- Keep logic deterministic and easy to test manually

### PR2 Definition Of Done

- Order and opex mutations produce correct journal changes
- Historical edits use storno flow
- Daily balances update only for affected ranges
- Business logic is not spread across ViewControllers

### PR2 Prompt For New AI Chat

You are working on `TrackMyCafe` issue `#147`, branch `feat/147-pr2-journal-engine`.

Goal:
Implement journal/storno logic, daily balance materialization, and integrate them into order/opex mutation flows.

Accepted interpretation:

- Firestore collections: `journal_entries`, `daily_balances`
- Offline: rely on Firestore local persistence
- Realm: no new models, no new sync layer

Do:

- Add finance service(s) that own journal append logic
- Implement storno-based updates
- Materialize daily balances incrementally
- Integrate order and opex create/update/delete flows with the journal

Do not:

- Rebuild Home UI yet
- Add reporting abstractions
- Add Realm support

Focus on:

- single owner for finance mutation logic
- deterministic balance updates
- minimal affected-date recomputation
- keeping UI thin

---

## 5. PR3 Context

Branch: `feat/147-pr3-home-ui-daily-balance`
Issue: `#214`

### PR3 Objective

Switch Home and related finance UI to read from `DailyBalance`, and add payment-account input to opex flow.

### PR3 What Must Be Implemented

- Update Home so:
  - current cash balance comes from `DailyBalance(today, cash)`
  - current card balance comes from `DailyBalance(today, card)`
- Update period balance analytics to use `DailyBalance.delta`
- Update opex create/edit UI to capture payment method
- Optionally add simple manual movement UI if it still fits release scope
- Keep UI consuming prepared finance data rather than recalculating balances

### PR3 Expected Files To Touch

Likely areas:

- `TrackMyCafe/View Layer/Flow/Home/ViewModel/HomeViewModel.swift`
- `TrackMyCafe/View Layer/Flow/Home/View/HomeViewController.swift`
- `TrackMyCafe/View Layer/Flow/Home/View/HomeHeaderView.swift`
- `TrackMyCafe/View Layer/Flow/Costs/CostDetails/ViewModel/CostDetailsViewModel.swift`
- `TrackMyCafe/View Layer/Flow/Costs/CostDetails/View/CostDetailsListViewController.swift`

### PR3 Important Constraints

- UI should not duplicate finance formulas
- Keep Dynamic Type / layout rules in mind
- Do not reintroduce old "sum of orders = balance" logic

### PR3 Definition Of Done

- Home no longer treats raw order sums as balances
- Opex payment method is editable in UI
- UI displays correct current balances from daily balance data
- No duplicated balance formulas in UI layer

### PR3 Prompt For New AI Chat

You are working on `TrackMyCafe` issue `#147`, branch `feat/147-pr3-home-ui-daily-balance`.

Goal:
Move Home and finance UI to `DailyBalance` and add opex payment method UI.

Accepted interpretation:

- Firestore collections: `journal_entries`, `daily_balances`
- Offline: rely on Firestore local persistence
- Realm: no new models, no new sync layer

Do:

- Update HomeViewModel/Home UI to read cash/card from `DailyBalance(today)`
- Use `DailyBalance.delta` for period balance analytics where applicable
- Add payment method input to opex create/edit flow
- Keep UI thin and business logic centralized

Do not:

- Rebuild the journal engine
- Add report features
- Add Realm code

Pay attention to:

- UIKit-only project style
- Dynamic Type and small-screen behavior
- MVVM separation

---

## 6. PR4 Context

Branch: `feat/147-pr4-backfill-hardening`
Issues: `#215`, `#216`

### PR4 Objective

Backfill historical data into journal/daily balances and finish manual validation/hardening.

### PR4 What Must Be Implemented

- Add one-time backfill flow for existing orders
- Add one-time backfill flow for existing opex
- Add one-time backfill flow for existing purchases that have `paymentAccount`
- Treat legacy opex without payment method as non-balance-affecting history
- Treat legacy purchases without payment method as non-balance-affecting history
- Add rollout-safe migration behavior
- Validate correctness for:
  - create/edit/delete orders
  - create/edit/delete opex
  - create/edit purchases
  - historical edits
  - manual movement scenarios if present
- Remove leftover old balance logic
- Do final hardening/cleanup

### PR4 Expected Files To Touch

Likely areas:

- finance migration/backfill service(s)
- app startup or controlled migration trigger point
- Home/data service cleanup
- possibly docs / QA notes if useful

### PR4 Important Constraints

- Backfill must not create a competing source of truth
- Avoid unsafe automatic behavior if migration cannot be guaranteed idempotent
- Keep release behavior understandable and debuggable

### PR4 Definition Of Done

- Existing data can populate journal and daily balance correctly
- Legacy opex does not corrupt balances
- Manual QA scenarios are covered
- Old balance logic is removed or isolated
- Release is ready to merge to main

### PR4 Prompt For New AI Chat

You are working on `TrackMyCafe` issue `#147`, branch `feat/147-pr4-backfill-hardening`.

Goal:
Implement historical backfill and finish validation/hardening for journal-based balances.

Accepted interpretation:

- Firestore collections: `journal_entries`, `daily_balances`
- Offline: rely on Firestore local persistence
- Realm: no new models, no new sync layer

Do:

- Add one-time backfill for orders and opex
- Add one-time backfill for purchases with payment method
- Treat old opex without payment method as non-balance-affecting history
- Treat old purchases without payment method as non-balance-affecting history
- Make rollout behavior safe
- Validate correctness and performance
- Remove leftover old balance logic

Do not:

- Introduce new finance sources of truth
- Add Realm migration work
- Expand scope into reports

Need:

- explicit manual QA checklist
- clear migration assumptions
- safe release-ready cleanup

---

## 7. Working Rules For Every New AI Dialogue

At the start of each new dialogue:

- mention the branch name
- mention the exact GitHub issue(s)
- restate the `Firestore-only` interpretation
- ask the AI to first inspect existing code before editing
- ask for a short implementation plan before changes
- require no invented APIs
- require UIKit-only and MVVM compliance
- require no Realm additions

### Minimal Reusable Prefix

We are working on `TrackMyCafe` iOS app.

Rules:

- UIKit only
- MVVM
- No SwiftUI
- No force unwraps
- Use async/await where practical
- Firestore is the source of truth
- Offline relies on Firestore local persistence
- Realm: no new models, no new sync layer
- No invented APIs
- Inspect existing code before editing
- Provide a short implementation plan before making changes

Issue context:

We are implementing `#147` journal-based cash/card accounting and daily balances.

---

## 8. Suggested Operational Workflow

1. Create branch from fresh `main`
2. Open a new AI chat
3. Paste:
   - reusable prefix
   - the specific PR context block
4. Implement only that PR scope
5. Build / verify manually
6. Open PR
7. Merge
8. Start next branch from updated `main`

---

## 9. Notes

This document is the working execution context for AI-assisted implementation.
GitHub issues remain the tracking layer.
This file should stay aligned with issue `#147` and its sub-issues.
