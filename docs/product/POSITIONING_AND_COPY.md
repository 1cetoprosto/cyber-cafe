# TrackMyCafe — Positioning & Copy Pack

## Роль документа

Канон **зовнішнього позиціонування** + in-app copy (онбординг / paywall).

Повний App Store Connect пакет (description, keywords, audit скрінів, proposed set):  
**[`app-store/LISTING.md`](app-store/LISTING.md)**.

- Це продуктовий / маркетинговий документ, не engineering spec.
- «Цифри, яким можна вірити» — внутрішній критерій якості в `docs/internal/`, не slogan ASC.
- Reports Hub уже в тоні канону: `reportsPLTitle` = «Скільки залишилось» / «What's left».

Останнє оновлення: 2026-11-21.

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

## First-run onboarding (канон)

**Тип:** утиліта + ідея. Без квизу / питань.  
**Джоб:** показати цикл **чек → витрати → що залишилось**, потім trial.  
**Правило:** кожен екран або рухає цей цикл, або веде до trial. Немає «онбордингу заради онбордингу».

### Психологічна дуга → підписка

| # | Екран | Механіка | Результат |
|---|---|---|---|
| 1 | Чек → підсумок зміни | Впізнавання + звичка «продажі = успіх» | Людина бачить знайому картину зміни |
| 2 | Витрати | Loss aversion / контраст | Виручка вже не виглядає як «гроші в кишені» |
| 3 | Що залишилось | Clarity + endowment («ага») | Отримана відповідь, заради якої відкрили апку |
| 4 | Trial / paywall | Зняття ризику; той самий меседж | Купують контроль, який щойно відчули — не список фіч |

Paywall **продає те, що вже показали на екрані 3**, не нову історію і не «хмару / ролі».

### Валюта і демо-цифри (обов’язково)

- Суми **форматувати** через `NumberFormatter` + символ валюти (settings / `Locale.current`), не хардкод `₴` / `$` у copy.
- **Один чек ≠ підсумок зміни.** Чек (кава + круасан) і виручка за зміну — різні числа на одному екрані.
- **Не калькувати US з UA** (не підставляти `$` замість `₴` на ті самі тисячі).

| Ринок | 1 чек (кава + круасан) | Виручка за зміну | Витрати (ілюстрація) | Залишилось |
|---|---|---|---|---|
| UA (`uk` / UAH) | ₴220 | ₴12 400 | продукти ₴4 800 · оренда (день) ₴1 200 · зарплата ₴3 500 | **₴2 900** |
| US / EN default (`en` / USD) | $9.50 | $980 | supplies $320 · rent (day) $95 · payroll $280 | **$285** |

Інші валюти: той самий **порядок величин**, що для локального ринку кав’ярні; символ з locale/settings.

### Екран 1 — Чек → зміна

| | UK | EN |
|---|---|---|
| Title | Продажів багато? | Lots of sales? |
| Sub | Ось виручка за зміну. Кожен чек одразу потрапляє в підсумок — без Excel. | Here’s a full shift’s sales. Every receipt lands in the total — no spreadsheet. |
| Visual | Один продаж (кава й круасан) → велика **виручка за зміну** |
| CTA | Далі | Continue |

### Екран 2 — Витрати

| | UK | EN |
|---|---|---|
| Title | Але грошей менше | But less cash in hand |
| Sub | Продукти, оренда й зарплата вже забрали своє. Велика виручка — ще не твої гроші. | Food, rent, and wages already took their cut. Big sales aren’t money in your pocket. |
| Visual | Виручка **перекреслена** + мінус продукти / оренда / зарплата |
| CTA | Показати, що лишилось | Show what’s left |

### Екран 3 — Що залишилось

| | UK | EN |
|---|---|---|
| Title | Ось що насправді твоє | Here’s what’s actually yours |
| Sub | З %@ виручки після витрат лишилось %@. Це і є прибуток. | From %@ in sales, %@ is left after costs. That’s profit. |
| Visual | Порівняння `виручка → залишок` + велика цифра прибутку |
| CTA | Спробувати на своїх цифрах | Try it on your numbers |

### Екран 4 — Trial / paywall (не окремий «онбординг»)

| Блок | UK | EN |
|---|---|---|
| Headline | Скільки лишається — на ваших цифрах | What’s left — on your numbers |
| Sub | Пробний період: чек → витрати → що залишилось | Free trial: sale → costs → what’s left |
| Features (макс. 3 на першому екрані) | Скільки залишилось · Собівартість · Усі витрати в одному місці | What’s left · Food cost · All costs in one place |
| Primary CTA | Спробувати безплатно | Try for free |
| Secondary | Пізніше / режим перегляду (як зараз у продукті) | Later / read-only (as today) |

