# Data Warehouse Design

## Overview

The warehouse is a PostgreSQL **star schema** built from the Brazilian Olist
e-commerce dataset. Raw CSVs land in staging, are cleaned and conformed, then loaded
into dimension and fact tables. Analytics marts are derived on top of the star for the
executive cases and the Power BI semantic model.

```
raw CSV  →  staging tables  →  dimensions + facts (star)  →  analytics marts  →  Power BI
```

Pipeline code: [`src/etl/`](../src/etl) (extract/transform/load) and
[`src/database/`](../src/database) (schema build + validation). DDL in
[`sql/setup/`](../sql/setup); loads in [`sql/transform/`](../sql/transform);
checks in [`sql/validation/`](../sql/validation).

---

## Grain

| Table | Type | Grain (one row per…) |
|---|---|---|
| `dim_customers` | dimension | customer record (Olist `customer_id`, order-scoped) |
| `dim_products` | dimension | product |
| `dim_sellers` | dimension | seller |
| `dim_date` | dimension | calendar day |
| `fact_orders` | fact | order |
| `fact_order_items` | fact | order line item (order × product × seller) |
| `fact_payments` | fact | payment transaction on an order |
| `fact_reviews` | fact | review submitted for an order |

> **Known grain caveat:** Olist `customer_id` is unique per order; the stable customer
> key is `customer_unique_id`. `dim_customers` is therefore effectively at order grain.
> Customer-level metrics use `DISTINCTCOUNT(customer_unique_id)`. The ML layer (RFM, churn) rebuilds customer-grain features directly on `customer_unique_id`.

---

## Dimensions

### dim_customers
`customer_id` (key) · `customer_unique_id` · `zip_code_prefix` · `customer_city` · `customer_state`

### dim_products
`product_id` (key) · `product_category_name` · dimensions/weight attributes

### dim_sellers
`seller_id` (key) · `seller_city` · `seller_state`

### dim_date
`date` (key) · `year` · `quarter` · `month` · `month_name` · `day`
Marked as the model Date table; exposes the `Calendar` hierarchy (Year → Quarter → Month → Date).

---

## Facts

### fact_orders
`order_id` (key) · `customer_id` (FK) · `order_status` · `order_purchase_timestamp` ·
`order_approved_at` · `order_delivered_carrier_date` · `order_delivered_customer_date` ·
`order_estimated_delivery_date`. Order-level timestamps drive fulfillment timing.

### fact_order_items
`order_id` (FK) · `order_item_id` · `product_id` (FK) · `seller_id` (FK) · `price` ·
`freight_value` · `shipping_limit_date`.

### fact_payments
`order_id` (FK) · `payment_sequential` · `payment_type` · `payment_installments` · `payment_value`.

### fact_reviews
`review_id` · `order_id` (FK) · `review_score` · `review_comment_message` ·
`review_creation_date` · `review_answer_timestamp`.

---

## Relationships (semantic model star)

| From | To | Cardinality | Filter |
|---|---|---|---|
| `fact_order_items[order_id]` | `fact_orders[order_id]` | Many→One | single |
| `fact_order_items[product_id]` | `dim_products[product_id]` | Many→One | single |
| `fact_order_items[seller_id]` | `dim_sellers[seller_id]` | Many→One | single |
| `fact_payments[order_id]` | `fact_orders[order_id]` | Many→One | single |
| `fact_reviews[order_id]` | `fact_orders[order_id]` | Many→One | single |
| `fact_orders[customer_id]` | `dim_customers[customer_id]` | One→One* | both* |
| `fact_orders[Order Date]` | `dim_date[Date]` | Many→One | single |

\* 1:1 + bidirectional is a consequence of the customer-grain caveat above, not a
design choice. See remediation P5.

---

## Analytics marts

Derived from the star for the executive cases ([`sql/analytics_marts/`](../sql/analytics_marts)):

| Mart | Built from | Used by |
|---|---|---|
| `customer_retention_mart` | orders + payments + customers | Case 1 — retention, CLV segments |
| `marketing_roi_mart` | same scaffold + LTV proxy + priority matrix | Case 2 — see reframe note¹ |
| `customer_segmentation_mart` | RFM-style customer attributes | Case 3 — segmentation |
| `order_fulfillment_funnel_mart` | orders + items + reviews, denormalized (order grain) | Case 4 — fulfillment funnel |

¹ `marketing_roi_mart` contains no CAC/ROAS/channel data (absent from Olist); it is a
customer-value + prioritisation mart. Reframe tracked in remediation P4.

---

## ETL & data quality

- **Extract** raw CSVs → **load_staging** → **transform** (clean/conform) →
  **populate_dimensions** → **populate_facts**.
- Validation: [`sql/validation/warehouse_validation.sql`](../sql/validation/warehouse_validation.sql)
  and [`src/database/validate_warehouse.py`](../src/database/validate_warehouse.py) —
  row-count reconciliation, referential-integrity and null checks against staging.
- All monetary values in BRL (R$).
