#  API Donate-cafe

## Data model

### Налаштування
GoodsPriceModel - Товари і планові ціни
TypeOfDonationModel - типи пожертвувань

### Данні
PurchaseModel - Закупки товарів
SalesModel - Пожертвування в розрізі типів та днів
SaleGoodModel - Видача товарів по дням

## Get-requests

## 1. Отримання налаштувань списку товарів (GoodsPriceModel)
{
  "GoodsPrice": [
    {
      "good": "Esspresso",
      "price": 10
    },
    {
      "good": "Americano",
      "price": 10
    },
    {
      "good": "Americano with milk",
      "price": 10
    }
  ]
}
## 2. Отримання налаштувань списку типів донатів (TypeOfDonationModel)
{
  "TypeOfDonation": [
    {
      "type": "Sunday"
    },
    {
      "type": "Morning pray"
    },
    {
      "type": "Milk"
    }
  ]
}
## 3. Отримання списку закупівель за період (PurchaseModel)
{
  "Purchase": [
    {
      "purchaseDate": "2022-04-15T13:17:05.273Z",
      "purchaseGood": "Молоко",
      "purchaseSum": 332.8
    },
    {
      "purchaseDate": "2022-04-15T13:17:05.273Z",
      "purchaseGood": "Coffe",
      "purchaseSum": 280
    },
    {
      "purchaseDate": "2022-04-15T13:17:05.273Z",
      "purchaseGood": "Sugar",
      "purchaseSum": 33
    }
  ]
}
## 4. Отримання списку донатів за період (SalesModel)
{
  "Sales": [
    {
      "salesDate": "2022-04-15T13:17:05.273Z",
      "salesTypeOfDonation": "Morning pray",
      "salesSum": 0,
      "salesCash": 144
    },
    {
      "salesDate": "2022-04-15T13:17:05.273Z",
      "salesTypeOfDonation": "Молоко",
      "salesSum": 0,
      "salesCash": 120
    },
    {
      "salesDate": "2022-04-15T13:17:05.273Z",
      "salesTypeOfDonation": "Sunday",
      "salesSum": 0,
      "salesCash": 567
    }
  ]
}
## 5. Отримання донату за день (SaleGoodModel + SalesModel)
{
  "salesDate": "2022-04-15T13:17:05.273Z",
  "salesTypeOfDonation": "Sunday",
  "salesSum": 140,
  "salesCash": 567,
  "SaleGood": [
    {
      "saleDate": "2022-04-15T13:17:05.273Z",
      "saleGood": "Americano",
      "saleQty": 2,
      "salePrice": 10,
      "saleSum": 20
    },
    {
      "saleDate": "2022-04-30T09:30:20.123Z",
      "saleGood": "Americano with milk",
      "saleQty": 12,
      "salePrice": 10,
      "saleSum": 120
    }
  ]
}


## POST-requests

## 1. GoodsPriceModel
{
    "good": "Milk",
    "price": 34.80
}
## 2. TypeOfDonationModel
{
    "type": "Sunday"
}
## 3. PurchaseModel
{
    "purchaseDate": "2022-04-15T13:17:05.273Z",
    "purchaseGood": "Молоко",
    "purchaseSum": 34
}
## 4. Sale
### 4.1 SalesModel
{
    "salesDate": "2022-04-15T13:17:05.273Z",
    "salesTypeOfDonation": "Молоко",
    "salesSum": 0.00,
    "salesCash": 120.00,
    "SaleGood": []
}
### 4.1 SalesModel + SaleGoodModel

{
  "salesDate": "2022-04-15T13:17:05.273Z",
  "salesTypeOfDonation": "Sunday",
  "salesSum": 0,
  "salesCash": 120,
  "SaleGood": [
    {
      "saleDate": "2022-04-30T09:30:20.123Z",
      "saleGood": "Americano",
      "saleQty": 2,
      "salePrice": 10,
      "saleSum": 20
    },
    {
      "saleDate": "2022-04-30T09:30:20.123Z",
      "saleGood": "Americano with milk",
      "saleQty": 12,
      "salePrice": 10,
      "saleSum": 120
    }
  ]
}




