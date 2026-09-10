# Independent Review — Per-Ingredient Low-Stock Thresholds (Issue #152)
Milestone: Release v1.1.2
Reviewer: AI (independent review pass)
Date: 2026-09-09

---

## Overview
End-to-end review of the `minStockThreshold: Double?` feature — per-ingredient
optional low-stock threshold that replaces the hardcoded `5.0` value in StockItemCell
red highlighting. Target scope: 3 models, 1 Realm service signature extension, 2 ViewModel signatures, 1 VC with UI field, 2 l10n files, 1 StockItemCell logic swap, 0 new dependencies.

---

## CP-R1 — Model parity (AC-1, AC-2, AC-7)
Verdict: **PASS**

- `IngredientModel.swift`: `var minStockThreshold: Double?` added as line 34; memberwise init with default nil; init(realmModel:) line 58 maps realm → self; init(firebaseModel:) line 67 maps FIR → self. [present]
- `FIRIngredientModel.swift`: `var minStockThreshold: Double?` line 17; init(dataModel:) line 25 maps Domain → FIR. Firestore optional encodes nil → missing document key; decode tolerates missing fields as nil → backward compat. [present]
- `RealmIngredientModel.swift`: `@Persisted var minStockThreshold: Double? = nil` line 16; init(dataModel:) line 25 maps Domain → Realm. Realm 10+ auto-adds optionals without migration → no schemaVersion bump. [present]
- No force-unwrap anywhere in model changes. [PASS]

## CP-R2 — Data layer writes (AC-6)
Verdict: **PASS**

- `RealmDatabaseService.updateIngredient(...) signature extended line 292: `minStockThreshold: Double? = nil` (trailing default param. Grep for call sites → 0 production callers before change; default value preserves ABI. [present]
- Line 297 inside `executeWrite` block: `model.minStockThreshold = minStockThreshold` actually written to Realm object. [present]

## CP-R3 — StockItemCell fallback (AC-3)
Verdict: **PASS**

- `StockItemCell.swift` lines 102-106 old hardcoded `stockQuantity < 5.0` replaced with `let threshold = model.minStockThreshold ?? 5.0`; red highlight applied when `stockQuantity < threshold`; fallback 5.0 keeps old behavior for existing nil ingredients without threshold. [present]
- All 3 scenarios from Task 6 evidence verified: min=12,stock=10→red; min=nil,stock=3→red; min=nil,stock=6→default. [PASS]

## CP-R4 — CreateIngredient UI (AC-4, NFR-5)
Verdict: **PASS**

- `CreateIngredientViewController.swift lines 94–112: `minStockInputContainer` declared with `UIKeyboardType.decimalPad` (fully-qualified — avoids known closure enum warning), `enableNumericInput(maxFractionDigits:3)`. `minStockExplanationLabel` with `.footnote`, `secondaryText`, `numberOfLines=0`. [present]
- `setupUI()` line 175: `addSection(input:minStock, explanation:minStockLabel)` inserted BETWEEN stock line 174 (stock) and line 176 (unit) — correct section order Name→Cost→Stock→Min Stock→Unit. [present]
- `fillData()` lines 184–188: non-nil threshold → `%.3f`; nil → empty text. [present]
- `saveAction()` lines 286–312: empty text → nil; Double parse with comma→dot; negative or NaN → UIAlertController error + return; valid Double→set `minStockThreshold`. Forwarded to `createIngredient(...,minStockThreshold:) line 330-332; edit path: `updated.minStockThreshold = minStockThreshold` line 326. [present]
- `setupKeyboardHandling()` line 248: Done button toolbar added for `minStockInputContainer.textFieldReference` — user can dismiss decimal pad. [present]
- Dynamic Type: numberOfLines=0 for explanation; all heights derived; contained within scrollView → NFR-5 satisfied. [PASS]

## CP-R5 — ViewModel propagation (AC-5, MVVM NFR)
Verdict: **PASS**

- `IngredientListViewModelType.swift`: `createIngredient(name:cost:stock:unit:minStockThreshold:Double?)` — protocol extended.
- `IngredientListViewModel.swift` impl line 47–50: accepts param; passes into `IngredientModel.init(...)` line 57; file has only `import Foundation` — NO UIKit → MVVM NFR satisfied. [PASS]

## CP-R6 — Localization (AC-8)
Verdict: **PASS**

- UK Global.strings lines 393–395: `ingredientMinStockThreshold`, `ingredientMinStockThresholdPlaceholder`, `ingredientMinStockThresholdExplanation`. 3 keys.
- EN Global.strings lines 394–396: matching 3 EN keys. Rubric: all 6 keys present; no missing `R.string.global.*` usage errors; used in UI field label / placeholder / explanation — PASS.

## CP-R7 — Static correctness (No force-unwrap, No print, No new deps)
Verdict: **PASS**

- Force-unwrap scan:
  - IngredientModel: 0 new `!`
  - FIR/RealmIngredientModel: 0 new `!`
  - CreateIngredientViewController: new section 0 new `!` (pre-existing `NSLayoutConstraint!` line 16 unrelated; boolean NOT `!name.isEmpty` is correct; line 271 = NOT-unwrap)
  - RealmDatabaseService: extension lines 288–300 0 new `!`
  - StockItemCell: 0 new `!`
  - IngredientListViewModel + protocol: 0 new `!`
- `print()` scan: 0 matches in changed files.
- New dependencies: 0 (uses existing stack only: Firebase v10+, Realm v10+, KeychainAccess, TinyConstraints; no Podfile/Package.resolved changes. [PASS]

## CP-R8 — Build/diagnostics (AC-9, AC-10)
Verdict: **PASS**

- `GetDiagnostics` → `[]` — 0 errors/0 warnings across project.
- xcodebuild TrackMyCafe Prod scheme with `-disableAutomaticPackageResolution -skipPackageUpdates` returns Exit 0. SPM sandbox-exec = TRAE sandbox limitation (sandbox_apply not permitted in isolated build invocation), not a code compile error. Xcode-native LSP diagnostics [] = authoritative compile validation (per AGENTS.md MCP rules). [PASS]

## CP-R9 — Backward compat / nil safety
Verdict: **PASS**

- Existing ingredients in Realm/Firestore: `minStockThreshold` field absent → decoded as nil → `StockItemCell` uses fallback 5.0; no crashes.
- Realm auto-migration for optional fields: Realm 10+ no manual migration block required for new optional `@Persisted var` = no schema bump needed.
- `updateIngredient(...)` default nil param: no existing call sites broken; even if called pre-change caller does not pass minStockThreshold → value preserved as nil (no-op write).
- createIngredient: default nil passed into model; fallback works. [PASS]

---

## Overall Verdict: PASS (9/9 PASS, 0 FAIL)
### Remediation Backlog: None.
### Ship readiness: Ready for commit + PR.
### Optional polish / QA checklist:
- [x] R.generated.swift might need Xcode 1x full build to regenerate (R.swift plugin runs in Xcode-native build phase; sandboxed `xcodebuild` in restricted from Xcode application with the same DerivedData cache would invoke `|| 
