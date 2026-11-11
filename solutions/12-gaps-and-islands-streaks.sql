-- 12 Gaps and islands: streaks of consecutive days (a classic hard interview question)
-- Day 12. Table: daily_logins (one row per customer per day they logged in,
-- 2026-08-01 to 2026-10-31, 220 customers).
-- The trick: for each customer, subtract the row number (in date order) from the date. Days in the same
-- unbroken streak end up with the same result, so that result identifies the island.

-- Q1 [easy] The 5 customers with the most login days. Show customer_id, login_days. Ties by customer_id.
SELECT customer_id, COUNT(*) AS login_days
FROM daily_logins
GROUP BY customer_id
ORDER BY login_days DESC, customer_id
LIMIT 5;

-- Q2 [easy] Daily active users: the 5 busiest login days. Show login_date, active_customers.
-- Ties by login_date.
SELECT login_date, COUNT(*) AS active_customers
FROM daily_logins
GROUP BY login_date
ORDER BY active_customers DESC, login_date
LIMIT 5;

-- Q3 [medium] Customers who logged in on 3 days in a row at least once. Show customer_id.
-- (Do not use the islands trick yet: try LAG, LEAD or a self-join.)
WITH nb AS (
    SELECT customer_id, login_date,
           LAG(login_date, 1)  OVER (PARTITION BY customer_id ORDER BY login_date) AS d1,
           LAG(login_date, 2)  OVER (PARTITION BY customer_id ORDER BY login_date) AS d2
    FROM daily_logins
)
SELECT DISTINCT customer_id
FROM nb
WHERE julianday(login_date) - julianday(d1) = 1
  AND julianday(d1) - julianday(d2) = 1;

-- Q4 [hard] All streaks of every customer. Show customer_id, streak_start, streak_end, streak_days
-- for customers 1055 and 1336 only, in date order.
WITH numbered AS (
    SELECT customer_id, login_date,
           date(login_date, '-' || ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY login_date) || ' days') AS island_key
    FROM daily_logins
)
SELECT customer_id,
       MIN(login_date) AS streak_start,
       MAX(login_date) AS streak_end,
       COUNT(*) AS streak_days
FROM numbered
WHERE customer_id IN (1055, 1336)
GROUP BY customer_id, island_key
ORDER BY customer_id, streak_start;
-- Tip: date minus row number is constant inside a streak. If a day is missing, the key jumps and a new island starts.

-- Q5 [hard] The longest streak of each customer. Show customer_id, longest_streak, for the 10 customers
-- with the longest streaks (ties by customer_id).
WITH numbered AS (
    SELECT customer_id, login_date,
           date(login_date, '-' || ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY login_date) || ' days') AS island_key
    FROM daily_logins
),
streaks AS (
    SELECT customer_id, island_key, COUNT(*) AS streak_days
    FROM numbered
    GROUP BY customer_id, island_key
)
SELECT customer_id, MAX(streak_days) AS longest_streak
FROM streaks
GROUP BY customer_id
ORDER BY longest_streak DESC, customer_id
LIMIT 10;

-- Q6 [hard] The 5 longest single streaks in the whole table: customer_id, streak_start, streak_end,
-- streak_days. Ties by customer_id, then streak_start.
WITH numbered AS (
    SELECT customer_id, login_date,
           date(login_date, '-' || ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY login_date) || ' days') AS island_key
    FROM daily_logins
)
SELECT customer_id, MIN(login_date) AS streak_start, MAX(login_date) AS streak_end, COUNT(*) AS streak_days
FROM numbered
GROUP BY customer_id, island_key
ORDER BY streak_days DESC, customer_id, streak_start
LIMIT 5;

-- Q7 [hard] Customers with an active streak right now: their latest login is 2026-10-31 and the streak is at
-- least 5 days long. Show customer_id, streak_start, current_streak_days.
WITH numbered AS (
    SELECT customer_id, login_date,
           date(login_date, '-' || ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY login_date) || ' days') AS island_key
    FROM daily_logins
),
streaks AS (
    SELECT customer_id, MIN(login_date) AS streak_start, MAX(login_date) AS streak_end, COUNT(*) AS streak_days
    FROM numbered
    GROUP BY customer_id, island_key
)
SELECT customer_id, streak_start, streak_days AS current_streak_days
FROM streaks
WHERE streak_end = '2026-10-31' AND streak_days >= 5;

-- Q8 [medium] How many separate streaks (islands) does each customer have? Show the distribution:
-- streak_count, customers (how many customers have that many streaks). Smallest count first.
WITH numbered AS (
    SELECT customer_id, login_date,
           date(login_date, '-' || ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY login_date) || ' days') AS island_key
    FROM daily_logins
),
per_customer AS (
    SELECT customer_id, COUNT(DISTINCT island_key) AS streak_count
    FROM numbered
    GROUP BY customer_id
)
SELECT streak_count, COUNT(*) AS customers
FROM per_customer
GROUP BY streak_count
ORDER BY streak_count;

-- Q9 [hard] The gaps: for customer 1055 show every gap between two logins longer than one day.
-- Show gap_start (the last login before the gap), gap_end (the next login), missing_days (days without login
-- in between).
WITH nb AS (
    SELECT login_date AS gap_start,
           LEAD(login_date) OVER (ORDER BY login_date) AS gap_end
    FROM daily_logins
    WHERE customer_id = 1055
)
SELECT gap_start, gap_end,
       CAST(julianday(gap_end) - julianday(gap_start) AS INTEGER) - 1 AS missing_days
FROM nb
WHERE julianday(gap_end) - julianday(gap_start) > 1;
