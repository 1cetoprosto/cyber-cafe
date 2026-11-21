# TrackMyCafe — конкуренти (ASO)

Оновлено: 2026-11-21.  
Метод: iTunes Search/Lookup + сторінки App Store (US/UA). Subtitle — з публічної сторінки.  
Мета: правильна ніша → ключі → тон скрінів (див. вебінар Radaso).

Ширший корпус (50 апків, кластери ключів):  
`research/01_Конкуренти_і_аналіз/` — цей файл = **вузький Tier A/B** під job «продажі + витрати → прибуток», не дубль Excel.

**Наш live ASC (перевірка 2026-11-21):**

| Поле | Live US | Канон `LISTING.md` |
|---|---|---|
| Name | `TrackMyCafe: Easy Cafe Book` | `TrackMyCafe` |
| Subtitle | `Track Expenses & Profit Simple` | EN: `Profit after all expenses` |
| Category | Business | Business |

→ Перед наступним submit: **звірити ASC з LISTING** (name/subtitle/description).

---

## Tier A — прямі (той самий job: продажі + витрати → прибуток)

| # | App | ID | Subtitle (live) | Ринки | Чому прямий | Інсайт для нас |
|---|---|---|---|---|---|---|
| 1 | **Yield: Profit Tracker** | 6777277585 | Know what you really take home | US (немає UA) | Cafe / small food P&L, COGS, wages, overhead, net profit | Найближчий меседж до нашого хука. Скрін 1 = «справжній take-home». Категорія **Finance**. |
| 2 | **Fobesoft** | 6464009570 | Daily Restaurant P&L | US | Daily restaurant P&L, COGS, labor, expenses | Прямий P&L-позишн. Invoice scan. Мало відгуків (8×5.0). |
| 3 | **RestoProfit** | 6760305446 | Restaurant Cost & Profit | US+UA | Income/expenses, rent/wages spread, margins | Хуки як у нас («where the money went»). Paid upfront $0.99, без IAP. Offline-first. |
| 4 | **Deliyum: Food Recipe & Cost** | 6790344572 | Margin calculator & P&L report | US+UA | Cafe/bakery costing + monthly P&L | Сильніший на recipe/stock; P&L вторинний. One-time Pro. |
| 5 | **clickBACON** | 1512752409 | Cost Control Dashboard | US+UA | Budgets, COGS, labor, prime cost | Важчий «operator dashboard» + QBO. Не наш сегмент solo-cafe, але keywords: COGS/labor/prime cost. |

---

## Tier B — UA / локальний контекст

| # | App | ID | Subtitle (live) | Ринки | Тип | Інсайт |
|---|---|---|---|---|---|---|
| 6 | **Poster Boss** | 1088181327 | Poster POS sales statistics | UA сильний (159★ ~4.6) | Companion до POS | У пошуку «кав'ярня облік» — топ. Продажі/склад/фінанси Poster, не standalone P&L. **Не копіювати POS**, відрізнятись: «прибуток без касового комплексу». |
| 7 | **Poster — tablet POS** | 691098784 | (POS) | UA | Full POS | Екосистема Poster. Конкурент за увагу, не за job-to-be-done. |
| 8 | **Smallbee** | 6822282605 | _(без чіткого subtitle на сторінці)_ | UA-only, UK | Зміна / зарплати / постачальники | Локальний UA суперник для малих закладів. Менше «P&L story», більше операційки зміни. iOS 26+. Слідкувати. |

---

## Tier C — суміжні (food cost / recipes — ключі, не той самий продукт)

| # | App | ID | Subtitle / позишн | Нотатка |
|---|---|---|---|---|
| 9 | **Plate Pro: Food Cost & Recipes** | 6753737815 | Food costing native Apple | Recipe → plate cost; слабший daily P&L |
| 10 | **Fillet for Chefs** | 696313628 | Recipe costing (сильні відгуки US) | Кухня/інвентар; не cafe owner P&L |
| 11 | **Recipe Cost Calc - KitchenCost** | 6756592070 | Margins без spreadsheets | Той самий біль «gut feeling pricing» |
| 12 | **Food Cost Calc & Pricing (Genka)** | 6743666327 | Recipe cost & pricing | Калькулятор собівартості |

*Narvata* (sales tracker) — **не** брати в ядро: загальний SMB sales, не HoReCa P&L.

---

## Патерни (що повторюється)

1. **Хук = виручка ≠ прибуток** — Yield, RestoProfit, наш канон. Це правильна ніша.
2. Subtitle часто **обіцянка результату**, не категорія: *take home / Daily P&L / Cost & Profit*.
3. US-direct P&L апки часто в **Finance**; ми в **Business** (як Fobesoft / Poster) — ок для cafe tooling.
4. UA-пошук забитий **Poster**; standalone «простий облік без POS» — вільна щілина для TrackMyCafe.
5. Багато конкурентів **майже без рейтингів** — вікно для перших якісних відгуків.

---

## Скріни конкурентів — що знімати в аудит (ручний прохід 15 хв)

Для Tier A (Yield, Fobesoft, RestoProfit) + Poster Boss UA:

- [ ] Скрін 1: біль чи дашборд прибутку?
- [ ] Чи є велика цифра «net / left / profit»?
- [ ] Мокап телефону + текстовий акцент?
- [ ] Сезонність / A/B відчуття?

Порівняти з нашим `screenshots/current/` + `LISTING.md` §3–4.

---

## Наступні кроки з цього документа

1. Keywords audit → `LISTING.md` §2.6 (+ пропозиції нижче в ASO_NEXT).
2. Вирівняти live Name/Subtitle з каноном при submit 1.2.0+.
3. Не змагатися з Poster за «каса»; змагатися за **«що залишилось»**.
