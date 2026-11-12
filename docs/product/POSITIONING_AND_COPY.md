# TrackMyCafe — Positioning & Copy Pack

## Роль документа

Канон **зовнішнього позиціонування** + in-app copy (онбординг / paywall).

Повний App Store Connect пакет (description, keywords, audit скрінів, proposed set):  
**[`app-store/LISTING.md`](app-store/LISTING.md)**.

- Це продуктовий / маркетинговий документ, не engineering spec.
- «Цифри, яким можна вірити» — внутрішній критерій якості в `docs/internal/`, не slogan ASC.
- Reports Hub уже в тоні канону: `reportsPLTitle` = «Скільки залишилось» / «What's left».

Останнє оновлення: 2026-11-12.

---

## Канон меседжу

### Головний хук (ASC opener / скрін 1)

| | |
|---|---|
| UK | Багато продажів, а грошей немає? |
| EN | Lots of sales — but no money left? |

### Insight

| | |
|---|---|
| UK | Прибуток — це не виручка. Прибуток — це те, що залишається. |
| EN | Profit isn’t revenue. Profit is what’s left. |

### Supporting line (конкретика витрат)

| | |
|---|---|
| UK | …після закупок, оренди і зарплат |
| EN | …after supplies, rent, and payroll |

### Обіцянка

| | |
|---|---|
| UK | TrackMyCafe покаже, скільки заробляєш, скільки витрачаєш і що залишається — без Excel. |
| EN | TrackMyCafe shows what you earn, what you spend, and what’s left — without spreadsheets. |

### Шари (не плутати)

| Шар | Формулювання |
|---|---|
| Що шукає юзер | «Продажів багато — грошей немає» / чи прибуткова кав’ярня |
| Що продаємо | Простий облік продажів, витрат і прибутку для маленької кав’ярні |
| Що має працювати всередині | COGS snapshot, P&L, склад — цифри, яким можна вірити |

### Чого уникаємо назовні

- «Довіра до цифр» як слоган
- «Повна фінансова картина», «відкрий потенціал», «детальна аналітика»
- Перелік модулів замість болю власника
- Обіцянки без фічі в коді (напр. export)
- Paid UA без CAC / LTV / cost-to-serve

---

## App Store Connect

**Source of truth:** [`app-store/LISTING.md`](app-store/LISTING.md)

Коротко:

| Поле | UK (канон) |
|---|---|
| Subtitle | Прибуток — не виручка |
| Promo text | Багато продажів, а грошей немає? … після закупок, оренди і зарплат |
| Description | Live-каркас збережено; без export; можливості = shipped v1.2 |
| Screenshots | Current застарілі → proposed 6-pack у LISTING §4 |

---

## In-app copy (цільові рядки для `Global.strings`)

Ключі існують; поточні рядки онбордингу/paywall ще загальні — синхронізувати окремим кроком.

### Onboarding slides

| Key | UK | EN |
|---|---|---|
| `onboardingSlide1Title` | Багато продажів? | Lots of sales? |
| `onboardingSlide1Desc` | А що залишилось після закупок, оренди і зарплат? TrackMyCafe покаже прибуток — не лише виручку. | What’s left after supplies, rent, and payroll? See profit — not just revenue. |
| `onboardingSlide2Title` | Продажі без хаосу | Sales without chaos |
| `onboardingSlide2Desc` | Швидкі чеки на зміні. Цифри одразу в підсумку. | Fast receipts on shift. Numbers flow straight into your totals. |
| `onboardingSlide3Title` | Витрати під контролем | Costs under control |
| `onboardingSlide3Desc` | Продукти, оренда, зарплати та інші витрати — в одному місці. | Supplies, rent, payroll, and other expenses — in one place. |
| `onboardingSlide4Title` | Твої дані в хмарі | Your data in the cloud |
| `onboardingSlide4Desc` | Синхронізація між пристроями. Власник і команда — з різними ролями. | Sync across devices. Owner and staff with different roles. |

### Paywall / banner

| Key | UK | EN |
|---|---|---|
| `subscriptionBannerDescription` | Бач, що залишилось після закупок, оренди і зарплат. | See what’s left after supplies, rent, and payroll. |
| `subscriptionSubtitle` | Прибуток — не виручка | Profit isn’t revenue |
| `subscriptionFeature1` | Чистий прибуток за період | Net profit for any period |
| `subscriptionFeature2` | Собівартість і автосписання | Food cost & auto write-off |
| `subscriptionFeature3` | Оренда, зарплати, інші витрати | Rent, payroll, other expenses |
| `subscriptionFeature4` | Що з меню робить гроші | What on the menu makes money |
| `subscriptionFeature5` | Команда з ролями в одному закладі | Team roles in one cafe |

### Вже в каноні (не змінювати без потреби)

| Key | UK | EN |
|---|---|---|
| `reportsPLTitle` | Скільки залишилось | What's left |
| `reportsPLSubtitle` | Виручка мінус усі витрати — ваш реальний прибуток. | Revenue minus all costs = your real profit. |

### Social / 10-sec pitch

| | |
|---|---|
| UK | Багато продажів, а грошей немає? TrackMyCafe покаже, що залишилось після закупок, оренди і зарплат. |
| EN | Lots of sales but no money left? TrackMyCafe shows what’s left after supplies, rent, and payroll. |

---

## Наступні кроки

### A. App Store

Див. [`app-store/LISTING.md`](app-store/LISTING.md) §6.

- [x] Затвердити тексти LISTING (subtitle, description UK/EN, promo, keywords).
- [x] Перезняти iPhone 6 + iPad 6 × UK/EN → залито в ASC 2026-11-12 (v1.2.0).
- [ ] (Опційно) Перезняти iPad Home з додатним прибутком; EN seed у `$`.
- [ ] App Preview 15–30 сек.

### B. In-app strings — **наступний пріоритет**

- [ ] Оновити `uk.lproj/Global.strings` і `en.lproj/Global.strings` (onboarding + paywall) з таблиць вище.
- [ ] Не чіпати `R.generated.swift`.
- [ ] Перевірити UI на UK/EN + Dynamic Type.

### C. Валідація

- [ ] 5–10 власників: хук «Багато продажів, а грошей немає?» — «Це про тебе?»
- [ ] «Перший скрін ASC = твоя проблема?»

### D. Paid UA — пізніше

Лише після organic listing + доказу LTV >> CAC на платячого власника.

---

## Контекст

B2C-трекери з дешевим Android + Play ads не копіюємо каналом.  
Беремо: біль у першому рядку + unit economics.  
TrackMyCafe = ніша власника маленької кав’ярні, iOS-first.
