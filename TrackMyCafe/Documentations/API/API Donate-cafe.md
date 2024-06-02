#  API Cyber-cafe

  ## Data model

   ### Налаштування
      ProductsPriceModel - Товари і планові ціни
      TypeModel - типи замовлень

   ### Данні
      CostModel - Витрати
      OrdersModel - Замовлення
      ProductModel - Товари/послуги

  ## Get-requests

  ## 1. Отримання налаштувань списку товарів (ProductsPriceModel)
    {
      "ProductsPrice": [
        {
          "product": "Esspresso",
          "price": 10
        },
        {
          "product": "Americano",
          "price": 10
        },
        {
          "product": "Americano with milk",
          "price": 10
        }
      ]
    }
  ## 2. Отримання налаштувань списку типів донатів (TypeModel)
    {
      "Type": [
        {
          "name": "Sunday service"
        },
        {
          "name": "Morning pray"
        },
        {
          "name": "Milk"
        }
      ]
    }
  ## 3. Отримання списку закупівель за період (CostModel)
    {
      "Cost": [
        {
          "Date": "2022-04-15T13:17:05.273Z",
          "Product": "Молоко",
          "Sum": 332.8
        },
        {
          "Date": "2022-04-15T13:17:05.273Z",
          "Product": "Coffe",
          "Sum": 280
        },
        {
          "Date": "2022-04-15T13:17:05.273Z",
          "Product": "Sugar",
          "Sum": 33
        }
      ]
    }
  ## 4. Отримання списку замовлень за період (OrdersModel)
    {
      "Orders": [
        {
          "date": "2022-04-15T13:17:05.273Z",
          "type": "Morning pray",
          "sum": 0,
          "cash": 144,
          "card": 100
        },
        {
          "date": "2022-04-15T13:17:05.273Z",
          "type": "Молоко",
          "sum": 0,
          "cash": 120,
          "card": 100
        },
        {
          "date": "2022-04-15T13:17:05.273Z",
          "type": "Sunday service",
          "sum": 0,
          "cash": 567,
          "card": 100
        }
      ]
    }
  ## 5. Продажі за день (ProductModel + OrdersModel)
    {
      "date": "2022-04-15T13:17:05.273Z",
      "type": "Sunday service",
      "sum": 140,
      "cash": 567,
      "caкв": 250,
      "Products": [
        {
          "date": "2022-04-15T13:17:05.273Z",
          "name": "Americano",
          "qty": 2,
          "price": 10,
          "sum": 20
        },
        {
          "date": "2022-04-30T09:30:20.123Z",
          "name": "Americano with milk",
          "qty": 12,
          "price": 10,
          "sum": 120
        }
      ]
    }


  ## POST-requests

  ## 1. ProductsPriceModel
    {
        "name": "Milk",
        "price": 34.80
    }
  ## 2. TypeModel
    {
        "name": "Sunday service"
    }
  ## 3. CostModel
    {
        "date": "2022-04-15T13:17:05.273Z",
        "product": "Молоко",
        "sum": 34
    }
  ## 4. Order
   ### 4.1 OrdersModel
      {
          "date": "2022-04-15T13:17:05.273Z",
          "type": "Молоко",
          "sum": 0.00,
          "cash": 120.00,
          "card": 80.00,
          "Products": []
      }
   ### 4.1 OrdersModel + ProductModel
      {
        "date": "2022-04-15T13:17:05.273Z",
        "type": "Sunday service",
        "sum": 0,
        "cash": 120,
        "card": 80.00,
        "Products": [
          {
            "date": "2022-04-30T09:30:20.123Z",
            "product": "Americano",
            "qty": 2,
            "price": 10,
            "sum": 20
          },
          {
            "odate": "2022-04-30T09:30:20.123Z",
            "product": "Americano with milk",
            "qty": 12,
            "price": 10,
            "sum": 120
          }
        ]
      }