### Чого свідомо немає в first-run

- Питань / квизу (відповіді не персоналізують пейволл).
- Окремих слайдів «хмара», «ролі», «продажі без хаосу» як feature tour.
- Соціальних доказів без реальних цифр.
- Фейкового сценарію «один чек = виручка зміни».

### Після логіну — first-win path (v1.2.1+)

Маркетинговий onboarding показує ідею. Після Sign Up / першого входу **owner** на порожній кав’ярні проходить короткий guided setup на **своїх** даних (меню → чек → витрата → «що залишилось»), без авто-demo. Demo seed лишається лише в DEBUG для скрінів. Деталі флоу: [`UserFlow.md`](UserFlow.md) § Getting Started.

---

## In-app copy (цільові рядки для `Global.strings`)

Ключі можуть лишатися `onboardingSlide1…`; **зміст** = канон вище. Поточні рядки в бінарнику ще старі — синхронізувати окремим кроком. Числа в UI брати з демо-таблиці + formatter, не з рядків локалізації.

### Onboarding slides (тексти)

| Key | UK | EN |
|---|---|---|
| `onboardingSlide1Title` | Продажів багато? | Lots of sales? |
| `onboardingSlide1Desc` | Ось виручка за зміну. Кожен чек одразу потрапляє в підсумок — без Excel. | Here’s a full shift’s sales. Every receipt lands in the total — no spreadsheet. |
| `onboardingSlide2Title` | Але грошей менше | But less cash in hand |
| `onboardingSlide2Desc` | Продукти, оренда й зарплата вже забрали своє. Велика виручка — ще не твої гроші. | Food, rent, and wages already took their cut. Big sales aren’t money in your pocket. |
| `onboardingSlide3Title` | Ось що насправді твоє | Here’s what’s actually yours |
| `onboardingSlide3Desc` | З %@ виручки після витрат лишилось %@. Це і є прибуток. | From %@ in sales, %@ is left after costs. That’s profit. |
| `onboardingSlide4Title` | _(deprecated / не показувати в first-run)_ | _(deprecated / hide from first-run)_ |
| `onboardingSlide4Desc` | _(deprecated)_ | _(deprecated)_ |

> Екран 4 у старому feature-tour («хмара») **не** входить у новий first-run. Ключ можна лишити в strings до cleanup, але не показувати.  
> UK і EN пишемо **окремо нативно**, не калькуємо одне з одного.

### Paywall / banner

| Key | UK | EN |
|---|---|---|
| `subscriptionPaywallHeadline` | Скільки лишається — на ваших цифрах | What’s left — on your numbers |
| `subscriptionPaywallTrialSubtitle` | Пробний період: чек → витрати → що залишилось | Free trial: sale → costs → what’s left |
| `subscriptionBannerDescription` | Скільки лишається після продуктів, оренди й зарплат. | See what’s left after food, rent, and wages. |
| `subscriptionSubtitle` | Прибуток — це не виручка | Profit isn’t the same as sales |
| `subscriptionFeature1` | Скільки реально залишилось за період | See what’s left for any period |
| `subscriptionFeature2` | Собівартість і списання зі складу | Food cost and stock write-offs |
| `subscriptionFeature3` | Оренда, зарплата та інші витрати | Rent, wages, and other costs |
| `subscriptionFeature4` | Які позиції меню реально заробляють | Which menu items actually earn |
| `subscriptionFeature5` | Працівники з різними ролями в одному закладі | Staff with roles in one cafe |

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

### B. In-app onboarding + strings

- [x] Зібрати first-run UI під канон «First-run onboarding» (3 екрани демо-циклу → trial; без slide 4 «хмара»).
- [x] Демо-суми з таблиці UA/US + `NumberFormatter` / currency symbol (settings або `Locale`).
- [x] Оновити `uk.lproj/Global.strings` і `en.lproj/Global.strings` (onboarding + paywall) з таблиць вище.
- [x] First-run paywall subtitle: `subscriptionPaywallTrialSubtitle` (Settings лишає `subscriptionSubtitle`).
- [x] Не чіпати `R.generated.swift`.
- [ ] Перевірити UI на UK/EN + Dynamic Type + обидві валютні демо-гілки (ручний прогін на симі).

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
