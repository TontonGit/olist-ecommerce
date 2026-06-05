-- ============================================
-- OLIST E-COMMERCE ANALYSIS
-- Phase 2: Data Quality Assessment
-- Dataset: Olist Brazilian E-Commerce
-- Database: ecommerce_analytics
-- ============================================

USE ecommerce_analytics;

-- =============================
-- I. DATA QUALITY ASSESSMENT 
-- =============================


-- TOTAL ROWS IN EACH TABLE

SELECT COUNT(*) AS total_rows FROM customers; 

SELECT COUNT(*) AS total_rows From order_items; 

SELECT COUNT(*) AS total_rows FROM orders; 

-- ====================================================================================
-- A)	CUSTOMERS TABLE
-- ====================================================================================

SELECT * FROM customers;
EXPLAIN customers;

-- CHECKING FOR DUPLICATES IN CUSTOMER_ID  

SELECT
	customer_id, 
    COUNT(*) AS customer_id_duplicates
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1
;

-- CHECKING FOR MISSING VALUES IN ALL COLUMNS

SELECT 
	SUM(CASE WHEN customer_id is NULL THEN 1 ELSE 0 END)AS missing_cust_id,
    SUM(CASE WHEN customer_unique_id is NULL THEN 1 ELSE 0 END)AS missing_cust_unique_id,
    SUM(CASE WHEN customer_city is NULL THEN 1 ELSE 0 END)AS missing_cust_city,
    SUM(CASE WHEN customer_state is NULL THEN 1 ELSE 0 END)AS missing_cust_state,
    SUM(CASE WHEN customer_zip_code_prefix is NULL THEN 1 ELSE 0 END)AS missing_cust_zip_code
FROM customers
;  
/* FINDINGS:  
No duplicate customer_id values were identified.
All customer records contain complete identifier and location information.
customer_id uniquely identifies each record and functions as the primary key
for the customers table.
*/


-- CHECKING FOR INCONSISTENCIES ENTRIES IN CUSTOMER_STATE.

SELECT 
	customer_state,
    COUNT(*) AS state_count
FROM customers
Group by customer_state
ORDER BY customer_state;

-- CHECKING FOR INCONSISTENCIES IN CUSTOMER_ZIP_CODE_PREFIX

DESCRIBE customers;

/* FINDINGS:
The customer_zip_code_prefix field is stored as an integer data type.
Some zip code prefixes contain fewer than five digits because leading zeros
are not preserved in numeric fields. This is a formatting issue rather than
a data quality issue and can be corrected using LPAD() when required for
reporting purposes.
THERE ARE NO INCONSISTENCIES IN customer_state or customer_zip_code_prefix. 
*/
 

SELECT
    customer_zip_code_prefix,
    LENGTH(customer_zip_code_prefix) AS zip_length,
    COUNT(*) AS total_records
FROM customers
GROUP BY customer_zip_code_prefix
HAVING LENGTH(customer_zip_code_prefix) <> 5
ORDER BY zip_length;

-- FORMATTING NOTES FOR customer_zip_code_prefix

SELECT
    LPAD(customer_zip_code_prefix, 5, '0') AS formatted_zip_code_prefix
FROM customers;


-- =====================================================================================
-- B)	ORDER_ITEMS TABLE
-- =====================================================================================

SELECT * FROM order_items;
DESCRIBE order_items;

-- ARE THERE MISSING VALUES IN THE FOLLOWING COLUMNS;
-- order_id, order_item_id, product_id, seller_id and shipping_limit_date


SELECT 
	SUM(CASE WHEN order_id is NULL THEN 1 ELSE 0 END) AS missing_order_id,
	SUM(CASE WHEN order_item_id is NULL THEN 1 ELSE 0 END) AS missing_order_item_id,
    SUM(CASE WHEN product_id is NULL THEN 1 ELSE 0 END) AS missing_product_id,
    SUM(CASE WHEN seller_id is NULL THEN 1 ELSE 0 END) AS missing_seller_id,
    SUM(CASE WHEN shipping_limit_date is NULL THEN 1 ELSE 0 END) AS missing_shipping_date
FROM order_items;


-- DOES THE COMPOSITE KEY (order_id, order_item_id) APPEARS MORE THAN ONCE IN AN ORDER?

SELECT
	order_id,
	order_item_id,
    COUNT(*) AS dupl_in_composite_key
FROM order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1
;
/* FINDINGS:
THERE ARE NO MISSING VALUES IN ANY OF THE COLUMNS IN ORDER_ITEMS TABLE.
NO PAIR OF COMPOSITE KEY (order_id, order_item_id) APPEARS MORE THAN ONCE
IN ANY SINGLE ORDER
*/

-- CAN ONE ORDER INVOLVE MULTIPLE SELLERS?

SELECT
	order_id,
    COUNT(DISTINCT seller_id ) AS seller_count
FROM order_items
GROUP BY order_id
HAVING COUNT(DISTINCT seller_id ) > 1
ORDER BY seller_count DESC
;
/* FINDINGS:
YES, ONE ORDER CAN INVOLVE  MANY SELLERS.
*/

-- CAN ONE SELLER FULFILL MULTIPLE ITEMS?

SELECT
	seller_id,
    COUNT(*) AS items_sold 
