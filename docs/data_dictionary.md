# Data Dictionary

## customers

| Column | Description |
|----------|-------------|
| customer_id | Unique customer identifier |
| customer_unique_id | Unique customer across orders |
| customer_zip_code_prefix | Customer ZIP prefix |
| customer_city | Customer city |
| customer_state | Customer state |

---

## orders

| Column | Description |
|----------|-------------|
| order_id | Unique order identifier |
| customer_id | Customer reference |
| order_status | Order status |
| order_purchase_timestamp | Purchase timestamp |
| order_approved_at | Approval timestamp |

---

## order_items

| Column | Description |
|----------|-------------|
| order_id | Order reference |
| product_id | Product reference |
| seller_id | Seller reference |
| price | Item price |
| freight_value | Shipping cost |

---

## payments

| Column | Description |
|----------|-------------|
| payment_type | Payment method |
| payment_value | Payment amount |

---

## reviews

| Column | Description |
|----------|-------------|
| review_score | Customer rating |
| review_comment_message | Review text |

---

## products

| Column | Description |
|----------|-------------|
| product_id | Product identifier |
| product_category_name | Product category |

---

## sellers

| Column | Description |
|----------|-------------|
| seller_id | Seller identifier |
| seller_city | Seller city |
| seller_state | Seller state |

---

## geolocation

| Column | Description |
|----------|-------------|
| geolocation_lat | Latitude |
| geolocation_lng | Longitude |