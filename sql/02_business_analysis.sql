

-- ============================================
-- OLIST E-COMMERCE ANALYSIS
-- Phase 3: Business Analysis
-- Dataset: Olist Brazilian E-Commerce
-- Database: ecommerce_analytics
-- ============================================

USE ecommerce_analytics;

-- ==========================================================
-- CORE BUSINESS KPIs (executive metrics)
-- ==========================================================

-- Total revenue, total_freight_revenue & pct_freight_ratio

SELECT 
    ROUND(SUM(price), 2) AS total_product_revenue,
    ROUND(SUM(freight_value), 2) AS total_freight_revenue,
    ROUND(SUM(price + freight_value), 2) AS total_order_item_value,
    ROUND(SUM(freight_value) * 100 / SUM(price),2) AS pct_freight_ratio
FROM order_items
;
/* FINDINGS:
The business generated total product revenue of 13,219,045.68, total order item value of 
15,416,994.83 and a freight-to-product revenue ratio of 16.63%.
*/

-- Average order value

SELECT 
    ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id;
    
-- ==================================================================
-- CUSTOMER RETENTION ANALYSIS (retention & repeat purchase metrics)
-- ==================================================================

-- Number of customer records vs unique customers

SELECT 
    COUNT(customer_id) AS total_customer_records,
    COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM customers
;
/* FINDINGS:
96,096 unique customers account for 99,441 customer records.
*/

-- Orders per real customer

SELECT 
    customer_unique_id,
    COUNT(customer_id) AS total_orders
FROM customers
GROUP BY customer_unique_id
ORDER BY total_orders DESC;

-- Repeat purchase distribution

SELECT
    total_orders,
    COUNT(*) AS number_of_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM (
    SELECT
        customer_unique_id,
        COUNT(customer_id) AS total_orders
    FROM customers
    GROUP BY customer_unique_id
) customer_orders
GROUP BY total_orders
ORDER BY total_orders
;
/* FINDINGS:
The distribution of repeat purchases is skewed toward one-time buyers.  96.88 percent of 
the number of customers are one-time buyers when the ratio of repeat customers who buy 
6 times or more is very small, representing less than 2%.  
*/ 

-- ==========================================================================
-- CUSTOMER SEGMENTATION 
-- ==========================================================================

-- Top customers by total spent

SELECT 
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_spent,
    ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
JOIN customers c
    ON o.customer_id = c.customer_id
GROUP BY c.customer_unique_id
ORDER BY total_spent DESC
LIMIT 10;

-- Top customers by order frequency

SELECT 
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_spent
FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
JOIN customers c
    ON o.customer_id = c.customer_id
GROUP BY c.customer_unique_id
ORDER BY total_orders DESC
LIMIT 10
;
/* FINDINGS:
Our top customer by total money spent is a one-time buyer with an order for 13,440.
Our top repeat customer placed a total of 15 orders worth 714.63. 
*/

-- Customer segmentation model

SELECT 
    customer_segment,
    COUNT(*) AS number_of_customers,
    ROUND(AVG(total_spent), 2) AS avg_total_spent,
    ROUND(AVG(total_orders), 2) AS avg_total_orders,
    ROUND(AVG(avg_order_value), 2) AS avg_order_value
FROM (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(oi.price) AS total_spent,
        SUM(oi.price) / COUNT(DISTINCT o.order_id) AS avg_order_value,
        CASE 
            WHEN COUNT(DISTINCT o.order_id) >= 5 THEN 'High Frequency'
            WHEN SUM(oi.price) >= 1000 THEN 'High Value'
            WHEN SUM(oi.price) / COUNT(DISTINCT o.order_id) >= 300 THEN 'High Ticket'
            ELSE 'Regular'
        END AS customer_segment
    FROM order_items oi
    JOIN orders o
        ON oi.order_id = o.order_id
    JOIN customers c
        ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
) segmented_customers
GROUP BY customer_segment
ORDER BY avg_total_spent DESC
;
/* FINDINGS:
Customers are segmented into four categories.  We have our High Value customers with
an average order value of 1562.68, our High Frequency customers with an average total 
orders of 6.32, our High Ticket customers with average total spent of 502.11  and our 
regular customer with an average order value of 94.42 
*/


-- =========================================================================
-- GEOGRAPHIC ANALYSIS
-- =========================================================================

-- Customer concentration by state

SELECT
    customer_state,
    COUNT(DISTINCT customer_unique_id) AS total_customers,
    ROUND(
        COUNT(DISTINCT customer_unique_id) * 100.0 
        / SUM(COUNT(DISTINCT customer_unique_id)) OVER (),
        2
    ) AS percentage_of_customers
FROM customers
GROUP BY customer_state
ORDER BY total_customers DESC
;

-- Orders by customer state

SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(
        COUNT(DISTINCT o.order_id) * 100.0
        / SUM(COUNT(DISTINCT o.order_id)) OVER (),
        2
    ) AS percentage_of_orders
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY total_orders DESC;
/* FINDINGS: 
54.80 percent of our customers come from only 2 states out of the 27 states that the company 
is servicing.  A closer look shows that 41.92 percent come from the state of SP.  The company's
business is strongly concentrated in a small section of the market. 
*/


-- Revenue by state

SELECT 
    c.customer_state,
    COUNT(DISTINCT c.customer_unique_id) AS total_customers,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS revenue
FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
JOIN customers c
    ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY revenue DESC
;

-- ============================================================================
-- REVENUE TREND ANALYSIS
-- ============================================================================

-- Monthly revenue trend 

SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY order_month
;
/* FINDINGS:
The monthly revenue trends help to identify growth periods and seasonal patterns.
*/

-- Recommendation:
-- Focus on retention campaigns for High Value and High Ticket customers,
-- especially in the states with the highest customer and revenue concentration.



