-- 07 CTEs (WITH): break a hard question into named steps
-- Day 7. Tables: orders, order_items, products, customers.
-- Revenue of a line = quantity * unit_price * (1 - discount_pct / 100.0).

-- Q1 [easy] Monthly revenue of completed orders, then only the months where revenue was above the
-- average month. Show month ('YYYY-MM'), revenue (rounded to 2 decimals).
WITH monthly AS (
    SELECT strftime('%Y-%m', o.order_date) AS month,
           SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0)) AS revenue
    FROM orders AS o
    JOIN order_items AS oi ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY month
)
SELECT month, ROUND(revenue, 2) AS revenue
FROM monthly
WHERE revenue > (SELECT AVG(revenue) FROM monthly);

-- Q2 [medium] Spend per customer (completed orders), then label each customer: 'vip' for $2,000 or more,
-- 'regular' for $500 up to $2,000, 'light' below $500. How many customers are in each segment?
-- Show segment, customers.
WITH spend AS (
    SELECT o.customer_id,
           SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0)) AS total_spend
    FROM orders AS o
    JOIN order_items AS oi ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY o.customer_id
),
labelled AS (
    SELECT customer_id,
           CASE WHEN total_spend >= 2000 THEN 'vip'
                WHEN total_spend >= 500  THEN 'regular'
                ELSE 'light' END AS segment
    FROM spend
)
SELECT segment, COUNT(*) AS customers
FROM labelled
GROUP BY segment;

-- Q3 [medium] The earlier question "orders whose total is above the average order total", now with CTEs.
-- Show order_id, order_total (rounded to 2 decimals). Biggest first, top 10.
WITH totals AS (
    SELECT order_id, SUM(quantity * unit_price * (1 - discount_pct / 100.0)) AS order_total
    FROM order_items
    GROUP BY order_id
)
SELECT order_id, ROUND(order_total, 2) AS order_total
FROM totals
WHERE order_total > (SELECT AVG(order_total) FROM totals)
ORDER BY order_total DESC
LIMIT 10;
-- Tip: compare this with the version in file 06. The CTE is defined once and used twice.

-- Q4 [medium] First and last order date per customer, and the number of days between them, for
-- customers with at least 2 orders. Show customer_id, first_order, last_order, span_days.
WITH bounds AS (
    SELECT customer_id, MIN(order_date) AS first_order, MAX(order_date) AS last_order, COUNT(*) AS n
    FROM orders
    GROUP BY customer_id
)
SELECT customer_id, first_order, last_order,
       CAST(julianday(last_order) - julianday(first_order) AS INTEGER) AS span_days
FROM bounds
WHERE n >= 2;

-- Q5 [medium] Repeat-purchase rate: of the customers who have placed any order, what percentage placed
-- 2 or more? One row: customers_with_orders, repeat_customers, repeat_pct (rounded to 1 decimal).
WITH per_customer AS (
    SELECT customer_id, COUNT(*) AS n FROM orders GROUP BY customer_id
)
SELECT COUNT(*) AS customers_with_orders,
       SUM(n >= 2) AS repeat_customers,
       ROUND(100.0 * SUM(n >= 2) / COUNT(*), 1) AS repeat_pct
FROM per_customer;

-- Q6 [medium] Products that sold before September 2026 but not a single time since 2026-09-01.
-- Show product_id, product_name.
WITH sold_before AS (
    SELECT DISTINCT oi.product_id
    FROM order_items AS oi JOIN orders AS o ON o.order_id = oi.order_id
    WHERE o.order_date < '2026-09-01'
),
sold_since AS (
    SELECT DISTINCT oi.product_id
    FROM order_items AS oi JOIN orders AS o ON o.order_id = oi.order_id
    WHERE o.order_date >= '2026-09-01'
)
SELECT p.product_id, p.product_name
FROM products AS p
WHERE p.product_id IN (SELECT product_id FROM sold_before)
  AND p.product_id NOT IN (SELECT product_id FROM sold_since);

-- Q7 [medium] Revenue by channel and category for completed orders, then show only the single best
-- category per channel. Show channel, category, revenue (rounded to 2 decimals).
-- (Window functions are the next topics, so use a CTE and a join to the per-channel maximum.)
WITH rev AS (
    SELECT o.channel, p.category,
           SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0)) AS revenue
    FROM orders AS o
    JOIN order_items AS oi ON oi.order_id = o.order_id
    JOIN products AS p ON p.product_id = oi.product_id
    WHERE o.status = 'completed'
    GROUP BY o.channel, p.category
),
best AS (
    SELECT channel, MAX(revenue) AS best_revenue FROM rev GROUP BY channel
)
SELECT r.channel, r.category, ROUND(r.revenue, 2) AS revenue
FROM rev AS r
JOIN best AS b ON b.channel = r.channel AND b.best_revenue = r.revenue;

-- Q8 [hard] Each month's revenue as a percentage of its year's total revenue (completed orders).
-- Show year, month ('YYYY-MM'), revenue (rounded to 2 decimals) and pct_of_year (rounded to 1 decimal).
WITH monthly AS (
    SELECT strftime('%Y', o.order_date) AS year,
           strftime('%Y-%m', o.order_date) AS month,
           SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0)) AS revenue
    FROM orders AS o
    JOIN order_items AS oi ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY year, month
),
yearly AS (
    SELECT year, SUM(revenue) AS year_revenue FROM monthly GROUP BY year
)
SELECT m.year, m.month, ROUND(m.revenue, 2) AS revenue,
       ROUND(100.0 * m.revenue / y.year_revenue, 1) AS pct_of_year
FROM monthly AS m
JOIN yearly  AS y ON y.year = m.year;

-- Q9 [hard] Customers whose most recent order was cancelled or returned.
-- Show customer_id, last_order_date, last_status. (No window functions yet: find each customer's last
-- order date in a CTE and join back. Assume no customer has two orders on the same date.)
WITH last_order AS (
    SELECT customer_id, MAX(order_date) AS last_order_date
    FROM orders
    GROUP BY customer_id
)
SELECT o.customer_id, o.order_date AS last_order_date, o.status AS last_status
FROM orders AS o
JOIN last_order AS l ON l.customer_id = o.customer_id AND l.last_order_date = o.order_date
WHERE o.status IN ('cancelled', 'returned');

-- Q10 [hard] Return rate by category: share of order lines that belong to returned orders.
-- Show category, lines, returned_lines, return_rate_pct (rounded to 1 decimal), highest rate first.
WITH lines AS (
    SELECT p.category, o.status
    FROM order_items AS oi
    JOIN orders   AS o ON o.order_id   = oi.order_id
    JOIN products AS p ON p.product_id = oi.product_id
)
SELECT category,
       COUNT(*) AS lines,
       SUM(status = 'returned') AS returned_lines,
       ROUND(100.0 * SUM(status = 'returned') / COUNT(*), 1) AS return_rate_pct
FROM lines
GROUP BY category
ORDER BY return_rate_pct DESC;
