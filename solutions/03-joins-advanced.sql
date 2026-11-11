-- 03 JOINs, part 2: self joins, anti-joins, EXISTS, CROSS JOIN, a FULL JOIN done portably
-- Day 3. Tables: employees, customers, orders, daily_logins, products.

-- Q1 [medium] Every employee with their manager's name. Show employee (first and last name together),
-- manager (the same for the manager, NULL for the CEO).
SELECT e.first_name || ' ' || e.last_name AS employee,
       m.first_name || ' ' || m.last_name AS manager
FROM employees AS e
LEFT JOIN employees AS m ON m.employee_id = e.manager_id;

-- Q2 [medium] Every manager (anyone with at least one direct report), with how many people report to
-- them and the average salary of those reports (rounded to 0 decimals).
-- Show manager (full name), direct_reports, avg_report_salary.
SELECT m.first_name || ' ' || m.last_name AS manager,
       COUNT(*)                           AS direct_reports,
       ROUND(AVG(e.salary), 0)            AS avg_report_salary
FROM employees AS e
JOIN employees AS m ON m.employee_id = e.manager_id
GROUP BY m.employee_id, m.first_name, m.last_name;
-- Tip: the same table joined to itself, with two different aliases: e is the employee, m is the manager.

-- Q3 [medium] Pairs of different customers from the same city who signed up on the same day.
-- Show city, signup_date, customer_id_a, customer_id_b with customer_id_a < customer_id_b.
SELECT a.city, a.signup_date, a.customer_id AS customer_id_a, b.customer_id AS customer_id_b
FROM customers AS a
JOIN customers AS b
  ON a.city = b.city
 AND a.signup_date = b.signup_date
 AND a.customer_id < b.customer_id;
-- Tip: "a.customer_id < b.customer_id" stops each pair appearing twice and a customer pairing with themselves.

-- Q4 [medium] Customers who placed orders, but none of them was completed.
-- Show customer_id.
SELECT DISTINCT o.customer_id
FROM orders AS o
WHERE NOT EXISTS (
    SELECT 1 FROM orders AS c
    WHERE c.customer_id = o.customer_id AND c.status = 'completed'
);

-- Q5 [medium] Customers who ordered in both 2025 and 2026. Show customer_id.
SELECT customer_id FROM orders WHERE order_date LIKE '2025-%'
INTERSECT
SELECT customer_id FROM orders WHERE order_date LIKE '2026-%';

-- Q6 [hard] Every sales channel crossed with every product category, with the number of order lines
-- sold (zero if none): channel, category, lines.
-- Use CROSS JOIN to build the grid first, then LEFT JOIN to count.
WITH grid AS (
    SELECT ch.channel, cat.category
    FROM (SELECT DISTINCT channel FROM orders) AS ch
    CROSS JOIN (SELECT DISTINCT category FROM products) AS cat
),
sold AS (
    SELECT o.channel, p.category, oi.order_item_id
    FROM order_items AS oi
    JOIN orders   AS o ON o.order_id   = oi.order_id
    JOIN products AS p ON p.product_id = oi.product_id
)
SELECT g.channel, g.category, COUNT(s.order_item_id) AS lines
FROM grid AS g
LEFT JOIN sold AS s ON s.channel = g.channel AND s.category = g.category
GROUP BY g.channel, g.category;
-- Tip: a grid with zeros is how you stop a report from silently dropping empty combinations.

-- Q7 [hard] A FULL OUTER JOIN done with LEFT JOIN + UNION: for every customer who either placed an order
-- or logged in, show customer_id, orders (count of orders, 0 if none), login_days (count of login days,
-- 0 if none).
WITH o AS (SELECT customer_id, COUNT(*) AS orders FROM orders GROUP BY customer_id),
     l AS (SELECT customer_id, COUNT(*) AS login_days FROM daily_logins GROUP BY customer_id),
     ids AS (SELECT customer_id FROM o UNION SELECT customer_id FROM l)
SELECT ids.customer_id, COALESCE(o.orders, 0) AS orders, COALESCE(l.login_days, 0) AS login_days
FROM ids
LEFT JOIN o ON o.customer_id = ids.customer_id
LEFT JOIN l ON l.customer_id = ids.customer_id;
-- Tip: newer SQLite (3.39+), SQL Server and Spark SQL support FULL OUTER JOIN directly. This pattern works everywhere.

-- Q8 [hard] Pairs of products bought together in the same order. Show the 5 most common pairs:
-- product_a, product_b (product names, with product_id_a < product_id_b), times_together.
-- Break ties by product names.
SELECT pa.product_name AS product_a, pb.product_name AS product_b, COUNT(*) AS times_together
FROM order_items AS a
JOIN order_items AS b ON a.order_id = b.order_id AND a.product_id < b.product_id
JOIN products AS pa ON pa.product_id = a.product_id
JOIN products AS pb ON pb.product_id = b.product_id
GROUP BY a.product_id, b.product_id
ORDER BY times_together DESC, product_a, product_b
LIMIT 5;
