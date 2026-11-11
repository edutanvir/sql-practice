-- 06 Subqueries: scalar, IN / NOT IN, EXISTS, correlated, derived tables
-- Day 6. Tables: employees, products, orders, order_items, customers.

-- Q1 [easy] Products priced above the average list price: product_name, list_price.
SELECT product_name, list_price
FROM products
WHERE list_price > (SELECT AVG(list_price) FROM products);

-- Q2 [easy] Employees who earn more than the average salary of the whole company:
-- first_name, last_name, salary.
SELECT first_name, last_name, salary
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);

-- Q3 [medium] Customers who bought a product from the 'Camping' category at least once:
-- customer_id. Each customer once. Use IN with a subquery.
SELECT DISTINCT customer_id
FROM orders
WHERE order_id IN (
    SELECT oi.order_id
    FROM order_items AS oi
    JOIN products AS p ON p.product_id = oi.product_id
    WHERE p.category = 'Camping'
);

-- Q4 [medium] Customers who have orders but never bought anything from 'Footwear'.
-- Show customer_id. Use NOT EXISTS.
SELECT DISTINCT o.customer_id
FROM orders AS o
WHERE NOT EXISTS (
    SELECT 1
    FROM orders AS o2
    JOIN order_items AS oi ON oi.order_id = o2.order_id
    JOIN products    AS p  ON p.product_id = oi.product_id
    WHERE o2.customer_id = o.customer_id
      AND p.category = 'Footwear'
);
-- Tip: NOT IN breaks when the subquery returns a NULL (the whole result becomes empty).
-- NOT EXISTS is the safe pattern.

-- Q5 [medium] Employees who earn more than the average of their own department.
-- Show first_name, last_name, department_id, salary. (Correlated subquery.)
SELECT e.first_name, e.last_name, e.department_id, e.salary
FROM employees AS e
WHERE e.salary > (
    SELECT AVG(e2.salary) FROM employees AS e2 WHERE e2.department_id = e.department_id
);

-- Q6 [medium] Each customer's biggest order by revenue. Use a derived table.
-- Show customer_id, biggest_order_revenue (rounded to 2 decimals) for customers whose biggest order is
-- over 1000.
SELECT customer_id, ROUND(MAX(order_revenue), 2) AS biggest_order_revenue
FROM (
    SELECT o.customer_id, o.order_id,
           SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100.0)) AS order_revenue
    FROM orders AS o
    JOIN order_items AS oi ON oi.order_id = o.order_id
    GROUP BY o.customer_id, o.order_id
) AS t
GROUP BY customer_id
HAVING MAX(order_revenue) > 1000;

-- Q7 [medium] The product with the highest list price in each category: category, product_name,
-- list_price. If two products tie, show both.
SELECT p.category, p.product_name, p.list_price
FROM products AS p
WHERE p.list_price = (
    SELECT MAX(p2.list_price) FROM products AS p2 WHERE p2.category = p.category
);

-- Q8 [medium] Customers whose number of orders is above the average number of orders per customer
-- (average over customers who ordered). Show customer_id, orders.
SELECT customer_id, COUNT(*) AS orders
FROM orders
GROUP BY customer_id
HAVING COUNT(*) > (
    SELECT AVG(n) FROM (SELECT COUNT(*) AS n FROM orders GROUP BY customer_id)
);

-- Q9 [hard] Each product's share of its category's units sold (all statuses), rounded to 1 decimal:
-- category, product_name, units, pct_of_category. Only products that sold at least 100 units.
SELECT p.category, p.product_name, SUM(oi.quantity) AS units,
       ROUND(100.0 * SUM(oi.quantity) / (
           SELECT SUM(oi2.quantity)
           FROM order_items AS oi2
           JOIN products AS p2 ON p2.product_id = oi2.product_id
           WHERE p2.category = p.category
       ), 1) AS pct_of_category
FROM order_items AS oi
JOIN products AS p ON p.product_id = oi.product_id
GROUP BY p.product_id, p.category, p.product_name
HAVING SUM(oi.quantity) >= 100;

-- Q10 [hard] Orders whose total revenue is greater than the average order total.
-- Show order_id, order_total (rounded to 2 decimals). Biggest first, top 10.
SELECT order_id, ROUND(order_total, 2) AS order_total
FROM (
    SELECT order_id, SUM(quantity * unit_price * (1 - discount_pct / 100.0)) AS order_total
    FROM order_items
    GROUP BY order_id
)
WHERE order_total > (
    SELECT AVG(t) FROM (
        SELECT SUM(quantity * unit_price * (1 - discount_pct / 100.0)) AS t
        FROM order_items
        GROUP BY order_id
    )
)
ORDER BY order_total DESC
LIMIT 10;
-- Tip: the same subquery written twice is a sign you want a CTE. That is tomorrow's topic.
