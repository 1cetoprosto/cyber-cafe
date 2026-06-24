# PR3 QA Checklist

Issue: `#214`
Branch: `feat/147-pr3-home-ui-daily-balance`

## Home

- Open Home with existing finance data and verify current cash value matches `DailyBalance(today, cash)`.
- Open Home with existing finance data and verify current card value matches `DailyBalance(today, card)`.
- Switch `Today / Week / Month` and confirm income, expenses, and profit cards update without layout breaks.
- Confirm Home money block shows only current cash/card leftovers and no extra delta text.
- Verify large Dynamic Type sizes and small screens do not clip Home header content.

## Opex

- Create a new expense with `Cash` selected and verify save succeeds.
- Create a new expense with `Card` selected and verify save succeeds.
- Edit an existing expense and verify the previously selected payment method is prefilled.
- Change payment method on edit and verify save succeeds.
- Try saving without payment method and verify validation blocks the save.

## Finance Behavior

- Create a cash expense and verify Home cash leftover changes after reload.
- Create a card expense and verify Home card leftover changes after reload.
- Edit a legacy expense without `paymentAccount` and verify selecting a payment method makes it balance-affecting after save.
- Verify legacy expenses that still have no `paymentAccount` do not affect leftovers until edited and saved with a method.

## Regression

- Verify recent incomes and recent expenses sections still load on Home.
- Verify adding income from Home still opens the expected order flow.
- Verify adding expense from Home still opens cost details and returns back after save.
