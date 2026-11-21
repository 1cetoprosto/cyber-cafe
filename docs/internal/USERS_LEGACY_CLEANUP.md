# Legacy `Users` cleanup

## Status (2026-11-21)

Cafe root is **`users/{uid}`** (lowercase). Top-level **`Subscriptions/{uid}`** is the Pro entitlement source of truth.

Prod inventory showed only 4 phantom `Users/{uid}` shells:

| UID | Was under `Users` | Action taken |
|---|---|---|
| `0WaDDack…` | `Subscription` only (dup of `Subscriptions`) | Keep until post-release delete |
| `In8OOHZk…` | `Subscription` only; **no** `users/{uid}` profile | Keep; orphan — do not invent a profile |
| `N91wibC9…` | `Subscription` only | Keep until post-release delete |
| `xVQB28bY…` | `Technicians` (Аня, Марго) | **Copied** → `users/xVQB…/Technicians` (same IDs) |

## Code (this PR / branch)

- `RequestManager.mainRef` → `users/{masterUserRef}`
- Admin + Settings map: listen/update on the `users/{uid}` document
- Subscription: read/write `Subscriptions/{uid}` only; one-release fallback from `Users/.../Subscription`
- Staff: create/update/delete under `users/{uid}/Technicians`

## Do NOT delete `Users` yet

1. Ship the app build that contains the code above (Beta → Prod).
2. Smoke-test: staff list, Pro entitlement, admin profile, currency symbol.
3. Then delete the four `Users/{uid}` trees in Console (or script).
4. After one stable release: remove `legacyUsers` / fallback reads from code.

## MCP note

Firestore data tools require a `firestore` block in the active `firebase.json` (see `Hosting/prod/firebase.json`). Do not deploy rules accidentally while using MCP.
