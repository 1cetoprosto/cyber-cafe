# Submit checklist — TrackMyCafe **1.2.0**

Дата чеклиста: 2026-11-14.  
**Статус: ✅ RELEASED — 2026-11-21** (перевірено live US/UA 2026-11-22).

Мета була: вивести на live нові скріни + metadata (щоб UA/US перестали бачити стару вітрину).

Далі: [`NEXT_ACTIONS.md`](NEXT_ACTIONS.md).

---

## Live після релізу (2026-11-22)

| Елемент | Live |
|---|---|
| Version | **1.2.0** (App Store, ~2026-11-21 20:58 UTC) |
| UA Name / Subtitle | `TrackMyCafe: Легкий Облік` / `Прибуток після всіх витрат` |
| US Name / Subtitle | `TrackMyCafe: Easy Cafe Book` / `Profit after all expenses` |
| Description | Канон LISTING (без offline / export) |
| What’s New | Про прибуток / дашборд |

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

## Кроки в ASC (архів — уже зроблено)

### 1. Прив’язати binary

1. App Store Connect → TrackMyCafe → Distribution
2. Версія iOS 1.2.0
3. Build → Add Build → **1.2.0 (71)** (або новіший)
4. Save

### 2. Product Page (EN + UK)

| Поле | Очікували |
|---|---|
| Name | EN: `TrackMyCafe: Easy Cafe Book` · UK: `TrackMyCafe: Легкий Облік` |
| Subtitle | EN: `Profit after all expenses` · UK: `Прибуток після всіх витрат` |
| Description | Без offline / export / «No credit card» |
| Screenshots | iPhone 6 + iPad 6, UK і EN — нові overlays |

### 3–5. Review info → Manual release → Submit

(виконано при релізі)

### 6. Після Release — ще зробити

1. [x] Live UA/US показують 1.2.0
2. [ ] Візуально підтвердити **нові скріни** (не splash 2023)
3. [ ] Записати дату релізу в baseline / Metrics Tracker → **2026-11-21**
4. [ ] Через **14 днів** зняти US + UA: Impr / Views / DL / CVR

---

## DoD

- [x] Build на 1.2.0
- [x] EN + UK metadata без overclaim
- [x] Нові скріни на версії (iPhone+iPad) — були в ASC
- [x] Submitted + Released
- [ ] Візуальний confirmation скрінів на store URL
- [ ] Дата релізу записана для ASO baseline
- [ ] +14 днів метрики

---

## Не блокувало / не блокує зараз

- Keywords A/B → після +14 днів (`NEXT_ACTIONS` Фаза 4)
- App Preview video
- pl-PL / en-GB
- In-app onboarding polish → окремий 1.2.1 лише якщо на live немає канону
