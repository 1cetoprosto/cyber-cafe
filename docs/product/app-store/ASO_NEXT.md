# ASO next — чеклист після вебінару

Оновлено: 2026-11-21.  
Пов’язано: [`COMPETITORS.md`](COMPETITORS.md) · [`LISTING.md`](LISTING.md) · [`POSITIONING_AND_COPY.md`](../POSITIONING_AND_COPY.md).

---

## 1. Онбординг → trial

| Статус | Що |
|---|---|
| ✅ | 3 слайди (чек → витрати → залишок) + paywall |
| ✅ | Демо-суми UA/US + formatter |
| ✅ | First-run subtitle: `subscriptionPaywallTrialSubtitle` |
| ✅ | Slide 3 copy вирівняно з каноном |
| ⏳ | Ручний прогін UK/EN + Dynamic Type на симі |
| ⏳ | 5–10 власників: «Це про тебе?» |

---

## 2. Конкуренти

Див. [`COMPETITORS.md`](COMPETITORS.md) — 12 апків, Tier A/B/C.  
Пріоритет ручного скрін-аудиту: **Yield, Fobesoft, RestoProfit, Poster Boss**.

---

## 3. Keywords — аудит (≤100 символів)

### Live / канон зараз (`LISTING` §2.6)

**UK:** `кав'ярня,кафе,пекарня,фудтрак,прибуток,облік,витрати,собівартість,оренда,каса,склад,меню`  
**EN:** `coffee shop,cafe,bakery,food truck,profit,bookkeeping,expenses,cogs,inventory,kiosk,pos,payroll`

### Що добре
- Загальні запити (не бренд) — як радили на вебінарі.
- Типи закладів у UK/EN.
- `прибуток` / `profit`, `витрати` / `expenses`, `cogs` / `собівартість`.

### Ризики
| Проблема | Дія |
|---|---|
| Live US **Name** = `TrackMyCafe: Easy Cafe Book` | Слова з name індексуються окремо; keywords не повинні їх дублювати. Якщо лишаєте довгий name — ок; якщо вертаєтесь до `TrackMyCafe` — keywords можна розширити. |
| Live US **Subtitle** ≠ LISTING | Вирівняти ASC → `Profit after all expenses` (канон). |
| `каса` / `pos` | Тягнуть очікування POS. Для диференціації від Poster можна **прибрати** і поставити сильніші P&L-слова. |
| EN `bookkeeping` | Широко; ок, але слабше за `food cost` / `pnl` у нашій ніші. |

### Пропозиція v2 (після вирівнювання Name → `TrackMyCafe`)

**UK (99):**  
`кав'ярня,кафе,пекарня,фудтрак,прибуток,витрати,облік,собівартість,фудкост,виторг,оренда,склад`

**EN (98):**  
`coffee shop,cafe,bakery,food truck,profit,expenses,food cost,cogs,pnl,payroll,kiosk,inventory`

Зміни: −`каса`/`меню`/`pos`/`bookkeeping`; +`фудкост`/`виторг`/`food cost`/`pnl`.  
**Не заливати в ASC**, доки не вирішите Name/Subtitle sync + один A/B цикл після релізу.

---

## 4. Скріни як креатив

Канон overlays: `screenshots/proposed/OVERLAY_COPY_*.md`.  
Live set: `screenshots/current/` (залито 2026-11-12).

### Аудит live UK (2026-11-21)

| Критерій вебінару | Статус | Коментар |
|---|---|---|
| Скрін 1 = креатив болю | ✅ | «Продажі є — а грошей немає?» + мокап Home з прибутком |
| Мокап + текстовий акцент | ✅ | Темний фон, великий headline |
| Велика цифра «що лишилось» | ✅ | Home green profit + P&L «ЗАЛИШИЛОСЬ» |
| Відповідність канону overlays | ✅ | Збігається з `OVERLAY_COPY_UK.md` |
| vs Yield («take home») | ✅ напрям той самий | Не треба перезнімати зараз заради ASO |
| Сезонне оновлення | ⏳ | Після свят / наступний major |

