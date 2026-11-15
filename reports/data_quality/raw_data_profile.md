# Raw Data Discovery & Profile Report
**Generated at:** 2026-11-12 22:47:29
**Source Directory:** `E:\Learning\Projects\data analyst\data\raw`

## 1. File Integrity & Provenance (SHA-256)

| File | Size (MB) | Rows | Columns | SHA-256 Checksum |
|---|---|---|---|---|
| `olist_orders_dataset.csv` | 16.84 MB | 99,441 | 8 | `8df58ef3d2d7e994...` |
| `olist_order_items_dataset.csv` | 14.31 MB | 112,650 | 7 | `4f6abdbbc94036d0...` |
| `olist_order_payments_dataset.csv` | 5.39 MB | 103,886 | 5 | `61674868ed7b872a...` |
| `olist_order_reviews_dataset.csv` | 13.78 MB | 99,224 | 7 | `012b61c7593e34f5...` |
| `olist_customers_dataset.csv` | 8.17 MB | 99,441 | 5 | `c26c17f59f3027a6...` |
| `olist_products_dataset.csv` | 2.27 MB | 32,951 | 9 | `3e6569628a17fbc7...` |
| `olist_sellers_dataset.csv` | 0.16 MB | 3,095 | 4 | `31eb9bd50d684526...` |
| `product_category_name_translation.csv` | 0.0 MB | 71 | 2 | `a81f0d1f27b27e72...` |

## 2. Table Profiles
### `olist_orders_dataset.csv` (99,441 rows, 8 cols)
**Date Ranges Identified:**
- `order_purchase_timestamp`: `2016-09-04 21:15:19` to `2018-10-17 17:30:18`
- `order_delivered_carrier_date`: `2016-10-08 10:34:01` to `2018-09-11 19:48:28`
- `order_delivered_customer_date`: `2016-10-11 13:46:32` to `2018-10-17 13:22:46`
- `order_estimated_delivery_date`: `2016-09-30 00:00:00` to `2018-11-12 00:00:00`

| Column Name | Inferred Dtype | Null Count | Null % | Distinct Values | Sample Values |
|---|---|---|---|---|---|
| `order_id` | str | 0 | 0.0% | 99,441 | e481f51cbdc54678b7cc49136f2d6af7... |
| `customer_id` | str | 0 | 0.0% | 99,441 | 9ef432eb6251297304e76186b10a928d... |
| `order_status` | str | 0 | 0.0% | 8 | delivered, delivered, delivered |
| `order_purchase_timestamp` | str | 0 | 0.0% | 98,875 | 2017-10-02 10:56:33, 2018-07-24 ... |
| `order_approved_at` | str | 160 | 0.16% | 90,733 | 2017-10-02 11:07:15, 2018-07-26 ... |
| `order_delivered_carrier_date` | str | 1,783 | 1.79% | 81,018 | 2017-10-04 19:55:00, 2018-07-26 ... |
| `order_delivered_customer_date` | str | 2,965 | 2.98% | 95,664 | 2017-10-10 21:25:13, 2018-08-07 ... |
| `order_estimated_delivery_date` | str | 0 | 0.0% | 459 | 2017-10-18 00:00:00, 2018-08-13 ... |

### `olist_order_items_dataset.csv` (112,650 rows, 7 cols)
**Date Ranges Identified:**
- `shipping_limit_date`: `2016-09-19 00:15:34` to `2020-04-09 22:35:08`

| Column Name | Inferred Dtype | Null Count | Null % | Distinct Values | Sample Values |
|---|---|---|---|---|---|
| `order_id` | str | 0 | 0.0% | 98,666 | 00010242fe8c5a6d1ba2dd792cb16214... |
| `order_item_id` | int64 | 0 | 0.0% | 21 | 1, 1, 1 |
| `product_id` | str | 0 | 0.0% | 32,951 | 4244733e06e7ecb4970a6e2683c13e61... |
| `seller_id` | str | 0 | 0.0% | 3,095 | 48436dade18ac8b2bce089ec2a041202... |
| `shipping_limit_date` | str | 0 | 0.0% | 93,318 | 2017-09-19 09:45:35, 2017-05-03 ... |
| `price` | float64 | 0 | 0.0% | 5,968 | 58.9, 239.9, 199.0 |
| `freight_value` | float64 | 0 | 0.0% | 7,010 | 13.29, 19.93, 17.87 |

### `olist_order_payments_dataset.csv` (103,886 rows, 5 cols)
| Column Name | Inferred Dtype | Null Count | Null % | Distinct Values | Sample Values |
|---|---|---|---|---|---|
| `order_id` | str | 0 | 0.0% | 99,440 | b81ef226f3fe1789b1e8b2acac839d17... |
| `payment_sequential` | int64 | 0 | 0.0% | 29 | 1, 1, 1 |
| `payment_type` | str | 0 | 0.0% | 5 | credit_card, credit_card, credit... |
| `payment_installments` | int64 | 0 | 0.0% | 24 | 8, 1, 1 |
| `payment_value` | float64 | 0 | 0.0% | 29,077 | 99.33, 24.39, 65.71 |

