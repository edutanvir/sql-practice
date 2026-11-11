-- 10 Duplicates and data-quality checks: the everyday work of a data engineer
-- Day 10. Tables: customers, orders, order_items, products, customer_address_history.
-- The customers table has duplicates on purpose: the same person signed up twice and the emails differ
-- only by capital letters or stray spaces. Real data looks like this.

-- Q1 [easy] How many customers have no city, and what percentage of all customers is that?
-- One row: missing_city, total_customers, missing_pct (rounded to 1 decimal).
SELECT SUM(city IS NULL) AS missing_city,
       COUNT(*) AS total_customers,
       ROUND(100.0 * SUM(city IS NULL) / COUNT(*), 1) AS missing_pct
FROM customers;
-- Tip: COUNT(city) skips NULLs, COUNT(*) does not. COUNT(*) - COUNT(city) is another way to get the same number.

-- Q2 [medium] Which e-mail addresses appear more than once once you ignore capital letters and spaces?
-- Show clean_email and how many customers have it. Alphabetical order.
SELECT LOWER(TRIM(email)) AS clean_email, COUNT(*) AS customers
FROM customers
GROUP BY LOWER(TRIM(email))
HAVING COUNT(*) > 1
ORDER BY clean_email;

-- Q3 [medium] For every duplicated e-mail show all the customer ids on one line, lowest id first.
-- Show clean_email, customer_ids (like '1054,1611').
WITH ordered AS (
    SELECT LOWER(TRIM(email)) AS clean_email, customer_id
    FROM customers
    ORDER BY customer_id
)
SELECT clean_email, GROUP_CONCAT(customer_id) AS customer_ids
FROM ordered
GROUP BY clean_email
HAVING COUNT(*) > 1;
-- Tip: GROUP_CONCAT in SQLite, STRING_AGG in SQL Server, collect_list + concat_ws in Spark SQL.

-- Q4 [medium] Which customer rows would you delete to keep one row per clean e-mail?
-- Keep the row with the lowest customer_id. Show the customer_id of every row to delete.
WITH numbered AS (
    SELECT customer_id,
           ROW_NUMBER() OVER (PARTITION BY LOWER(TRIM(email)) ORDER BY customer_id) AS rn
    FROM customers
)
SELECT customer_id
FROM numbered
WHERE rn > 1;
-- Tip: ROW_NUMBER() OVER (PARTITION BY the-duplicate-key ORDER BY the-row-to-keep) is the standard
-- de-duplication pattern in SQL and Spark. Keep rn = 1, delete rn > 1.

-- Q5 [medium] The same de-duplication, but show the survivor too: for each duplicate row show
-- duplicate_id and keep_id (the lowest id with the same clean e-mail).
WITH numbered AS (
    SELECT customer_id, LOWER(TRIM(email)) AS clean_email,
           ROW_NUMBER() OVER (PARTITION BY LOWER(TRIM(email)) ORDER BY customer_id) AS rn
    FROM customers
)
SELECT d.customer_id AS duplicate_id, k.customer_id AS keep_id
FROM numbered AS d
JOIN numbered AS k ON k.clean_email = d.clean_email AND k.rn = 1
WHERE d.rn > 1;

-- Q6 [medium] Count the real number of distinct people (distinct clean e-mails), the number of customer
-- rows and how many extra rows are duplicates: distinct_people, customer_rows, duplicate_rows.
SELECT COUNT(DISTINCT LOWER(TRIM(email))) AS distinct_people,
       COUNT(*) AS customer_rows,
       COUNT(*) - COUNT(DISTINCT LOWER(TRIM(email))) AS duplicate_rows
FROM customers;

-- Q7 [medium] Integrity check: order lines that reference a product that does not exist, or an order that
-- does not exist. Return the order_item_id of any bad rows. (The clean dataset should return no rows.
-- Learn the pattern, you will use it on real pipelines.)
SELECT oi.order_item_id
FROM order_items AS oi
LEFT JOIN products AS p ON p.product_id = oi.product_id
LEFT JOIN orders   AS o ON o.order_id   = oi.order_id
WHERE p.product_id IS NULL OR o.order_id IS NULL;

-- Q8 [medium] Business rule check: orders placed before the customer's signup date, or items sold before the
-- product's launch date or after its discontinued date. Return order_id for any broken order.
-- (Expect no rows here as well.)
SELECT o.order_id
FROM orders AS o
JOIN customers AS c ON c.customer_id = o.customer_id
WHERE o.order_date < c.signup_date
UNION
SELECT o.order_id
FROM orders AS o
JOIN order_items AS oi ON oi.order_id = o.order_id
JOIN products AS p ON p.product_id = oi.product_id
WHERE o.order_date < p.launch_date
   OR (p.discontinued_date IS NOT NULL AND o.order_date > p.discontinued_date);

-- Q9 [hard] Customers who have no current address row in customer_address_history, split into customers who
-- have placed an order and those who have not. Show has_orders ('yes' or 'no') and customers.
SELECT CASE WHEN EXISTS (SELECT 1 FROM orders AS o WHERE o.customer_id = c.customer_id)
            THEN 'yes' ELSE 'no' END AS has_orders,
       COUNT(*) AS customers
FROM customers AS c
WHERE NOT EXISTS (
    SELECT 1 FROM customer_address_history AS h
    WHERE h.customer_id = c.customer_id AND h.is_current = 1
)
GROUP BY has_orders;

-- Q10 [hard] Orders per real person: after merging duplicate customers into the lowest customer_id with the
-- same clean e-mail, who are the 5 people with the most orders? Show keep_id, orders.
-- Ties by keep_id.
WITH numbered AS (
    SELECT customer_id, LOWER(TRIM(email)) AS clean_email,
           ROW_NUMBER() OVER (PARTITION BY LOWER(TRIM(email)) ORDER BY customer_id) AS rn
    FROM customers
),
mapping AS (
    SELECT d.customer_id, k.customer_id AS keep_id
    FROM numbered AS d
    JOIN numbered AS k ON k.clean_email = d.clean_email AND k.rn = 1
)
SELECT m.keep_id, COUNT(*) AS orders
FROM orders AS o
JOIN mapping AS m ON m.customer_id = o.customer_id
GROUP BY m.keep_id
ORDER BY orders DESC, m.keep_id
LIMIT 5;