FROM order_items
GROUP BY seller_id
ORDER BY items_sold DESC
;
/*
A single seller can fulfill many order items, which is expected in a marketplace model.
*/


-- CAN ONE ORDER CONTAIN THE SAME PRODUCT MORE THAN ONCE?

SELECT
    order_id,
    product_id,
    COUNT(*) AS product_count
FROM order_items
GROUP BY order_id, product_id
HAVING COUNT(*) > 1
ORDER BY product_count DESC
;
/* FINDINGS:
The same order can contain the same product more than once.
*/


-- ===================================================================================
-- C) ORDERS TABLE
-- ===================================================================================
SELECT * FROM orders;
explain orders;

-- CHECK FOR MISSING VALUE IN THE FOLLOWING COLUMNS:
-- order_id, customer_id, order_status, order_purchase_timestamp,

SELECT 
	SUM(CASE WHEN order_id is NULL THEN 1 ELSE 0 END) AS missing_order_id,
	SUM(CASE WHEN customer_id is NULL THEN 1 ELSE 0 END) AS missing_customer_id,
    SUM(CASE WHEN order_status is NULL THEN 1 ELSE 0 END) AS missing_order_status,
    SUM(CASE WHEN order_purchase_timestamp is NULL THEN 1 ELSE 0 END) AS missing_timestamp
FROM orders;

/* FINDING:
No missing values were found in order_id, customer_id, order_status,
or order_purchase_timestamp. This confirms that each order has a unique
identifier, an associated customer, a status, and a recorded purchase time.
*/


-- CHECK FOR DUPLICATE VALUE IN ORDER_ID

SELECT
	order_id,
    COUNT(*) AS cnt
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY cnt DESC
;
/* FINDING:
No duplicate order_id values were identified.
order_id uniquely identifies each record and serves as the primary key
for the orders table.
*/

-- HOW MANY CATEGORIES DO WE HAVE IN THE VARIABLE order_status?

SELECT 
	order_status,
    COUNT(*) AS total_orders 
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC
;
/* 
WE HAVE 6 ORDERS THAT WERE CANCELED AND 96,455 ORDERS THAT WERE DELIVERED.
*/

-- ARE THERE ANY MISSING DATETIME VALUES IN THE ORDERS TABLE?

SELECT
    SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END) AS missing_approved,
    SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END) AS missing_carrier,
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS missing_customer_delivery,
    SUM(CASE WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END) AS missing_estimated_delivery
FROM orders;


-- HOW MANY CANCELED  ORDERS WERE NEVERTHELESS DELIVERED?

SELECT 
	COUNT(*) AS canceled_and_delivered
FROM orders
WHERE order_status = 'canceled'
AND order_delivered_customer_date IS NOT NULL
;
/* FINDING:
THE ORDERS TABLE CONTAINS ONLY TWO ORDER STATUSES: DELIVERED(96,455 ORDERS) AND CANCELED
(6 ORDERS).  DELIVERED ORDERS REPRESENT 99.99% OF ALL RECORDS, WHILE CANCELED ORDERS ACCOUNT FOR 
LESS THAN 0.01% OF THE DATASET. SIX ORDERS THAT HAVE A CANCELED STATUS HAVE ALSO A DELIVERY DATE.
*/

-- ============================================
-- CHECKING THE ENTIRE ORDERS LIFECYCLE
-- ============================================

-- CHECK FOR order_approved_at BEFORE order_purchase_timestamp

SELECT 
	COUNT(*) AS approvals_before_purchase
FROM orders
WHERE order_approved_at < order_purchase_timestamp
;

-- CHECK FOR order_delivered_carrier_date BEFORE order_approved_at

SELECT 
    COUNT(*) AS carrier_before_approval
FROM orders
WHERE order_delivered_carrier_date < order_approved_at
;

-- CHECK FOR order_delivered_customer_date BEFORE order_delivered_carrier_date

SELECT COUNT(*) AS delivered_before_carrier
FROM orders
WHERE order_delivered_customer_date < order_delivered_carrier_date;
 
/* FINDINGS:
THERE WAS 0 ORDER APPROVED AT BEFORE ORDER PURCHASE TIMESTAMP. 
A TOTAL OF 1,350 ORDERS (APPROXIMATELY 1.40% OF TOTAL RECORDS) EXHIBITED CARRIER DELIVERY DATE PRECEDING 
ORDER APPROVAL DATES.
A TOTAL OF 23 ORDERS EXHIBITED CUSTOMER DELIVERY DATES PRECEDING CARRIER DELIVERY DATES.  
THESE RECORDS WERE FLAGGED FOR FURTHER INVESTIGATION TO DETERMINE WHETHER THEY REFLECT 
OPERATIONAL PROCESSES, TIMESTAMP RECORDING DELAYS, OR DATA INCONSISTENCIES. 
*/
 
-- ==================================================================================== 
-- FINAL SUMMARY FOR DATA QUALITY ASSESSMENT
-- ====================================================================================

/*
 Data quality validation identified no duplicate primary keys, no missing values in critical
 business fields, and no material inconsistencies in customers, orders , or order_items table. 
 A small number of canceled orders (6) were found to contain delivery dates, likely reflecting 
 post-delivery refunds or cancellation workflows rather than data errors. These records were 
 retained.  
 Overall, the dataset was determined to be suitable for downstream analysis without requiring 
 substantive cleaning. 
 */