### `olist_order_reviews_dataset.csv` (99,224 rows, 7 cols)
**Date Ranges Identified:**
- `review_creation_date`: `2016-10-02 00:00:00` to `2018-08-31 00:00:00`
- `review_answer_timestamp`: `2016-10-07 18:32:28` to `2018-10-29 12:27:35`

| Column Name | Inferred Dtype | Null Count | Null % | Distinct Values | Sample Values |
|---|---|---|---|---|---|
| `review_id` | str | 0 | 0.0% | 98,410 | 7bc2406110b926393aa56f80a40eba40... |
| `order_id` | str | 0 | 0.0% | 98,673 | 73fc7af87114b39712e6da79b0a377eb... |
| `review_score` | int64 | 0 | 0.0% | 5 | 4, 5, 5 |
| `review_comment_title` | str | 87,656 | 88.34% | 4,527 | recomendo, Super recomendo, Não ... |
| `review_comment_message` | str | 58,247 | 58.7% | 36,159 | Recebi bem antes do prazo estipu... |
| `review_creation_date` | str | 0 | 0.0% | 636 | 2018-01-18 00:00:00, 2018-03-10 ... |
| `review_answer_timestamp` | str | 0 | 0.0% | 98,248 | 2018-01-18 21:46:59, 2018-03-11 ... |

### `olist_customers_dataset.csv` (99,441 rows, 5 cols)
| Column Name | Inferred Dtype | Null Count | Null % | Distinct Values | Sample Values |
|---|---|---|---|---|---|
| `customer_id` | str | 0 | 0.0% | 99,441 | 06b8999e2fba1a1fbc88172c00ba8bc7... |
| `customer_unique_id` | str | 0 | 0.0% | 96,096 | 861eff4711a542e4b93843c6dd7febb0... |
| `customer_zip_code_prefix` | int64 | 0 | 0.0% | 14,995 | 14409, 9790, 1151 |
| `customer_city` | str | 0 | 0.0% | 4,119 | franca, sao bernardo do campo, s... |
| `customer_state` | str | 0 | 0.0% | 27 | SP, SP, SP |

### `olist_products_dataset.csv` (32,951 rows, 9 cols)
| Column Name | Inferred Dtype | Null Count | Null % | Distinct Values | Sample Values |
|---|---|---|---|---|---|
| `product_id` | str | 0 | 0.0% | 32,951 | 1e9e8ef04dbcff4541ed26657ea517e5... |
| `product_category_name` | str | 610 | 1.85% | 73 | perfumaria, artes, esporte_lazer |
| `product_name_lenght` | float64 | 610 | 1.85% | 66 | 40.0, 44.0, 46.0 |
| `product_description_lenght` | float64 | 610 | 1.85% | 2,960 | 287.0, 276.0, 250.0 |
| `product_photos_qty` | float64 | 610 | 1.85% | 19 | 1.0, 1.0, 1.0 |
| `product_weight_g` | float64 | 2 | 0.01% | 2,204 | 225.0, 1000.0, 154.0 |
| `product_length_cm` | float64 | 2 | 0.01% | 99 | 16.0, 30.0, 18.0 |
| `product_height_cm` | float64 | 2 | 0.01% | 102 | 10.0, 18.0, 9.0 |
| `product_width_cm` | float64 | 2 | 0.01% | 95 | 14.0, 20.0, 15.0 |

### `olist_sellers_dataset.csv` (3,095 rows, 4 cols)
| Column Name | Inferred Dtype | Null Count | Null % | Distinct Values | Sample Values |
|---|---|---|---|---|---|
| `seller_id` | str | 0 | 0.0% | 3,095 | 3442f8959a84dea7ee197c632cb2df15... |
| `seller_zip_code_prefix` | int64 | 0 | 0.0% | 2,246 | 13023, 13844, 20031 |
| `seller_city` | str | 0 | 0.0% | 611 | campinas, mogi guacu, rio de jan... |
| `seller_state` | str | 0 | 0.0% | 23 | SP, SP, RJ |

### `product_category_name_translation.csv` (71 rows, 2 cols)
| Column Name | Inferred Dtype | Null Count | Null % | Distinct Values | Sample Values |
|---|---|---|---|---|---|
| `product_category_name` | str | 0 | 0.0% | 71 | beleza_saude, informatica_acesso... |
| `product_category_name_english` | str | 0 | 0.0% | 71 | health_beauty, computers_accesso... |
