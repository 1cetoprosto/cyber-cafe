# Submit checklist — TrackMyCafe **1.2.0**

Дата чеклиста: 2026-11-14.  
**Статус: ✅ RELEASED — 2026-11-21** (перевірено live US/UA 2026-11-22).

Мета була: вивести на live нові скріни + metadata (щоб UA/US перестали бачити стару вітрину).

Далі: [`NEXT_ACTIONS.md`](NEXT_ACTIONS.md).

---

## Live після релізу (підтверджено 2026-11-22)

| Елемент | Live |
|---|---|
| Version | **1.2.0** (App Store, ~2026-11-21 20:58 UTC) |
| UA Name / Subtitle | `TrackMyCafe: Легкий Облік` / `Прибуток після всіх витрат` |
| US Name / Subtitle | `TrackMyCafe: Easy Cafe Book` / `Profit after all expenses` |
| Description | Канон LISTING (без offline / export) |
| What’s New | Про прибуток / дашборд |
| Screenshots | ✅ нові (підтверджено Leo 2026-11-22, не splash 2023) |
| Onboarding у binary | ✅ канон з trial (Leo, fresh install) |

---

## Стан ASC на момент чеклиста (2026-11-14) — архів

| Елемент | Стан тоді |
|---|---|
| Version **1.2.0** | Prepare for Submission |
| **Build на версії** | ❌ порожньо — треба було **Add Build** |
| TestFlight builds **1.2.0** | ✅ **71** Ready to Submit (також 69) |
| Screenshots | ✅ залиті в ASC 2026-11-12 — на live ще старі, бо версія не released |
| Retention Messaging `#291` | окремо WAITING_FOR_REVIEW (не блокувало) |

Головний блокер тоді: **не вибраний build**.

---

## Кроки в ASC (архів — виконано)

### 1. Прив’язати binary — [x]

1. App Store Connect → TrackMyCafe → Distribution
2. Версія iOS 1.2.0
3. Build → Add Build → **1.2.0 (71)** (або новіший)
4. Save

### 2. Product Page (EN + UK) — [x]

| Поле | Очікували / live |
|---|---|
| Name | EN: `TrackMyCafe: Easy Cafe Book` · UK: `TrackMyCafe: Легкий Облік` |
| Subtitle | EN: `Profit after all expenses` · UK: `Прибуток після всіх витрат` |
| Description | Без offline / export / «No credit card» |
| Screenshots | iPhone 6 + iPad 6, UK і EN — нові overlays |

### 3–5. Review info → Manual release → Submit — [x]

Виконано при релізі 2026-11-21.

### 6. Після Release

1. [x] Live UA/US показують 1.2.0
2. [x] Візуально підтвердити **нові скріни** (Leo 2026-11-22)
3. [x] Дата релізу для ASO baseline → **2026-11-21** (зафіксовано тут і в `NEXT_ACTIONS.md`)
4. [ ] Через **14 днів** (~**2026-12-05**) зняти US + UA: Impr / Views / DL / CVR → див. Фазу 2 у [`NEXT_ACTIONS.md`](NEXT_ACTIONS.md)

---

## DoD

- [x] Build на 1.2.0
- [x] EN + UK metadata без overclaim
- [x] Нові скріни на версії (iPhone+iPad) — були в ASC і live
- [x] Submitted + Released (2026-11-21)
- [x] Візуальний confirmation скрінів на store URL (Leo 2026-11-22)
- [x] Дата релізу записана для ASO baseline (**2026-11-21**)
- [ ] +14 днів метрики (~2026-12-05) — єдиний відкритий follow-up

---

## Не блокувало / не в цьому чеклисті

- Keywords A/B → після +14 днів (`NEXT_ACTIONS` Фаза 4)
- App Preview video
- pl-PL / en-GB
- In-app onboarding polish → **не потрібен 1.2.1** заради онбордингу (уже на live)
