-- Northern Trail Co.: an invented Ontario online outdoor-gear store.
-- Orders run from 2025-01-01 to 2026-10-30. Dates are stored as 'YYYY-MM-DD' text (SQLite has no date type).

CREATE TABLE departments (
    department_id    INTEGER PRIMARY KEY,
    department_name  TEXT NOT NULL,
    location         TEXT
);

CREATE TABLE employees (
    employee_id    INTEGER PRIMARY KEY,
    first_name     TEXT NOT NULL,
    last_name      TEXT NOT NULL,
    department_id  INTEGER NOT NULL REFERENCES departments (department_id),
    manager_id     INTEGER REFERENCES employees (employee_id),   -- NULL for the CEO
    job_title      TEXT NOT NULL,
    hire_date      TEXT NOT NULL,
    salary         INTEGER NOT NULL
);

CREATE TABLE products (
    product_id         INTEGER PRIMARY KEY,
    product_name       TEXT NOT NULL,
    category           TEXT NOT NULL,
    list_price         REAL NOT NULL,
    cost_price         REAL NOT NULL,
    launch_date        TEXT NOT NULL,
    discontinued_date  TEXT                                        -- NULL = still on sale
);

CREATE TABLE customers (
    customer_id          INTEGER PRIMARY KEY,
    first_name           TEXT NOT NULL,
    last_name            TEXT NOT NULL,
    email                TEXT NOT NULL,                            -- messy on purpose: duplicates differ by case/spaces
    city                 TEXT,                                     -- NULL for a few customers
    province             TEXT,
    signup_date          TEXT NOT NULL,
    acquisition_channel  TEXT NOT NULL
);

-- Slowly changing dimension (type 2): one row per address period.
-- valid_to = '9999-12-31' for the current address.
CREATE TABLE customer_address_history (
    history_id    INTEGER PRIMARY KEY,
    customer_id   INTEGER NOT NULL REFERENCES customers (customer_id),
    address_line  TEXT NOT NULL,
    city          TEXT NOT NULL,
    province      TEXT NOT NULL,
    valid_from    TEXT NOT NULL,
    valid_to      TEXT NOT NULL,
    is_current    INTEGER NOT NULL
);

CREATE TABLE orders (
    order_id     INTEGER PRIMARY KEY,
    customer_id  INTEGER NOT NULL REFERENCES customers (customer_id),
    order_date   TEXT NOT NULL,
    status       TEXT NOT NULL,                                    -- completed, cancelled, returned
    channel      TEXT NOT NULL,                                    -- web, mobile, store
    coupon_code  TEXT                                              -- NULL when no coupon was used
);

CREATE TABLE order_items (
    order_item_id  INTEGER PRIMARY KEY,
    order_id       INTEGER NOT NULL REFERENCES orders (order_id),
    product_id     INTEGER NOT NULL REFERENCES products (product_id),
    quantity       INTEGER NOT NULL,
    unit_price     REAL NOT NULL,
    discount_pct   INTEGER NOT NULL                                -- 0, 10, 15, 20 or 25
);

-- One row per customer per day they logged in (for streak / gaps-and-islands practice).
CREATE TABLE daily_logins (
    customer_id  INTEGER NOT NULL REFERENCES customers (customer_id),
    login_date   TEXT NOT NULL,
    PRIMARY KEY (customer_id, login_date)
);

CREATE INDEX idx_orders_customer ON orders (customer_id);
CREATE INDEX idx_orders_date     ON orders (order_date);
CREATE INDEX idx_items_order     ON order_items (order_id);
CREATE INDEX idx_items_product   ON order_items (product_id);
