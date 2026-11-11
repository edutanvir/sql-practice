-- 15 Interview-style business questions: mixed topics, no hints about which technique to use
-- Day 15 and beyond. Do these under a timer (15 minutes each) and explain your approach out loud.
-- Revenue of a line = quantity * unit_price * (1 - discount_pct / 100.0). Completed orders count as sales.

-- Q1 [medium] A monthly business report in one query, for completed orders only: month ('YYYY-MM'), orders,
-- customers (distinct), revenue (rounded to 2 decimals), aov (revenue / orders, rounded to 2 decimals).
SELECT strftime('%Y-%m', o.order_date) AS month,
       COUNT(DISTINCT o.order_id) AS orders,
       COUNT(DISTINCT o.customer_id) AS customers,
       ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0)), 2) AS revenue,
       ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0)) / COUNT(DISTINCT o.order_id), 2) AS aov
FROM orders AS o
JOIN order_items AS oi ON oi.order_id = o.order_id
WHERE o.status = 'completed'
GROUP BY month
ORDER BY month;

-- Q2 [medium] The top 3 customers by completed revenue inside each acquisition channel.
-- Show acquisition_channel, customer_id, revenue (rounded to 2 decimals), position (1, 2, 3).
-- If two customers tie, show both.
WITH spend AS (
    SELECT c.acquisition_channel, c.customer_id,
           SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0)) AS revenue
    FROM customers AS c
    JOIN orders AS o ON o.customer_id = c.customer_id AND o.status = 'completed'
    JOIN order_items AS oi ON oi.order_id = o.order_id
    GROUP BY c.acquisition_channel, c.customer_id
),
ranked AS (
    SELECT *, RANK() OVER (PARTITION BY acquisition_channel ORDER BY revenue DESC) AS position
    FROM spend
)
SELECT acquisition_channel, customer_id, ROUND(revenue, 2) AS revenue, position
FROM ranked
WHERE position <= 3;

-- Q3 [medium] Customers who bought from at least 4 different product categories. Show customer_id,
-- categories (how many). Most first, ties by customer_id.
SELECT o.customer_id, COUNT(DISTINCT p.category) AS categories
FROM orders AS o
JOIN order_items AS oi ON oi.order_id = o.order_id
JOIN products AS p ON p.product_id = oi.product_id
GROUP BY o.customer_id
HAVING COUNT(DISTINCT p.category) >= 4
ORDER BY categories DESC, o.customer_id;

-- Q4 [hard] Activation: what percentage of each acquisition channel's customers placed an order within 30 days of
-- signing up? Show acquisition_channel, customers, activated, activation_pct (rounded to 1 decimal).
WITH first_order AS (
    SELECT customer_id, MIN(order_date) AS first_date FROM orders GROUP BY customer_id
)
SELECT c.acquisition_channel,
       COUNT(*) AS customers,
       SUM(f.first_date IS NOT NULL AND julianday(f.first_date) - julianday(c.signup_date) <= 30) AS activated,
       ROUND(100.0 * SUM(f.first_date IS NOT NULL AND julianday(f.first_date) - julianday(c.signup_date) <= 30) / COUNT(*), 1) AS activation_pct
FROM customers AS c
LEFT JOIN first_order AS f ON f.customer_id = c.customer_id
GROUP BY c.acquisition_channel;

-- Q5 [hard] Basket size: the share of completed orders with 1, 2, 3 or 4+ items (lines). Show basket_size
-- ('1', '2', '3', '4+'), orders, pct (rounded to 1 decimal).
WITH sizes AS (
    SELECT o.order_id, COUNT(*) AS n
    FROM orders AS o
    JOIN order_items AS oi ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY o.order_id
)
SELECT CASE WHEN n >= 4 THEN '4+' ELSE CAST(n AS TEXT) END AS basket_size,
       COUNT(*) AS orders,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM sizes), 1) AS pct
