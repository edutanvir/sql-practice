-- 14 Slowly changing dimensions (type 2): history tables and "as of" joins
-- Day 14. Tables: customer_address_history, customers, orders.
-- customer_address_history keeps one row per address period. valid_from and valid_to are the first and
-- last day of the period, and the current address has valid_to = '9999-12-31' and is_current = 1.
-- 104 customers have moved once, so they have two rows. This is how data warehouses store history.

-- Q1 [easy] The current address of every customer who has one: customer_id, city, province.
SELECT customer_id, city, province
FROM customer_address_history
WHERE is_current = 1;

-- Q2 [easy] Customers who have moved: those with more than one address row. Show customer_id, addresses.
SELECT customer_id, COUNT(*) AS addresses
FROM customer_address_history
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Q3 [medium] For each customer who moved, show where they lived before and where they live now, and the
-- date they moved. Show customer_id, old_city, new_city, moved_on (the valid_from of the new address).
SELECT o.customer_id, o.city AS old_city, n.city AS new_city, n.valid_from AS moved_on
FROM customer_address_history AS o
JOIN customer_address_history AS n
  ON n.customer_id = o.customer_id
 AND n.is_current = 1
WHERE o.is_current = 0;

-- Q4 [medium] Where did customer 1025 live on 2026-01-15? Show city, province.
-- (Pick the row whose period contains the date.)
SELECT city, province
FROM customer_address_history
WHERE customer_id = 1025
  AND '2026-01-15' BETWEEN valid_from AND valid_to;
-- Tip: that BETWEEN is the "as of" lookup. Because the periods do not overlap, only one row matches.

-- Q5 [hard] The city each order was shipped to, meaning the customer's address on the order date.
-- Show order_id, order_date, city for orders of customers 1019, 1025 and 1035. Newest first.
SELECT o.order_id, o.order_date, h.city
FROM orders AS o
JOIN customer_address_history AS h
  ON h.customer_id = o.customer_id
 AND o.order_date BETWEEN h.valid_from AND h.valid_to
WHERE o.customer_id IN (1019, 1025, 1035)
ORDER BY o.order_date DESC, o.order_id DESC;

-- Q6 [hard] Orders and customers by the city where the customer lived at the time of the order. Show the 5 cities
-- with the most orders: city, orders, customers (distinct). Ties by city.
SELECT h.city, COUNT(*) AS orders, COUNT(DISTINCT o.customer_id) AS customers
FROM orders AS o
JOIN customer_address_history AS h
  ON h.customer_id = o.customer_id
 AND o.order_date BETWEEN h.valid_from AND h.valid_to
GROUP BY h.city
ORDER BY orders DESC, h.city
LIMIT 5;

-- Q7 [hard] Orders that were placed while the customer lived at an address that is no longer current: how many
-- orders, and how many different customers? One row: orders_at_old_address, customers.
SELECT COUNT(*) AS orders_at_old_address, COUNT(DISTINCT o.customer_id) AS customers
FROM orders AS o
JOIN customer_address_history AS h
  ON h.customer_id = o.customer_id
 AND o.order_date BETWEEN h.valid_from AND h.valid_to
WHERE h.is_current = 0;
-- Tip: using the CURRENT address for old orders would put these orders in the wrong city. This is the whole
-- reason type 2 history exists.

-- Q8 [medium] People who moved to a different province: how many moved from each province to each other province?
-- Show from_province, to_province, movers. Most common first, then from_province, then to_province.
SELECT o.province AS from_province, n.province AS to_province, COUNT(*) AS movers
FROM customer_address_history AS o
JOIN customer_address_history AS n
  ON n.customer_id = o.customer_id AND n.is_current = 1
WHERE o.is_current = 0
  AND o.province <> n.province
GROUP BY o.province, n.province
ORDER BY movers DESC, from_province, to_province;

-- Q9 [hard] Check the history for problems. For each customer, flag any case where the next period does not start
-- exactly one day after the previous period ends (a gap or an overlap). Show customer_id, valid_to,
-- next_valid_from. (The clean data returns no rows. Keep this query, it is a real data-quality test.)
WITH periods AS (
    SELECT customer_id, valid_from, valid_to,
           LEAD(valid_from) OVER (PARTITION BY customer_id ORDER BY valid_from) AS next_valid_from
    FROM customer_address_history
)
SELECT customer_id, valid_to, next_valid_from
FROM periods
WHERE next_valid_from IS NOT NULL
  AND next_valid_from <> date(valid_to, '+1 day');

-- Q10 [hard] How long did movers live at their old address? Show old_city and average_days
-- (rounded to 0 decimals) and movers, for old cities with at least 3 movers. Highest average first, ties by city.
SELECT o.city AS old_city,
       ROUND(AVG(julianday(o.valid_to) - julianday(o.valid_from) + 1), 0) AS average_days,
       COUNT(*) AS movers
FROM customer_address_history AS o
WHERE o.is_current = 0
GROUP BY o.city
HAVING COUNT(*) >= 3
ORDER BY average_days DESC, old_city;
