-- ============================================
-- OLIST E-COMMERCE ANALYSIS
-- Phase 4: Export Queries for Python Visualizations
-- Dataset: Olist Brazilian E-Commerce
-- Database: ecommerce_analytics
-- ============================================

USE ecommerce_analytics;

-- ==========================================================
-- 1. REPEAT PURCHASE DISTRIBUTION
-- Output file: data/exported/repeat_purchase_distribution.csv
-- ==========================================================

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
ORDER BY total_orders;


-- ==========================================================
-- 2. CUSTOMER SEGMENTATION DISTRIBUTION
-- Output file: data/exported/customer_segmentation_distribution.csv
-- ==========================================================

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
ORDER BY number_of_customers DESC;


-- ==========================================================
-- 3. TOP 10 STATES BY REVENUE
-- Output file: data/exported/top_10_states_by_revenue.csv
-- ==========================================================

SELECT 
    c.customer_state,
    ROUND(SUM(oi.price), 2) AS revenue
FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
JOIN customers c
    ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY revenue DESC
LIMIT 10;


-- ==========================================================
-- 4. MONTHLY REVENUE TRENDS
-- Output file: data/exported/monthly_revenue_trends.csv
-- ==========================================================

SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY order_month;