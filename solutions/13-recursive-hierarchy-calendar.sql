-- 13 Recursive CTEs: org charts (hierarchies) and generated calendars
-- Day 13. Tables: employees (manager_id points to another employee), orders.
-- A recursive CTE has two parts joined by UNION ALL: an anchor (where to start) and a recursive step
-- (how to get from one level to the next). It stops by itself when the step returns no new rows.
-- In SQL Server it is WITH ... AS (...) without the word RECURSIVE. Spark SQL added recursive CTEs recently,
-- so check your runtime before relying on them there.

-- Q1 [medium] The org chart level of every employee: the CEO is level 0, people who report to the CEO are
-- level 1, and so on. Show employee_id, first_name, last_name, level.
WITH RECURSIVE chart AS (
    SELECT employee_id, first_name, last_name, 0 AS level
    FROM employees
    WHERE manager_id IS NULL
    UNION ALL
    SELECT e.employee_id, e.first_name, e.last_name, c.level + 1
    FROM employees AS e
    JOIN chart AS c ON e.manager_id = c.employee_id
)
SELECT employee_id, first_name, last_name, level
FROM chart;

-- Q2 [easy] How many employees are at each level of the org chart? Show level, employees.
WITH RECURSIVE chart AS (
    SELECT employee_id, 0 AS level FROM employees WHERE manager_id IS NULL
    UNION ALL
    SELECT e.employee_id, c.level + 1
    FROM employees AS e
    JOIN chart AS c ON e.manager_id = c.employee_id
)
SELECT level, COUNT(*) AS employees
FROM chart
GROUP BY level
ORDER BY level;

-- Q3 [medium] Everyone who works anywhere under employee 102 (the VP of Engineering), directly or through
-- other managers. Do not include 102 themself. Show employee_id, first_name, last_name, job_title.
WITH RECURSIVE team AS (
    SELECT employee_id FROM employees WHERE manager_id = 102
    UNION ALL
    SELECT e.employee_id
    FROM employees AS e
    JOIN team AS t ON e.manager_id = t.employee_id
)
SELECT e.employee_id, e.first_name, e.last_name, e.job_title
FROM team AS t
JOIN employees AS e ON e.employee_id = t.employee_id;

-- Q4 [hard] The reporting chain of every employee in department 3 (Data & Analytics), from the CEO down to
-- the person, as text like 'Camille Lee > Camille Perez > Marco Hassan'. Show employee_id, chain.
WITH RECURSIVE chain AS (
    SELECT employee_id, first_name || ' ' || last_name AS path
    FROM employees
    WHERE manager_id IS NULL
    UNION ALL
    SELECT e.employee_id, c.path || ' > ' || e.first_name || ' ' || e.last_name
    FROM employees AS e
    JOIN chain AS c ON e.manager_id = c.employee_id
)
SELECT e.employee_id, c.path AS chain
FROM chain AS c
JOIN employees AS e ON e.employee_id = c.employee_id
WHERE e.department_id = 3;

-- Q5 [hard] The total team size under each manager at every depth (not just direct reports), for the top 5
-- biggest teams. Show manager_id, team_size. Ties by manager_id.
WITH RECURSIVE below AS (
    SELECT manager_id AS boss_id, employee_id
    FROM employees
    WHERE manager_id IS NOT NULL
    UNION ALL
    SELECT b.boss_id, e.employee_id
    FROM below AS b
    JOIN employees AS e ON e.manager_id = b.employee_id
)
SELECT boss_id AS manager_id, COUNT(*) AS team_size
FROM below
GROUP BY boss_id
ORDER BY team_size DESC, boss_id
LIMIT 5;
-- Tip: the anchor here is every manager-employee pair. The recursive step adds the people one level further
-- down, still tagged with the original boss.

-- Q6 [hard] Total salary cost of each VP's whole organisation, including the VP: for the employees who report
-- directly to the CEO (manager_id = 101) show vp_id, people (counting the VP) and total_salary.
WITH RECURSIVE org AS (
    SELECT employee_id AS vp_id, employee_id, salary
    FROM employees
    WHERE manager_id = 101
    UNION ALL
    SELECT o.vp_id, e.employee_id, e.salary
    FROM employees AS e
    JOIN org AS o ON e.manager_id = o.employee_id
)
SELECT vp_id, COUNT(*) AS people, SUM(salary) AS total_salary
FROM org
GROUP BY vp_id;

-- Q7 [medium] Generate a calendar: every date from 2026-10-01 to 2026-10-30 (the last day of data), then count the orders on each day,
-- showing zero for days without orders. How many days in October 2026 had no orders at all?
-- One column: days_without_orders.
WITH RECURSIVE days(d) AS (
    SELECT '2026-10-01'
    UNION ALL
    SELECT date(d, '+1 day') FROM days WHERE d < '2026-10-30'
)
SELECT COUNT(*) AS days_without_orders
FROM days
LEFT JOIN orders AS o ON o.order_date = days.d
WHERE o.order_id IS NULL;
-- Tip: this is how you find missing days when the data has no rows for them. In SQL Server you
-- would use a recursive CTE too or a tally table, in Spark SQL sequence() + explode().

-- Q8 [hard] The same calendar for the whole data period (2025-01-01 to 2026-10-30): for each month show the number of
-- days with no orders. Show month ('YYYY-MM'), days_without_orders. Only months where it is more than 0.
WITH RECURSIVE days(d) AS (
    SELECT '2025-01-01'
    UNION ALL
    SELECT date(d, '+1 day') FROM days WHERE d < '2026-10-30'
)
SELECT strftime('%Y-%m', days.d) AS month, COUNT(*) AS days_without_orders
FROM days
LEFT JOIN orders AS o ON o.order_date = days.d
WHERE o.order_id IS NULL
GROUP BY month
HAVING COUNT(*) > 0
ORDER BY month;

-- Q9 [hard] Daily orders with a 7-day rolling sum, for 1 to 30 October 2026, including days with zero orders.
-- Show order_date, orders, rolling_7d_orders (this day and the six days before it, using the calendar so
-- that missing days count as zero). Only the dates 2026-10-01 to 2026-10-30 should appear.
WITH RECURSIVE days(d) AS (
    SELECT '2026-09-25'
    UNION ALL
    SELECT date(d, '+1 day') FROM days WHERE d < '2026-10-30'
),
daily AS (
    SELECT days.d AS order_date, COUNT(o.order_id) AS orders
    FROM days
    LEFT JOIN orders AS o ON o.order_date = days.d
    GROUP BY days.d
),
rolled AS (
    SELECT order_date, orders,
           SUM(orders) OVER (ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_7d_orders
    FROM daily
)
SELECT order_date, orders, rolling_7d_orders
FROM rolled
WHERE order_date >= '2026-10-01';
-- Tip: start the calendar six days early (09-25) so that the first days of October have a full window,
-- then filter in the last step.
