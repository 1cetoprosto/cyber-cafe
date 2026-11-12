# Agent Task: App Store marketing screenshots for TrackMyCafe

**Status:** ✅ Done — iPhone + iPad (UK+EN) uploaded to ASC **2026-11-12** (v1.2.0)  
**Live finals:** `docs/product/app-store/screenshots/current/`  
**Working raw / overlays:** `docs/product/app-store/screenshots/proposed/`  
**Manifest:** `docs/product/app-store/screenshots/proposed/MANIFEST.md`  
**Copy source of truth:** `docs/product/app-store/LISTING.md`  
**Positioning:** `docs/product/POSITIONING_AND_COPY.md`

> Нижче — оригінальний бриф (історичний). Для нової перезйомки читай MANIFEST + LISTING §4–6.

---

## 1. Goal

Produce **6 App Store screenshot frames per locale (UK + EN)** = **12 final PNGs**, ready to upload to App Store Connect for iPhone.

Each frame = branded marketing canvas + real (or faithfully staged) app UI + short overlay headline matching the approved listing.

Do **not** invent product features that are not in the app. Do **not** show splash-only / logo-only as a slot. Do **not** show developer-only UI («Ініціювати тестові дані» / Initialize test data).

---

## 2. Can an AI agent do this?

**Yes, in a two-stage pipeline:**

| Stage | What | How |
|---|---|---|
| A. UI capture | Raw phone screens of real app | Xcode Simulator / `xcode-tools` DeviceInteraction / manual export from TestFlight build. Prefer **light theme** “Latte” / CoffeeWithMilk look that matches current marketing. |
| B. Marketing frame | Device mockup + dark green branded background + overlay type | Image generation / composition tool, or Figma. Match style of `screenshots/current/` (forest green organic shapes, mint accent, beige app chrome). |

If Stage A cannot be automated, agent must:

1. List exact screens + demo data to seed.
2. Ask human for 6 raw simulator PNGs per locale **or** seed demo data and capture via MCP.
3. Only then run Stage B.

**Do not** fake the app UI as a vague illustration — App Store users bounce when mock UI ≠ install UI. Overlay marketing chrome around **real screenshots**.

---

## 3. Deliverables (filenames)

```text
docs/product/app-store/screenshots/proposed/uk/
  01-home.png
  02-pl.png
  03-pos.png
  04-costs.png
  05-abc.png
  06-team.png

docs/product/app-store/screenshots/proposed/en/
  01-home.png
  02-pl.png
  03-pos.png
  04-costs.png
  05-abc.png
  06-team.png
```

Optional raw captures (before framing):

```text
docs/product/app-store/screenshots/proposed/_raw/uk/...
docs/product/app-store/screenshots/proposed/_raw/en/...
```

Also write a short `docs/product/app-store/screenshots/proposed/MANIFEST.md`:

- which build/scheme/locale
- overlay text used
- ASC size target used
- any deviations from this brief

---

## 4. Technical specs (App Store Connect)

Produce for **iPhone 6.7" display** (primary set). If only one size is feasible first, do 6.7".

| Requirement | Value |
|---|---|
| Target | iPhone 6.7" (e.g. 1290 × 2796 or current ASC-accepted 6.7" size) |
| Format | PNG (RGB, no alpha required for final ASC upload; keep transparent only in working files) |
| Orientation | Portrait |
| Count | Exactly 6 per locale for first upload (max ASC allows more; we use 6) |
| Text on image | Overlay headlines below — keep ≤ ~6 words; large, high contrast |

**Safe layout:**

