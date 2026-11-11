-- 11 Dates, cohorts and retention: the analytics questions interviewers love
-- Day 11. Tables: customers, orders.
-- "Today" for this dataset is 2026-10-31 (the data stops on 2026-10-30).

-- Q1 [medium] Signup cohorts: for each signup month show how many customers signed up and how many of them
-- placed at least one order. Show signup_month ('YYYY-MM'), signups, customers_who_ordered, order_rate_pct
-- (rounded to 1 decimal).
SELECT strftime('%Y-%m', c.signup_date) AS signup_month,
       COUNT(*) AS signups,
       SUM(EXISTS (SELECT 1 FROM orders AS o WHERE o.customer_id = c.customer_id)) AS customers_who_ordered,
       ROUND(100.0 * SUM(EXISTS (SELECT 1 FROM orders AS o WHERE o.customer_id = c.customer_id)) / COUNT(*), 1) AS order_rate_pct
FROM customers AS c
GROUP BY signup_month
ORDER BY signup_month;

-- Q2 [medium] New versus returning customers per month. A customer is "new" in the month of their first
-- order and "returning" in later months. Show month, new_customers, returning_customers
-- (count of distinct customers who ordered that month).
WITH first_order AS (
    SELECT customer_id, strftime('%Y-%m', MIN(order_date)) AS first_month
    FROM orders
    GROUP BY customer_id
),
active AS (
    SELECT DISTINCT customer_id, strftime('%Y-%m', order_date) AS month
    FROM orders
)
SELECT a.month,
       SUM(a.month = f.first_month) AS new_customers,
       SUM(a.month > f.first_month) AS returning_customers
FROM active AS a
JOIN first_order AS f ON f.customer_id = a.customer_id
GROUP BY a.month
ORDER BY a.month;

-- Q3 [medium] Retention by month: of the customers who ordered in a month, how many also ordered in the next
-- calendar month? Show month, customers, retained_next_month, retention_pct (rounded to 1 decimal).
-- Only months from 2025-01 to 2026-09 (the last month has no "next" month yet).
WITH active AS (
    SELECT DISTINCT customer_id, strftime('%Y-%m', order_date) AS month
    FROM orders
)
SELECT a.month,
       COUNT(*) AS customers,
       COUNT(n.customer_id) AS retained_next_month,
       ROUND(100.0 * COUNT(n.customer_id) / COUNT(*), 1) AS retention_pct
FROM active AS a
LEFT JOIN active AS n
       ON n.customer_id = a.customer_id
      AND n.month = strftime('%Y-%m', date(a.month || '-01', '+1 month'))
WHERE a.month <= '2026-09'
GROUP BY a.month
ORDER BY a.month;
-- Tip: date('2026-03-01', '+1 month') is how SQLite adds a month. Spark SQL: add_months(date, 1).

-- Q4 [hard] Cohort table: for each first-order month (the cohort), how many customers were active in the
-- same month (month 0) and 1, 2 and 3 months later? Show cohort ('YYYY-MM'), m0, m1, m2, m3 for cohorts
-- from 2025-01 to 2026-06.
WITH first_order AS (
    SELECT customer_id, strftime('%Y-%m', MIN(order_date)) AS cohort
    FROM orders
    GROUP BY customer_id
),
active AS (
    SELECT DISTINCT customer_id, strftime('%Y-%m', order_date) AS month
    FROM orders
),
offsets AS (
    SELECT f.cohort,
           (CAST(substr(a.month, 1, 4) AS INTEGER) - CAST(substr(f.cohort, 1, 4) AS INTEGER)) * 12
           + CAST(substr(a.month, 6, 2) AS INTEGER) - CAST(substr(f.cohort, 6, 2) AS INTEGER) AS month_offset,
           a.customer_id
    FROM first_order AS f
    JOIN active AS a ON a.customer_id = f.customer_id
)
SELECT cohort,
       SUM(month_offset = 0) AS m0,
       SUM(month_offset = 1) AS m1,
       SUM(month_offset = 2) AS m2,
       SUM(month_offset = 3) AS m3
FROM offsets
WHERE cohort <= '2026-06'
GROUP BY cohort
ORDER BY cohort;
-- Tip: this "conditional aggregation" turns rows into columns, the SQLite / Spark / T-SQL alternative to PIVOT.

-- Q5 [medium] Average days between first and second order, by acquisition channel, for customers with at
-- least two orders. Show acquisition_channel, customers, avg_days_to_second_order (rounded to 1 decimal).
WITH ranked AS (
    SELECT customer_id, order_date,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date, order_id) AS rn
    FROM orders
),
pairs AS (
    SELECT a.customer_id, julianday(b.order_date) - julianday(a.order_date) AS days
    FROM ranked AS a
    JOIN ranked AS b ON b.customer_id = a.customer_id AND a.rn = 1 AND b.rn = 2
)
SELECT c.acquisition_channel, COUNT(*) AS customers, ROUND(AVG(p.days), 1) AS avg_days_to_second_order
FROM pairs AS p
JOIN customers AS c ON c.customer_id = p.customer_id
GROUP BY c.acquisition_channel;

-- Q6 [medium] Lapsed customers: customers whose last order was more than 90 days before 2026-10-31.
-- How many per acquisition channel? Show acquisition_channel, lapsed_customers.
WITH last_order AS (
    SELECT customer_id, MAX(order_date) AS last_date FROM orders GROUP BY customer_id
)
SELECT c.acquisition_channel, COUNT(*) AS lapsed_customers
FROM last_order AS l
JOIN customers AS c ON c.customer_id = l.customer_id
WHERE l.last_date < date('2026-10-31', '-90 days')
GROUP BY c.acquisition_channel;

-- Q7 [medium] Weekly orders. Show the week (strftime('%Y-W%W')) and number of orders for the 5 busiest weeks.
-- Break ties by week.
SELECT strftime('%Y-W%W', order_date) AS week, COUNT(*) AS orders
FROM orders
GROUP BY week
ORDER BY orders DESC, week
LIMIT 5;

-- Q8 [hard] Year over year by month, side by side: for January to October show the number of orders in 2025
-- and in 2026 and the growth between them. Show month ('01' to '10'), orders_2025, orders_2026,
-- growth_pct (rounded to 1 decimal).
SELECT strftime('%m', order_date) AS month,
       SUM(strftime('%Y', order_date) = '2025') AS orders_2025,
       SUM(strftime('%Y', order_date) = '2026') AS orders_2026,
       ROUND(100.0 * (SUM(strftime('%Y', order_date) = '2026') - SUM(strftime('%Y', order_date) = '2025'))
             / SUM(strftime('%Y', order_date) = '2025'), 1) AS growth_pct
FROM orders
WHERE strftime('%m', order_date) <= '10'
GROUP BY month
ORDER BY month;
-- Tip: SUM(condition) per column is "conditional aggregation". It is how you pivot without PIVOT.

-- Q9 [hard] Customers who ordered in three different months in a row at some point. Show customer_id.
-- (A customer must have orders in months M, M+1 and M+2.)
WITH active AS (
    SELECT DISTINCT customer_id, strftime('%Y-%m', order_date) AS month
    FROM orders
)
SELECT DISTINCT a.customer_id
FROM active AS a
JOIN active AS b ON b.customer_id = a.customer_id
                AND b.month = strftime('%Y-%m', date(a.month || '-01', '+1 month'))
JOIN active AS c ON c.customer_id = a.customer_id
                AND c.month = strftime('%Y-%m', date(a.month || '-01', '+2 month'));
