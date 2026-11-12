# App Store assets

| Файл / папка | Призначення |
|---|---|
| [`LISTING.md`](LISTING.md) | Канон ASC: subtitle, description, keywords, screenshot status |
| [`retention-messaging.md`](retention-messaging.md) | ASC Retention Messaging (cancel flow): EN/UK copy, offer, checklist — issue `#291` |
| [`SCREENSHOTS_AGENT_TASK.md`](SCREENSHOTS_AGENT_TASK.md) | Бриф зйомки (архівний; iPhone+iPad **залиті** 2026-11-12) |
| `screenshots/current/` | **Live в ASC** — iPhone + iPad, UK + EN (`01`…`06`) |
| `screenshots/proposed/` | Робочі артефакти: overlays, `_raw/`, frame asset (для перезйомки) |
| `retention/` | Image для Retention Messaging |

Позиціонування / in-app copy: [`../POSITIONING_AND_COPY.md`](../POSITIONING_AND_COPY.md).

## Live screenshots (залито в ASC 2026-11-12, версія 1.2.0)

```text
screenshots/current/uk/01-home.png … 06-team.png          # iPhone 1290×2796
screenshots/current/en/01-home.png … 06-team.png
screenshots/current/ipad/uk/01-home.png … 06-team.png    # iPad 2048×2732
screenshots/current/ipad/en/01-home.png … 06-team.png
```

Overlay copy: [`screenshots/proposed/OVERLAY_COPY_UK.md`](screenshots/proposed/OVERLAY_COPY_UK.md), [`OVERLAY_COPY_EN.md`](screenshots/proposed/OVERLAY_COPY_EN.md).  
Деталі зйомки: [`screenshots/proposed/MANIFEST.md`](screenshots/proposed/MANIFEST.md).

## Metadata (залито разом зі скрінами)

Subtitle / Description / Keywords / Promotional Text / What’s New — у [`LISTING.md`](LISTING.md) §2; файли deliver: `fastlane/metadata/{uk,en-US}/`.