FROM sizes
GROUP BY basket_size
ORDER BY basket_size;

-- Q6 [hard] The Pareto question: how many customers account for the first 80% of completed revenue?
-- Rank customers by revenue (biggest first) and find how many it takes for the cumulative share to reach
-- 80%. One row: customers_needed, total_customers, pct_of_customers (rounded to 1 decimal).
WITH spend AS (
    SELECT o.customer_id,
           SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0)) AS revenue
    FROM orders AS o
    JOIN order_items AS oi ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY o.customer_id
),
cum AS (
    SELECT customer_id, revenue,
           SUM(revenue) OVER (ORDER BY revenue DESC, customer_id) AS running,
           SUM(revenue) OVER () AS total,
           ROW_NUMBER() OVER (ORDER BY revenue DESC, customer_id) AS rn
    FROM spend
)
SELECT (SELECT MIN(rn) FROM cum WHERE running >= 0.8 * total) AS customers_needed,
       COUNT(*) AS total_customers,
       ROUND(100.0 * (SELECT MIN(rn) FROM cum WHERE running >= 0.8 * total) / COUNT(*), 1) AS pct_of_customers
FROM cum;

-- Q7 [hard] Products that sell better than their category average: for each product with at least 100 units
-- sold, compare its units to the average units per product in its category. Show category, product_name,
-- units, category_avg_units (rounded to 1 decimal) for products above the category average.
WITH product_units AS (
    SELECT p.product_id, p.category, p.product_name, SUM(oi.quantity) AS units
    FROM order_items AS oi
    JOIN products AS p ON p.product_id = oi.product_id
    GROUP BY p.product_id, p.category, p.product_name
),
with_avg AS (
    SELECT *, AVG(units) OVER (PARTITION BY category) AS category_avg_units
    FROM product_units
)
SELECT category, product_name, units, ROUND(category_avg_units, 1) AS category_avg_units
FROM with_avg
WHERE units >= 100 AND units > category_avg_units;
-- Tip: the average is calculated over all products of the category, then the filter on units >= 100 is applied.

-- Q8 [hard] Discount effect: for each discount level (0, 10, 15, 20, 25) show lines, units and the share of lines
-- that belong to orders later returned. Show discount_pct, lines, units, returned_pct (rounded to 1 decimal).
SELECT oi.discount_pct,
       COUNT(*) AS lines,
       SUM(oi.quantity) AS units,
       ROUND(100.0 * SUM(o.status = 'returned') / COUNT(*), 1) AS returned_pct
FROM order_items AS oi
JOIN orders AS o ON o.order_id = oi.order_id
GROUP BY oi.discount_pct
ORDER BY oi.discount_pct;

-- Q9 [hard] Customers who placed a second order within 14 days of their first. Show customer_id, first_order,
-- second_order, days_between. (Use ROW_NUMBER to find the first and second.)
WITH numbered AS (
    SELECT customer_id, order_date,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date, order_id) AS rn
    FROM orders
)
SELECT a.customer_id, a.order_date AS first_order, b.order_date AS second_order,
       CAST(julianday(b.order_date) - julianday(a.order_date) AS INTEGER) AS days_between
FROM numbered AS a
JOIN numbered AS b ON b.customer_id = a.customer_id AND a.rn = 1 AND b.rn = 2
WHERE julianday(b.order_date) - julianday(a.order_date) <= 14;

-- Q10 [explore] Open question: look at the numbers by month and channel and write down three things you
-- would tell the business. For example: Is 2026 growing or shrinking compared with 2025, and is it
-- the same on every channel? (Hint: January 2025 is the start of the data, so the first months are a ramp-up and
-- should not be compared with the later months.) Write the query that supports each of your three points.
SELECT strftime('%Y-%m', o.order_date) AS month, o.channel, COUNT(*) AS orders
FROM orders AS o
GROUP BY month, o.channel
ORDER BY month, o.channel;
