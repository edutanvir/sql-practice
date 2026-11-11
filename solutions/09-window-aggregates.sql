-- 09 Window functions, part 2: running totals, LAG / LEAD, moving averages, FIRST_VALUE
-- Day 9. Tables: orders, order_items, customers.
-- Revenue of a line = quantity * unit_price * (1 - discount_pct / 100.0).

-- Q1 [easy] Monthly number of orders and the running (cumulative) total of orders.
-- Show month ('YYYY-MM'), orders, running_orders, in month order.
WITH monthly AS (
    SELECT strftime('%Y-%m', order_date) AS month, COUNT(*) AS orders
    FROM orders
    GROUP BY month
)
SELECT month, orders,
       SUM(orders) OVER (ORDER BY month) AS running_orders
FROM monthly
ORDER BY month;

-- Q2 [medium] Monthly completed revenue with its running total. Show month, revenue, running_revenue
-- (both rounded to 2 decimals).
WITH monthly AS (
    SELECT strftime('%Y-%m', o.order_date) AS month,
           SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0)) AS revenue
    FROM orders AS o
    JOIN order_items AS oi ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY month
)
SELECT month, ROUND(revenue, 2) AS revenue,
       ROUND(SUM(revenue) OVER (ORDER BY month), 2) AS running_revenue
FROM monthly
ORDER BY month;

-- Q3 [medium] Month-over-month growth in the number of orders.
-- Show month, orders, prev_orders and growth_pct (rounded to 1 decimal; NULL for the first month).
WITH monthly AS (
    SELECT strftime('%Y-%m', order_date) AS month, COUNT(*) AS orders
    FROM orders
    GROUP BY month
),
with_prev AS (
    SELECT month, orders, LAG(orders) OVER (ORDER BY month) AS prev_orders
    FROM monthly
)
SELECT month, orders, prev_orders,
       ROUND(100.0 * (orders - prev_orders) / prev_orders, 1) AS growth_pct
FROM with_prev
ORDER BY month;
-- Tip: LAG(col) looks one row back, LEAD(col) one row ahead. The first row has no previous row, so NULL.

-- Q4 [medium] Days since each customer's previous order. Show customer_id, order_id, order_date and
-- days_since_prev (NULL for a customer's first order) for customers 1029 and 1036 only.
WITH gaps AS (
    SELECT customer_id, order_id, order_date,
           CAST(julianday(order_date)
                - julianday(LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date, order_id))
                AS INTEGER) AS days_since_prev
    FROM orders
)
SELECT customer_id, order_id, order_date, days_since_prev
FROM gaps
WHERE customer_id IN (1029, 1036);
-- Tip: filter AFTER the window function runs (in the outer query), otherwise the window only sees the
-- rows that passed the filter.

-- Q5 [medium] Average days between orders per customer, for customers with at least 3 orders.
-- Show customer_id, orders, avg_gap_days (rounded to 1 decimal). Smallest gap first, top 10,
-- ties by customer_id.
WITH gaps AS (
    SELECT customer_id,
           julianday(order_date)
             - julianday(LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date, order_id)) AS gap
    FROM orders
)
SELECT customer_id, COUNT(*) AS orders, ROUND(AVG(gap), 1) AS avg_gap_days
FROM gaps
GROUP BY customer_id
HAVING COUNT(*) >= 3
ORDER BY avg_gap_days, customer_id
LIMIT 10;

-- Q6 [medium] A 3-month moving average of the number of orders (the current month and the two before).
-- Show month, orders and moving_avg_3m (rounded to 1 decimal). The first two months use the months
-- they have.
WITH monthly AS (
    SELECT strftime('%Y-%m', order_date) AS month, COUNT(*) AS orders
    FROM orders
    GROUP BY month
)
SELECT month, orders,
       ROUND(AVG(orders) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 1) AS moving_avg_3m
FROM monthly
ORDER BY month;

-- Q7 [medium] Cumulative number of customers signed up by month. Show month ('YYYY-MM') of signup,
-- new_customers, total_customers (running total), in month order.
WITH monthly AS (
    SELECT strftime('%Y-%m', signup_date) AS month, COUNT(*) AS new_customers
    FROM customers
    GROUP BY month
)
SELECT month, new_customers,
       SUM(new_customers) OVER (ORDER BY month) AS total_customers
FROM monthly
ORDER BY month;

-- Q8 [medium] Which channel did each customer use for their very first order?
-- Show channel, customers (how many customers started on that channel). Use FIRST_VALUE.
WITH firsts AS (
    SELECT DISTINCT customer_id,
           FIRST_VALUE(channel) OVER (PARTITION BY customer_id ORDER BY order_date, order_id) AS first_channel
    FROM orders
)
SELECT first_channel AS channel, COUNT(*) AS customers
FROM firsts
GROUP BY first_channel;

-- Q9 [hard] Each customer's cumulative spend (completed orders). Find the order on which each customer
-- first passed $1,000 of total spend. Show customer_id, order_id, order_date, cumulative_spend
-- (rounded to 2 decimals). Customers who never passed $1,000 do not appear.
WITH order_totals AS (
    SELECT o.customer_id, o.order_id, o.order_date,
           SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0)) AS order_total
    FROM orders AS o
    JOIN order_items AS oi ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY o.customer_id, o.order_id, o.order_date
),
running AS (
    SELECT customer_id, order_id, order_date,
           SUM(order_total) OVER (PARTITION BY customer_id ORDER BY order_date, order_id) AS cumulative_spend
    FROM order_totals
),
flagged AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date, order_id) AS rn
    FROM running
    WHERE cumulative_spend >= 1000
)
SELECT customer_id, order_id, order_date, ROUND(cumulative_spend, 2) AS cumulative_spend
FROM flagged
WHERE rn = 1;

-- Q10 [hard] Year over year: compare each month of 2026 with the same month of 2025 (completed revenue).
-- Show month ('MM'), revenue_2026, revenue_2025, diff (revenue_2026 - revenue_2025), all rounded to
-- 2 decimals, for months 01 to 10.
WITH monthly AS (
    SELECT strftime('%Y', o.order_date) AS year,
           strftime('%m', o.order_date) AS month,
           SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0)) AS revenue
    FROM orders AS o
    JOIN order_items AS oi ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY year, month
)
SELECT a.month,
       ROUND(a.revenue, 2) AS revenue_2026,
       ROUND(b.revenue, 2) AS revenue_2025,
       ROUND(a.revenue - b.revenue, 2) AS diff
FROM monthly AS a
JOIN monthly AS b ON b.month = a.month AND b.year = '2025'
WHERE a.year = '2026' AND a.month <= '10';
-- Tip: a self-join on the month number is one way to compare year over year. LAG(revenue, 12) over
-- a continuous month list is another.