**Висновок:** скріни вже відповідають порадам вебінару. Пріоритетніше вирівняти **live Name/Subtitle/description** з LISTING, ніж нові скріни.

Чеклист:
- [x] Скрін 1 = рекламний креатив болю
- [x] Мокап + короткий акцент
- [x] Велика цифра прибутку
- [ ] (Опційно) side-by-side з Yield у `research/`
- [ ] Сезонне оновлення — пізніше

---

## 5. Метрики (готовність до UA)

### Уже є (без in-app SDK)

Baseline ASC: `research/05_Відстеження_метрик/baseline_ASC_2026-11-14.md`

| ASC (World ~90д) | Значення |
|---|---:|
| Impressions | ~5.2K |
| Product Page Views | ~244 |
| First-Time Downloads | ~77 |
| Conversion (view→DL) | **~1.8%** |
| Search → DL | ~39% |
| App Referrer → DL | ~53% |

→ Головний важіль зараз: **підняти CVR сторінки** (subtitle/name sync + скріни вже ок) і **trial→pay** після інсталу.

### In-app (зараз немає Firebase Analytics)

Мінімум до платного трафіку:

| Подія | Навіщо |
|---|---|
| `onboarding_completed` | Воронка first-run |
| `paywall_view` / `trial_start` / `subscribe` | CAC / trial→pay |
| `first_sale_saved` / `first_expense_saved` | Activation |
| D1 / D7 open | Retention |

**Варіанти (потрібне рішення Leo):**

| Варіант | Плюс | Мінус |
|---|---|---|
| A. Увімкнути **Firebase Analytics** (згода) | Повна воронка | Відхилення від поточного Firebase-scope |
| B. Лише **ASC + App Store Connect Subscriptions** + ручні нотатки | Без нового SDK | Немає D1/activation |
| C. Легкий **власний лог у Firestore** (згоди / opt-in) | Контроль | Треба писати код і privacy |

Рекомендація до Paid: **B зараз** + фіксувати trial/subscribe з ASC; **A** — якщо підете в Ads.

---

## 6. Paid UA — план «пізніше» (чернетка)

### Умови старту (Go / No-Go)

1. [ ] ASC Name/Subtitle/Description = LISTING канон  
2. [ ] CVR сторінки стабільніший за ~1.8% (ціль після sync: **≥3–4%** як орієнтир, не гарантія)  
3. [ ] Є дані trial→pay з ASC Subscriptions (хоча б кілька тижнів)  
4. [ ] Бюджет на **≥4 тижні** одного каналу (не «день тест»)

### Перший тест (коли Go)

| Параметр | Значення |
|---|---|
| Канал | **Apple Search Ads** only |
| Geo | Спочатку **UA** (де Poster + наш UK listing) *або* US — обрати один |
| Match | Exact: 2–3 фрази з keywords v2 (`кав'ярня облік` / `cafe profit` тощо — уточнити Search Match звітом) |
| Creative | Default product page (скріни вже ок); CPP — пізніше |
| Бюджет | Не $5k/міс агенції: старт типу **$10–20/день** на 4 тижні, якщо LTV підписки покриває CPT×воронку |
| Kill criteria | Після learning: CPT або CPA >> LTV × допустимий payback |

Бенчмарк вебінару ($5k/міс/канал/geo) — для агенційного масштабу, **не** наш день 1.

---

## Порядок виконання (статус)

| # | Крок | Статус |
|---|---|---|
| 1 | Онбординг → trial gaps | ✅ код; ⏳ QA на симі |
| 2 | Конкуренти | ✅ `COMPETITORS.md` |
| 3 | Keywords audit | ✅ пропозиція v2; ⏳ рішення Leo + ASC |
| 4 | Скріни креатив | ✅ live OK; сезон / Yield side-by-side опційно |
| 5 | Метрики | ⏳ рішення Leo: Analytics чи без |
| 6 | Paid UA план | ⏳ після ASC sync + метрик |
