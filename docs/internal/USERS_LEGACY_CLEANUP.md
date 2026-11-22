# Legacy `Users` cleanup

## Status (2026-11-22)

Cafe root is **`users/{uid}`** (lowercase). Top-level **`Subscriptions/{uid}`** is the Pro entitlement source of truth.

App Store build with the migration shipped. Code no longer reads/writes the top-level **`Users`** collection (PascalCase). Subscription fallback to `Users/.../Subscription` has been removed.

### Prod inventory (historical)

| UID | Was under `Users` | Status |
|---|---|---|
| `0WaDDack…` | `Subscription` only (dup of `Subscriptions`) | Safe to delete shell |
| `In8OOHZk…` | `Subscription` only; **no** `users/{uid}` profile | Orphan — delete shell; keep `Subscriptions/{uid}` if still needed |
| `N91wibC9…` | `Subscription` only | Safe to delete shell |
| `xVQB28bY…` | `Technicians` (Аня, Марго) | Copied → `users/xVQB…/Technicians`; delete shell |

## Remaining PascalCase names (not `Users` root)

These stay under **`users/{uid}`** on purpose:

- `Technicians` — staff subcollection
- `Settings` — map field on the user document
- `Orders` / `Logs` — still referenced by `RequestManager` listeners / logging

Do **not** confuse them with the removed top-level `Users` collection.

## Console cleanup (manual)

1. Confirm staff + Pro work on the shipped build.
2. In Firebase Console (prod): delete the four `Users/{uid}` document trees.
3. Optionally delete empty top-level `Users` collection afterward.

## MCP note

Firestore data tools require a `firestore` block in the active `firebase.json` (see `Hosting/prod/firebase.json`). Do not deploy rules accidentally while using MCP.
