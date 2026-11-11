-- 01 SELECT and filtering: WHERE, BETWEEN, IN, LIKE, IS NULL, ORDER BY, LIMIT
-- Day 1. Tables: customers, products, orders, employees.



-- Q1 [easy] List the first name, last name and email of every customer who lives in Sudbury.
SELECT 
    first_name,
    last_name,
    email
FROM customers
WHERE city = 'Sudbury';

-- Q2 [easy] Show products priced from $50 to $100 (inclusive): product_name, category, list_price.
-- Cheapest first.


-- Q3 [easy] Which orders were placed in March 2026 using a coupon?
-- Show order_id, order_date, coupon_code.


-- Q4 [easy] List the customers who have no city recorded: customer_id, first_name, last_name.


-- Q5 [easy] List the distinct acquisition channels, in alphabetical order.


-- Q6 [easy] Show the 10 most expensive products: product_name, category, list_price.


-- Q7 [medium] Customers whose last name starts with 'M' and who live in Ontario (ON) or Quebec (QC).
-- Show first_name, last_name, city, province.


-- Q8 [medium] Web orders in 2026 that were cancelled or returned, newest first.
-- Show order_id, order_date, status.


-- Q9 [easy] Employees hired in 2024 or later who earn more than $90,000.
-- Show first_name, last_name, hire_date, salary. Highest salary first.


-- Q10 [medium] How many products have 'Boots' in the name, and what is their average list price?
-- One row with two columns: boot_count and avg_price (rounded to 2 decimals).


-- Q11 [medium] Customers who signed up in 2026 from the 'referral' or 'social' channel and whose city
-- is not Toronto. Show customer_id, city. (Watch out for customers with no city.)


-- Q12 [easy] Which employee has no manager? Show first_name, last_name, job_title.


