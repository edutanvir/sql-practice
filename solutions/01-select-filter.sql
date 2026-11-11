-- 01 SELECT and filtering: WHERE, BETWEEN, IN, LIKE, IS NULL, ORDER BY, LIMIT
-- Day 1. Tables: customers, products, orders, employees.

-- Q1 [easy] List the first name, last name and email of every customer who lives in Sudbury.
SELECT first_name, last_name, email
FROM customers
WHERE city = 'Sudbury';

-- Q2 [easy] Show products priced from $50 to $100 (inclusive): product_name, category, list_price.
-- Cheapest first.
SELECT product_name, category, list_price
FROM products
WHERE list_price BETWEEN 50 AND 100
ORDER BY list_price;

-- Q3 [easy] Which orders were placed in March 2026 using a coupon?
-- Show order_id, order_date, coupon_code.
SELECT order_id, order_date, coupon_code
FROM orders
WHERE order_date BETWEEN '2026-03-01' AND '2026-03-31'
  AND coupon_code IS NOT NULL;
-- Tip: dates are text in 'YYYY-MM-DD' form, so BETWEEN and comparisons sort correctly.

-- Q4 [easy] List the customers who have no city recorded: customer_id, first_name, last_name.
SELECT customer_id, first_name, last_name
FROM customers
WHERE city IS NULL;
-- Tip: "city = NULL" never matches anything. Use IS NULL.

-- Q5 [easy] List the distinct acquisition channels, in alphabetical order.
SELECT DISTINCT acquisition_channel
FROM customers
ORDER BY acquisition_channel;

-- Q6 [easy] Show the 10 most expensive products: product_name, category, list_price.
SELECT product_name, category, list_price
FROM products
ORDER BY list_price DESC
LIMIT 10;
-- Tip: SQL Server writes this as SELECT TOP 10 ...; Spark SQL uses LIMIT like SQLite.

-- Q7 [medium] Customers whose last name starts with 'M' and who live in Ontario (ON) or Quebec (QC).
-- Show first_name, last_name, city, province.
SELECT first_name, last_name, city, province
FROM customers
WHERE last_name LIKE 'M%'
  AND province IN ('ON', 'QC');

-- Q8 [medium] Web orders in 2026 that were cancelled or returned, newest first.
-- Show order_id, order_date, status.
SELECT order_id, order_date, status
FROM orders
WHERE channel = 'web'
  AND order_date >= '2026-01-01'
  AND status IN ('cancelled', 'returned')
ORDER BY order_date DESC, order_id DESC;

-- Q9 [easy] Employees hired in 2024 or later who earn more than $90,000.
-- Show first_name, last_name, hire_date, salary. Highest salary first.
SELECT first_name, last_name, hire_date, salary
FROM employees
WHERE hire_date >= '2024-01-01'
  AND salary > 90000
ORDER BY salary DESC;

-- Q10 [medium] How many products have 'Boots' in the name, and what is their average list price?
-- One row with two columns: boot_count and avg_price (rounded to 2 decimals).
SELECT COUNT(*) AS boot_count, ROUND(AVG(list_price), 2) AS avg_price
FROM products
WHERE product_name LIKE '%Boots%';

-- Q11 [medium] Customers who signed up in 2026 from the 'referral' or 'social' channel and whose city
-- is not Toronto. Show customer_id, city. (Watch out for customers with no city.)
SELECT customer_id, city
FROM customers
WHERE signup_date >= '2026-01-01'
  AND acquisition_channel IN ('referral', 'social')
  AND (city IS NULL OR city <> 'Toronto');
-- Tip: "city <> 'Toronto'" alone drops the NULL cities, because NULL <> 'Toronto' is unknown, not true.

-- Q12 [easy] Which employee has no manager? Show first_name, last_name, job_title.
SELECT first_name, last_name, job_title
FROM employees
WHERE manager_id IS NULL;
