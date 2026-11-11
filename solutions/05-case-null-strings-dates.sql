-- 05 CASE, NULL handling, string and date functions
-- Day 5. Tables: customers, orders, order_items, products, employees.
-- SQLite date functions: strftime, date, julianday. SQL Server uses DATEDIFF/DATEADD/FORMAT,
-- Spark SQL uses datediff/date_add/date_format. The ideas are the same.

-- Q1 [easy] Label each product by price: 'budget' under $40, 'mid' from $40 to under $150,
-- 'premium' from $150. Show product_name, list_price, price_band.
SELECT product_name, list_price,
       CASE WHEN list_price < 40  THEN 'budget'
            WHEN list_price < 150 THEN 'mid'
            ELSE 'premium' END AS price_band
FROM products;

-- Q2 [easy] Show every customer's city, but write 'Unknown' when it is missing.
-- Show customer_id, city_clean.
SELECT customer_id, COALESCE(city, 'Unknown') AS city_clean
FROM customers;

-- Q3 [easy] Show each order's coupon, using 'NO COUPON' when there was none: order_id, coupon.
-- Only orders from October 2026.
SELECT order_id, COALESCE(coupon_code, 'NO COUPON') AS coupon
FROM orders
WHERE order_date >= '2026-10-01' AND order_date < '2026-11-01';

-- Q4 [medium] Count the orders by whether a coupon was used: coupon_used ('yes' or 'no') and orders.
SELECT CASE WHEN coupon_code IS NULL THEN 'no' ELSE 'yes' END AS coupon_used,
       COUNT(*) AS orders
FROM orders
GROUP BY coupon_used;

-- Q5 [medium] Email domain of each customer (the text after the @), in lower case. Some emails have
-- stray spaces or capital letters, so clean them first.
-- Show the distinct domains with how many customers use each: domain, customers. Most common first,
-- ties by domain.
WITH clean AS (SELECT LOWER(TRIM(email)) AS email FROM customers)
SELECT SUBSTR(email, INSTR(email, '@') + 1) AS domain, COUNT(*) AS customers
FROM clean
GROUP BY domain
ORDER BY customers DESC, domain;

-- Q6 [easy] Full name in the form 'LAST, First' for the employees of department_id 2.
-- Show employee_id, display_name.
SELECT employee_id, UPPER(last_name) || ', ' || first_name AS display_name
FROM employees
WHERE department_id = 2;

-- Q7 [medium] How many days after signing up did each customer place their first order?
-- Customers who never ordered must not appear. Show customer_id, days_to_first_order.
-- (Use julianday to subtract two dates.)
SELECT c.customer_id,
       CAST(julianday(MIN(o.order_date)) - julianday(c.signup_date) AS INTEGER) AS days_to_first_order
FROM customers AS c
JOIN orders AS o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.signup_date;

-- Q8 [medium] Orders per weekday. Show weekday_number (0 = Sunday ... 6 = Saturday) and orders, in
-- weekday order.
SELECT CAST(strftime('%w', order_date) AS INTEGER) AS weekday_number, COUNT(*) AS orders
FROM orders
GROUP BY weekday_number
ORDER BY weekday_number;

-- Q9 [medium] Orders per quarter of the year: year, quarter (1 to 4), orders.
SELECT CAST(strftime('%Y', order_date) AS INTEGER) AS year,
       (CAST(strftime('%m', order_date) AS INTEGER) + 2) / 3 AS quarter,
       COUNT(*) AS orders
FROM orders
GROUP BY year, quarter
ORDER BY year, quarter;
-- Tip: integer division in SQLite: (month + 2) / 3 gives the quarter. Spark SQL has quarter(date).

-- Q10 [medium] Orders from the last 30 days of the data. Treat 2026-10-31 as "today".
-- Show how many orders and how many distinct customers: orders_30d, customers_30d.
SELECT COUNT(*) AS orders_30d, COUNT(DISTINCT customer_id) AS customers_30d
FROM orders
WHERE order_date >= date('2026-10-31', '-30 days');
-- Tip: in SQL Server this is DATEADD(day, -30, '2026-10-31'), in Spark SQL date_sub('2026-10-31', 30).

-- Q11 [medium] Use NULLIF to avoid dividing by zero: for each product category show the number of items
-- sold and the average units per order line (units / lines, rounded to 2 decimals), but return NULL
-- instead of failing for a category with no sales.
-- Start from products so that every category appears: category, lines, avg_units_per_line.
SELECT p.category,
       COUNT(oi.order_item_id) AS lines,
       ROUND(1.0 * SUM(oi.quantity) / NULLIF(COUNT(oi.order_item_id), 0), 2) AS avg_units_per_line
FROM products AS p
LEFT JOIN order_items AS oi ON oi.product_id = p.product_id
GROUP BY p.category;

-- Q12 [hard] Customer tenure bands. For customers who have signed up, show how many belong to each band
-- by days since signup as of 2026-10-31: 'under 90 days', '90-364 days', '1 year +'.
-- Show tenure_band, customers.
SELECT CASE
         WHEN julianday('2026-10-31') - julianday(signup_date) < 90  THEN 'under 90 days'
         WHEN julianday('2026-10-31') - julianday(signup_date) < 365 THEN '90-364 days'
         ELSE '1 year +'
       END AS tenure_band,
       COUNT(*) AS customers
FROM customers
GROUP BY tenure_band;
