-- 08 Window functions, part 1: ROW_NUMBER, RANK, DENSE_RANK, NTILE and "top N per group"
-- Day 8. Tables: employees, orders, order_items, products, customers.
-- Window functions need SQLite 3.25 or newer (the setup in README.md gives you that).

-- Q1 [easy] Number each customer's orders from oldest to newest and show the first one only:
-- customer_id, order_id, order_date for each customer's first order. (ROW_NUMBER, order by date then id.)
WITH numbered AS (
    SELECT customer_id, order_id, order_date,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date, order_id) AS rn
    FROM orders
)
SELECT customer_id, order_id, order_date
FROM numbered
WHERE rn = 1;

-- Q2 [easy] The latest order of each customer: customer_id, order_id, order_date, status.
WITH numbered AS (
    SELECT customer_id, order_id, order_date, status,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC, order_id DESC) AS rn
    FROM orders
)
SELECT customer_id, order_id, order_date, status
FROM numbered
WHERE rn = 1;

-- Q3 [medium] The three best-paid employees in each department. If people tie, include all of them
-- (use DENSE_RANK). Show department_id, first_name, last_name, salary, salary_rank.
WITH ranked AS (
    SELECT department_id, first_name, last_name, salary,
           DENSE_RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS salary_rank
    FROM employees
)
SELECT department_id, first_name, last_name, salary, salary_rank
FROM ranked
WHERE salary_rank <= 3;

-- Q4 [medium] The second highest salary in the whole company: one column, second_highest.
-- (Must still work if two people share the top salary.)
WITH ranked AS (
    SELECT salary, DENSE_RANK() OVER (ORDER BY salary DESC) AS r
    FROM employees
)
SELECT DISTINCT salary AS second_highest
FROM ranked
WHERE r = 2;
-- Tip: this is one of the most common interview questions. Know three ways: DENSE_RANK, OFFSET and a subquery.

-- Q5 [medium] The top 3 products by revenue (completed orders) inside each category.
-- Show category, product_name, revenue (rounded to 2 decimals), rank_in_category.
WITH rev AS (
    SELECT p.category, p.product_name,
           SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0)) AS revenue
    FROM order_items AS oi
    JOIN orders   AS o ON o.order_id   = oi.order_id
    JOIN products AS p ON p.product_id = oi.product_id
    WHERE o.status = 'completed'
    GROUP BY p.product_id, p.category, p.product_name
),
ranked AS (
    SELECT category, product_name, revenue,
           RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS rank_in_category
    FROM rev
)
SELECT category, product_name, ROUND(revenue, 2) AS revenue, rank_in_category
FROM ranked
WHERE rank_in_category <= 3;

-- Q6 [medium] The top-spending customer in each month (completed orders): month ('YYYY-MM'),
-- customer_id, spend (rounded to 2 decimals). If two customers tie, show both.
WITH monthly AS (
    SELECT strftime('%Y-%m', o.order_date) AS month, o.customer_id,
           SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0)) AS spend
    FROM orders AS o
    JOIN order_items AS oi ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY month, o.customer_id
),
ranked AS (
    SELECT month, customer_id, spend,
           RANK() OVER (PARTITION BY month ORDER BY spend DESC) AS r
    FROM monthly
)
SELECT month, customer_id, ROUND(spend, 2) AS spend
FROM ranked
WHERE r = 1;

-- Q7 [medium] Split customers who have orders into four equal groups by number of orders (NTILE),
-- group 1 = the most active. Show quartile, customers, min_orders, max_orders.
WITH per_customer AS (
    SELECT customer_id, COUNT(*) AS n FROM orders GROUP BY customer_id
),
grouped AS (
    SELECT customer_id, n, NTILE(4) OVER (ORDER BY n DESC, customer_id) AS quartile
    FROM per_customer
)
SELECT quartile, COUNT(*) AS customers, MIN(n) AS min_orders, MAX(n) AS max_orders
FROM grouped
GROUP BY quartile;
-- Tip: NTILE gives equal-sized groups, so customers with the same count can land in different groups.
-- Ordering by customer_id as well makes the result repeatable.

-- Q8 [hard] The most loyal customers per province: in each province, show the two customers with the most orders.
-- If there is a tie for second place, show everyone tied. Skip customers without a province.
-- Show province, customer_id, orders, rank_in_province.
WITH per_customer AS (
    SELECT c.province, c.customer_id, COUNT(*) AS orders
    FROM customers AS c
    JOIN orders AS o ON o.customer_id = c.customer_id
    WHERE c.province IS NOT NULL
    GROUP BY c.province, c.customer_id
),
ranked AS (
    SELECT province, customer_id, orders,
           RANK() OVER (PARTITION BY province ORDER BY orders DESC) AS rank_in_province
    FROM per_customer
)
SELECT province, customer_id, orders, rank_in_province
FROM ranked
WHERE rank_in_province <= 2;

-- Q9 [hard] For each customer, the product they bought most often (by units, all statuses). If there is a
-- tie, pick the product with the lower product_id. Show customer_id, product_id, units.
WITH per_product AS (
    SELECT o.customer_id, oi.product_id, SUM(oi.quantity) AS units
    FROM orders AS o
    JOIN order_items AS oi ON oi.order_id = o.order_id
    GROUP BY o.customer_id, oi.product_id
),
ranked AS (
    SELECT customer_id, product_id, units,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY units DESC, product_id) AS rn
    FROM per_product
)
SELECT customer_id, product_id, units
FROM ranked
WHERE rn = 1;

-- Q10 [explore] Show employees of department_id 3 with their salary and three columns side by side:
-- ROW_NUMBER(), RANK() and DENSE_RANK() all ordered by salary DESC. Look at what happens when two people
-- have the same salary. There is no single right answer to check, but you should be able to explain the
-- difference out loud: ROW_NUMBER never repeats, RANK repeats and then skips, DENSE_RANK repeats and
-- does not skip.
SELECT first_name, last_name, salary,
       ROW_NUMBER() OVER (ORDER BY salary DESC) AS row_num,
       RANK()       OVER (ORDER BY salary DESC) AS rnk,
       DENSE_RANK() OVER (ORDER BY salary DESC) AS dense_rnk
FROM employees
WHERE department_id = 3
ORDER BY salary DESC;
