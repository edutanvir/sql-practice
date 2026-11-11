-- 02 JOINs, part 1: INNER JOIN, LEFT JOIN, joining three tables, finding rows with no match
-- Day 2. Tables: orders, customers, order_items, products, employees, departments.
-- Revenue of a line = quantity * unit_price * (1 - discount_pct / 100.0).

-- Q1 [easy] Show order_id, order_date and the customer's full name (first and last name together as
-- customer_name) for the 15 oldest orders. Break ties by order_id.
SELECT o.order_id, o.order_date, c.first_name || ' ' || c.last_name AS customer_name
FROM orders AS o
JOIN customers AS c ON c.customer_id = o.customer_id
ORDER BY o.order_date, o.order_id
LIMIT 15;

-- Q2 [easy] For order 10024 list every item: product_name, quantity, unit_price.
SELECT p.product_name, oi.quantity, oi.unit_price
FROM order_items AS oi
JOIN products AS p ON p.product_id = oi.product_id
WHERE oi.order_id = 10024;

-- Q3 [easy] Every employee with their department name: first_name, last_name, department_name.
SELECT e.first_name, e.last_name, d.department_name
FROM employees AS e
JOIN departments AS d ON d.department_id = e.department_id;

-- Q4 [medium] Customers who have never placed an order. Show customer_id, first_name, last_name.
SELECT c.customer_id, c.first_name, c.last_name
FROM customers AS c
LEFT JOIN orders AS o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;
-- Tip: LEFT JOIN, then keep only the rows where the right side is NULL. This is called an anti-join.

-- Q5 [medium] Products that have never been sold. Show product_id, product_name, launch_date.
SELECT p.product_id, p.product_name, p.launch_date
FROM products AS p
LEFT JOIN order_items AS oi ON oi.product_id = p.product_id
WHERE oi.order_item_id IS NULL;

-- Q6 [medium] The number of orders per customer for the 10 customers with the most orders.
-- Show customer_id, order_count. Highest first; break ties by customer_id.
SELECT c.customer_id, COUNT(o.order_id) AS order_count
FROM customers AS c
JOIN orders AS o ON o.customer_id = c.customer_id
GROUP BY c.customer_id
ORDER BY order_count DESC, c.customer_id
LIMIT 10;

-- Q7 [medium] Total revenue of the completed orders of customers who live in Sudbury.
-- One column: sudbury_revenue (rounded to 2 decimals).
SELECT ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0)), 2) AS sudbury_revenue
FROM customers AS c
JOIN orders AS o ON o.customer_id = c.customer_id
JOIN order_items AS oi ON oi.order_id = o.order_id
WHERE c.city = 'Sudbury'
  AND o.status = 'completed';

-- Q8 [medium] Units sold per product category (all order statuses): category, units_sold.
-- Largest first.
SELECT p.category, SUM(oi.quantity) AS units_sold
FROM order_items AS oi
JOIN products AS p ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY units_sold DESC;

-- Q9 [medium] Every department with its headcount, including departments with no employees.
-- Show department_name, headcount. (Every department here has people, but write it so that an empty one
-- would show 0.)
SELECT d.department_name, COUNT(e.employee_id) AS headcount
FROM departments AS d
LEFT JOIN employees AS e ON e.department_id = d.department_id
GROUP BY d.department_id, d.department_name;
-- Tip: COUNT(e.employee_id) counts only matched rows. COUNT(*) would count the empty department as 1.

-- Q10 [hard] Why does joining orders to order_items before counting inflate counts? Show for the
-- customers with the most orders: customer_id, real_orders (COUNT DISTINCT order_id) and order_lines
-- (rows after the join). Top 5 by real_orders, then customer_id.
SELECT o.customer_id,
       COUNT(DISTINCT o.order_id) AS real_orders,
       COUNT(*)                   AS order_lines
FROM orders AS o
JOIN order_items AS oi ON oi.order_id = o.order_id
GROUP BY o.customer_id
ORDER BY real_orders DESC, o.customer_id
LIMIT 5;
-- Tip: a join that multiplies rows (one order, many items) makes COUNT(*) wrong. Count DISTINCT keys.
