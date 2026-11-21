# Submit checklist — TrackMyCafe **1.2.0**

Дата: 2026-11-14.  
Мета: вивести на live нові скріни + metadata (щоб UA/US перестали бачити стару вітрину).

---

## Стан зараз (перевірено в ASC)

| Елемент | Стан |
|---|---|
| Version **1.2.0** | Prepare for Submission |
| **Build на версії** | ❌ порожньо — треба **Add Build** |
| TestFlight builds **1.2.0** | ✅ **71** Ready to Submit (Internal, 2 installs); також 69 |
| Locales | ✅ English (U.S.) + **Ukrainian** (і інші) |
| UK Promo / Description / What’s New | ✅ заповнені (опенер «Багато продажів…») |
| Screenshots | ✅ залиті в ASC 2026-11-12 (див. `LISTING.md`) — **на live ще старі**, бо версія не released |
| Retention Messaging `#291` | окремо WAITING_FOR_REVIEW (не блокує 1.2.0) |

Головний блокер submit: **не вибраний build**.

---

## Кроки в ASC (15–25 хв)

### 1. Прив’язати binary

1. [App Store Connect](https://appstoreconnect.apple.com) → **Apps** → TrackMyCafe → **Distribution**
2. Версія **iOS 1.2.0**
3. Секція **Build** → **Add Build**
4. Обрати **1.2.0 (71)** (новіший за 69)
5. **Done** / зберегти

### 2. Швидка перевірка Product Page (обидві мови)

Перемкнути **English (U.S.)** і **Ukrainian**:

| Поле | Очікуємо |
|---|---|
| Name | EN: `TrackMyCafe: Easy Cafe Book` · UK: `TrackMyCafe: Легкий Облік` |
| Subtitle | EN: expenses/profit · UK: `Витрати й Прибуток Кафе` або канон з `LISTING.md` |
| Description | Без offline / export / «No credit card» (якщо раптом research CLEAN) |
| Keywords | ≤100, без дубля з Title |
| What’s New | Коротко про прибуток / дашборд (уже є UK текст) |
| Screenshots | iPhone 6 + iPad 6, UK і EN — **нові** overlays (Home / P&L / …) |

Якщо Description ще research CLEAN з офлайн/експортом — **замінити** на канон з `LISTING.md` / `fastlane/metadata/` **перед** review.

### 3. App Review Information

- [ ] **Sign-in required** — увімкнути, якщо без логіну немає демо
- [ ] Demo Apple ID / пароль (або пояснення як увійти)
- [ ] Notes: демо-дані при першому запуску (у полі вже є англ. текст — ок)
- [ ] Contact — актуальний email/телефон

### 4. Release options

Рекомендація для ASO-експерименту скрінів:

- [ ] **Manually release this version** — після Approve сам натиснеш Release, щоб зафіксувати дату для метрик  
  *або* Automatically, якщо хочеш швидше на live

- [ ] **Не** Reset Summary Rating (лише 1 оцінка — скидати сенсу немає)

### 5. Відправка

1. **Add for Review**
2. Пройти Compliance / Export / Advertising ID, якщо спитає
3. **Submit to App Review**
4. Дочекатись **Waiting for Review → In Review → Pending Developer Release / Ready for Sale**

### 6. Після Approve / Release

1. Перевірити live:  
   - [UA uk](https://apps.apple.com/ua/app/id6753102351?l=uk) — нові скріни  
   - [US](https://apps.apple.com/us/app/id6753102351) — нові скріни
2. У `baseline_ASC_2026-11-14.md` / Metrics Tracker записати **дату релізу**
3. Через **14 днів** зняти знову US + UA: Impr / Views / DL / CVR
4. Очікування: UA **Impr→View** лишається ок, **Views→DL** має вирости

---

## Якщо треба новий binary (не обов’язково)

У TestFlight уже є **71**. Новий upload потрібен лише якщо:

- хочеш інший код, ніж у 71, або
- 71 застарілий / з багом

Тоді локально (чистий git):

```bash
bin/deploy          # TrackMyCafe Prod → TestFlight
```

Після processing: Add Build → новий номер → Review.

---

## Не блокує цей submit

- In-app onboarding/paywall sync (`POSITIONING_AND_COPY`) — окремий PR
- App Preview video
- pl-PL / en-GB локалізації
- Keywords A/B
- Retention Messaging (вже в окремому review)

---

## DoD

- [ ] Build **71** (або новіший) на 1.2.0
- [ ] EN + UK metadata без overclaim
- [ ] Нові скріни на версії (iPhone+iPad)
- [ ] Review info заповнено
- [ ] Submitted
- [ ] Released → live скріни ≠ грудень 2023
- [ ] Дата релізу записана для ASO baseline
