-- 04 Aggregates: COUNT, SUM, AVG, MIN, MAX, GROUP BY, HAVING, COUNT(DISTINCT ...)
-- Day 4. Tables: orders, order_items, products, customers, employees.
-- Revenue of a line = quantity * unit_price * (1 - discount_pct / 100.0).

-- Q1 [easy] How many orders are there in each status? Show status, orders. Largest first.
SELECT status, COUNT(*) AS orders
FROM orders
GROUP BY status
ORDER BY orders DESC;

-- Q2 [easy] Overall: the first order date, the last order date and the number of orders.
-- One row: first_order, last_order, total_orders.
SELECT MIN(order_date) AS first_order, MAX(order_date) AS last_order, COUNT(*) AS total_orders
FROM orders;

-- Q3 [easy] Average, lowest and highest salary per department_id. Show department_id, avg_salary
-- (rounded to 0 decimals), min_salary, max_salary.
SELECT department_id, ROUND(AVG(salary), 0) AS avg_salary, MIN(salary) AS min_salary, MAX(salary) AS max_salary
FROM employees
GROUP BY department_id;

-- Q4 [medium] Revenue per product category from completed orders only: category, revenue
-- (rounded to 2 decimals). Biggest category first.
SELECT p.category,
       ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0)), 2) AS revenue
FROM order_items AS oi
JOIN orders   AS o ON o.order_id   = oi.order_id
JOIN products AS p ON p.product_id = oi.product_id
WHERE o.status = 'completed'
GROUP BY p.category
ORDER BY revenue DESC;

-- Q5 [medium] Customers with at least 15 orders: customer_id, orders. Most orders first.
SELECT customer_id, COUNT(*) AS orders
FROM orders
GROUP BY customer_id
HAVING COUNT(*) >= 15
ORDER BY orders DESC, customer_id;
-- Tip: WHERE filters rows before grouping, HAVING filters groups after. You cannot use COUNT(*) in WHERE.

-- Q6 [medium] How many different customers ordered in each month? Show month ('YYYY-MM') and
-- active_customers, in month order.
SELECT strftime('%Y-%m', order_date) AS month, COUNT(DISTINCT customer_id) AS active_customers
FROM orders
GROUP BY month
ORDER BY month;

-- Q7 [medium] The channel mix: for each channel show orders and the percentage of all orders
-- (rounded to 1 decimal): channel, orders, pct_of_orders.
SELECT channel,
       COUNT(*) AS orders,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM orders), 1) AS pct_of_orders
FROM orders
GROUP BY channel;

-- Q8 [medium] Categories where at least 8 different products have been sold.
-- Show category, products_sold.
SELECT p.category, COUNT(DISTINCT oi.product_id) AS products_sold
FROM order_items AS oi
JOIN products AS p ON p.product_id = oi.product_id
GROUP BY p.category
HAVING COUNT(DISTINCT oi.product_id) >= 8;

-- Q9 [medium] Average order value (AOV) per channel for completed orders, rounded to 2 decimals:
-- channel, aov. Highest first.
-- AOV = total revenue / number of orders.
SELECT o.channel,
       ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0)) / COUNT(DISTINCT o.order_id), 2) AS aov
FROM orders AS o
JOIN order_items AS oi ON oi.order_id = o.order_id
WHERE o.status = 'completed'
GROUP BY o.channel
ORDER BY aov DESC;
-- Tip: divide by COUNT(DISTINCT order_id), not COUNT(*), because the join makes one row per item.

-- Q10 [hard] Which coupon codes were used, how many orders used each, and how many of those orders were
-- returned? Show coupon_code, orders, returned_orders. Ignore orders without a coupon.
SELECT coupon_code,
       COUNT(*) AS orders,
       SUM(CASE WHEN status = 'returned' THEN 1 ELSE 0 END) AS returned_orders
FROM orders
WHERE coupon_code IS NOT NULL
GROUP BY coupon_code;
-- Tip: SUM(CASE WHEN ... THEN 1 ELSE 0 END) is the standard way to count a condition inside a group.

-- Q11 [hard] The share of items sold with a discount. For each category show items (rows in order_items),
-- discounted_items (discount_pct > 0) and pct_discounted (rounded to 1 decimal).
SELECT p.category,
       COUNT(*) AS items,
       SUM(oi.discount_pct > 0) AS discounted_items,
       ROUND(100.0 * SUM(oi.discount_pct > 0) / COUNT(*), 1) AS pct_discounted
FROM order_items AS oi
JOIN products AS p ON p.product_id = oi.product_id
GROUP BY p.category;
-- Tip: SQLite treats a true comparison as 1 and false as 0, so SUM(condition) counts. In SQL Server or
-- Spark SQL write SUM(CASE WHEN discount_pct > 0 THEN 1 ELSE 0 END) instead.

-- Q12 [hard] Top 5 products by total units sold in 2026: product_name, units (all statuses).
-- Break ties by product_name.
SELECT p.product_name, SUM(oi.quantity) AS units
FROM order_items AS oi
JOIN orders   AS o ON o.order_id   = oi.order_id
JOIN products AS p ON p.product_id = oi.product_id
WHERE o.order_date >= '2026-01-01'
GROUP BY p.product_id, p.product_name
ORDER BY units DESC, p.product_name
LIMIT 5;