- Top ~18–22% of canvas: headline overlay (mint / off-white on dark green).
- Center/lower: one primary iPhone mockup (or collage only on #1 if needed — prefer single device for #2–#6).
- Do not cover critical KPI numbers with captions.
- Margins ≥ 3% from edges.

---

## 5. Brand / visual system

Match existing ASC art direction in `screenshots/current/`:

- **Background:** deep forest green `#1B3A2F`–`#243D32` range with soft organic lighter-green shapes (not purple gradients, not generic AI purple).
- **Accent / pills:** mint `#7CFFB2`–`#B6F5C6` for ovals / CTA bars.
- **App UI chrome:** light “Latte” beige (`#F9F2ED` family), dark green primary buttons — see `docs/engineering/ThemeColors.md` → CoffeeWithMilk.
- **Typography overlays:** bold sans, mixed case OK; UK uses Ukrainian; EN uses American English (native, not translated word-for-word).
- **Props:** subtle coffee beans OK (as in current #2); don’t clutter.

Avoid: splash ribbon-only frame like current #7 as a slot; settings with test-data row like current #6.

---

## 6. Shot list (content + overlay)

Approved listing hooks live in `LISTING.md`. Overlay text is **fixed** unless unreadable on the composition — then shorten, don’t change meaning.

### 01 — Home / profit answer

| | |
|---|---|
| **UI** | Home (Dashboard) for a period with visible **Net Profit** (and ideally Sales / costs summary). 5-tab bar visible. |
| **UK overlay** | Багато продажів. А що залишилось? |
| **EN overlay** | Lots of sales. What’s left? |
| **Demo data notes** | Net profit clearly positive or realistically mixed; currency ₴ (UK) / $ (EN). Period label readable (Тиждень / Week). |

### 02 — P&L / What’s left

| | |
|---|---|
| **UI** | Reports → P&L («Скільки залишилось» / «What's left») with Sales, COGS, Opex, Net. |
| **UK overlay** | Виручка − витрати = ваш прибуток |
| **EN overlay** | Sales − costs = your profit |
| **Demo data notes** | Show the subtraction story in the UI itself; overlay only reinforces. |

### 03 — POS / receipt

| | |
|---|---|
| **UI** | New sale / order details: 2–4 menu items with steppers, total, cash/card split, Save. |
| **UK overlay** | Чек за кілька натискань |
| **EN overlay** | A receipt in a few taps |
| **Demo data notes** | UK menu: Американо, Капучино, Круасан… EN menu: Americano, Latte, Bagel… Mix food+drink so not coffee-only. |

### 04 — Costs / expenses

| | |
|---|---|
| **UI** | Costs list with **diverse** rows: ingredients purchase, rent/booth, payroll (or salary), packaging — not only “coffee beans”. |
| **UK overlay** | Закупки, оренда, зарплати — під контролем |
| **EN overlay** | Supplies, rent, payroll — under control |
| **Demo data notes** | Group by date; amounts realistic for small venue. |

### 05 — ABC / what makes money

| | |
|---|---|
| **UI** | Reports → ABC («Що робить гроші» / «What makes money»). |
| **UK overlay** | Що з меню реально заробляє |
| **EN overlay** | What on the menu actually earns |
| **Demo data notes** | Top items mix drinks + food. |

### 06 — Team (preferred) or clean Settings

| | |
|---|---|
| **UI** | **Preferred:** Staff list with roles (Власник / Менеджер / Офіціант · Owner / Manager / Waiter). **Fallback:** Settings **without** any developer/test-data rows. |
| **UK overlay** | Для власника і команди |
| **EN overlay** | For the owner and the team |
| **Demo data notes** | No “Initialize test data”. No empty state if avoidable. |

---

## 7. Demo data seeding (before capture) — MUST DO FIRST

**Do not** change the simulator system clock to match old Firebase data.  
**Do** generate fresh demo activity for the **current period** so Home / P&L / ABC show non-zero numbers.

### Built-in seed (preferred)

On **TrackMyCafe Beta/Dev** (`#if DEBUG`):

1. Open **Налаштування / Settings**.
2. Developer section → **Ініціювати тестові дані / Seed test data**.
3. Enter **`60`** days (default) → confirm — covers current + previous month for Home delta %.
4. Wait until HUD finishes. This calls `DomainDatabaseService.seedTestData(forDays:)` which **clears DB** and generates sales/costs/recipes **relative to `Date()`** (today backward). Seed uses UA-realistic prices and **calendar opex** (rent/payroll once per month) so Net Profit is positive.

Alternative: empty-account floating **Demo data** button → `seedUserDemoData()` (`defaultDemoSeedDays` = 60).

### Why previous raw UK shots failed

Account had Feb 2026 activity while “today” was Nov 2026 → week/month KPIs = `0,00 ₴`. Useless for ASC.

### After seed, verify before capture

- Home → **Тиждень** or **Місяць**: income, expenses, profit **≠ 0**
- Reports → P&L: sales / COGS / opex / net **≠ 0**
- Reports → ABC: at least a few products listed
- Costs: mixed rows (rent, payroll, supplies)
- Prefer light theme; dismiss coach marks

**UK persona label in UI data:** Ukrainian product names from seed.  
**EN:** switch app language to English and re-seed (or second account) so menu strings are English.

Use **Prod or Beta scheme** UI that matches App Store binary. Prefer light theme.

---

## 8. Locale rules

| | UK | EN |
|---|---|---|
| App language | Ukrainian | English (US) |
| Currency in UI | ₴ | $ |
| Overlay language | Ukrainian | American English |
| Menu names | Local UA names | Local US names |
| Do not | Machine-translate overlays from UK | Mirror UA wording awkwardly |

UA/EN frames may share layout templates; **UI content and overlays must be native per locale**.

---

## 9. Quality checklist (DoD)

Agent is done only when **all** are true:

- [ ] 12 finals exist at paths in §3  
- [ ] Each shows **current 5-tab IA** (not old 3-tab from `current/`)  
- [ ] Shot 01 shows Net Profit / home summary  
- [ ] Shot 02 shows P&L  
- [ ] Shot 05 shows ABC (or documented fallback if ABC empty — then use Trends and note in MANIFEST)  
- [ ] No splash-only, no test-data settings  
- [ ] Overlays match §6 (or shortened equivalents noted in MANIFEST)  
- [ ] Readable at phone-thumbnail size (zoom out test)  
- [ ] Visual style consistent across 6 frames  
- [ ] `MANIFEST.md` written  
- [ ] Human spot-check: install UI ≈ screenshot UI  

---

## 10. Suggested execution order

1. Read `LISTING.md` §2 + §4 and this file end-to-end.  
2. Open Xcode → scheme **TrackMyCafe Beta** or **Prod** → iPhone 15/16 Pro Max (6.7").  
3. Seed demo data (UK first).  
4. Capture `_raw/uk` screens for shots 01–06.  
5. Compose marketing frames → `proposed/uk/*.png`.  
6. Switch app language + currency/demo to EN; repeat captures → `proposed/en/`.  
7. Write `MANIFEST.md`.  
8. Paste 01 thumbnails into chat / open files for human approval before ASC upload.

---

## 11. Out of scope

- Uploading to App Store Connect (human or separate release task)  
- Changing in-app `Global.strings` / paywall copy  
- Android  
- App Preview video (optional follow-up after stills approved)  
- Rewriting approved Description / Subtitle  

---

## 12. Prompt stub (paste to agent)

```text
Execute docs/product/app-store/SCREENSHOTS_AGENT_TASK.md end-to-end.

Repo: TrackMyCafe / cyber-coffe.
Approved ASC copy: docs/product/app-store/LISTING.md (Description + Subtitle already approved).
Produce 6 UK + 6 EN marketing screenshots into docs/product/app-store/screenshots/proposed/{uk,en}/ per the shot list and DoD.
Prefer real Simulator UI captures composed onto branded frames matching screenshots/current/ art direction.
Do not show developer test-data UI. Do not ship splash-only frames.
When finished, write proposed/MANIFEST.md and stop for human review.
```
