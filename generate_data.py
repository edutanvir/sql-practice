#!/usr/bin/env python3
"""Generate the practice dataset as CSV files in ./data (no packages needed).

The random seed is fixed, so everyone who runs this gets exactly the same rows.
Company: "Northern Trail Co.", an invented Ontario online outdoor-gear store.
Orders run from 2025-01-01 to 2026-10-31.
"""
import csv
import random
from datetime import date, timedelta
from pathlib import Path

SEED = 2026
START, END = date(2025, 1, 1), date(2026, 10, 31)
OUT = Path(__file__).parent / "data"
rng = random.Random(SEED)


def write(name, header, rows):
    OUT.mkdir(exist_ok=True)
    with open(OUT / f"{name}.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(header)
        for r in rows:
            w.writerow(["" if v is None else v for v in r])
    print(f"{name:26s}{len(rows):>7,} rows")


FIRST = ["Aiden", "Aisha", "Amir", "Ana", "Arjun", "Ava", "Ben", "Camille", "Chloe", "Daniel", "Dina", "Elena", "Emma",
         "Ethan", "Fatima", "Gabriel", "Hana", "Hugo", "Isabelle", "Ivan", "Jack", "Jasmine", "Jin", "Julien", "Kavya",
         "Kareem", "Lena", "Liam", "Lucas", "Maya", "Marco", "Mei", "Mia", "Nadia", "Noah", "Olivia", "Omar", "Priya",
         "Rafael", "Rhea", "Ryan", "Sara", "Sofia", "Tariq", "Theo", "Uma", "Victor", "Yara", "Zain", "Zoe"]
LAST = ["Ahmed", "Anderson", "Bouchard", "Brown", "Campbell", "Chen", "Clarke", "Cote", "Davis", "Dubois", "Fraser",
        "Gagnon", "Gill", "Gupta", "Hassan", "Ibrahim", "Johnson", "Khan", "Kim", "Lavoie", "Lee", "MacDonald", "Martin",
        "Miller", "Morin", "Nguyen", "Patel", "Perez", "Rahman", "Roy", "Santos", "Singh", "Smith", "Tremblay", "Wilson",
        "Wong", "Young", "Zhang"]
CITIES = [("Sudbury", "ON", 14), ("Toronto", "ON", 18), ("Ottawa", "ON", 9), ("Mississauga", "ON", 7),
          ("Hamilton", "ON", 6), ("London", "ON", 5), ("Kitchener", "ON", 4), ("Windsor", "ON", 3),
          ("Barrie", "ON", 3), ("Thunder Bay", "ON", 4), ("North Bay", "ON", 5), ("Sault Ste. Marie", "ON", 4),
          ("Timmins", "ON", 3), ("Montreal", "QC", 5), ("Vancouver", "BC", 4), ("Calgary", "AB", 3),
          ("Winnipeg", "MB", 2), ("Halifax", "NS", 2)]
STREETS = ["Elm St", "Maple Ave", "Cedar Rd", "Lakeshore Dr", "Pine St", "King St", "Queen St", "Bay St", "Oak Ln",
           "Birch Cres", "Notre Dame Ave", "Regent St", "Lasalle Blvd", "Larch St"]
CHANNELS = [("organic", 35), ("paid_search", 22), ("social", 18), ("referral", 15), ("email", 10)]


def pick(pairs):
    return rng.choices([p[0] for p in pairs], weights=[p[-1] for p in pairs])[0]


def d(x):
    return x.isoformat()


# ---------------------------------------------------------------- departments + employees
DEPTS = [(1, "Executive", "Sudbury"), (2, "Engineering", "Toronto"), (3, "Data & Analytics", "Sudbury"),
         (4, "Marketing", "Toronto"), (5, "Sales", "Ottawa"), (6, "Operations", "Sudbury"), (7, "Finance", "Toronto")]
write("departments", ["department_id", "department_name", "location"], DEPTS)

employees, eid = [], 100
used_names = set()


def new_emp(dept, mgr, title, lo, hi, hire_lo, hire_hi):
    global eid
    eid += 1
    while True:
        nm = (rng.choice(FIRST), rng.choice(LAST))
        if nm not in used_names:
            used_names.add(nm)
            break
    hire = date(2017, 1, 1) + timedelta(days=rng.randint(hire_lo, hire_hi))
    employees.append([eid, nm[0], nm[1], dept, mgr, title, d(hire), round(rng.randint(lo, hi), -2)])
    return eid


ceo = new_emp(1, None, "Chief Executive Officer", 220000, 260000, 0, 200)
titles = {2: ("VP Engineering", "Engineering Manager", ["Software Developer", "QA Analyst", "DevOps Engineer"]),
          3: ("VP Data", "Data Team Lead", ["Data Engineer", "Data Analyst", "BI Developer"]),
          4: ("VP Marketing", "Marketing Manager", ["Marketing Specialist", "Content Writer", "SEO Analyst"]),
          5: ("VP Sales", "Sales Manager", ["Account Executive", "Sales Rep", "Customer Success Rep"]),
          6: ("VP Operations", "Operations Manager", ["Warehouse Lead", "Logistics Coordinator", "Buyer"]),
          7: ("VP Finance", "Finance Manager", ["Accountant", "Financial Analyst", "Payroll Clerk"])}
for dept, (vp_t, mgr_t, staff_t) in titles.items():
    vp = new_emp(dept, ceo, vp_t, 170000, 200000, 100, 900)
    for _ in range(rng.randint(1, 2)):
        m = new_emp(dept, vp, mgr_t, 110000, 140000, 300, 1700)
        for _ in range(rng.randint(2, 4)):
            new_emp(dept, m, rng.choice(staff_t), 62000, 108000, 800, 3400)
write("employees", ["employee_id", "first_name", "last_name", "department_id", "manager_id", "job_title", "hire_date",
                    "salary"], employees)

# ---------------------------------------------------------------- products
CATALOG = {
    "Footwear": [("Trailhead Hiking Boots", 169.99), ("Lakeshore Trail Runners", 129.99), ("Boreal Winter Boots", 219.99),
                 ("Cedar Camp Sandals", 59.99), ("Ridgeline Approach Shoes", 139.99), ("Granite Waterproof Boots", 189.99),
                 ("Birch Everyday Sneakers", 99.99), ("Pine Wool Slippers", 49.99), ("Aurora Ice Cleats", 34.99),
                 ("Timber Work Boots", 159.99)],
    "Outerwear": [("Northern Shell Jacket", 249.99), ("Frostline Down Parka", 399.99), ("Rainier Rain Jacket", 179.99),
                  ("Cedar Fleece Pullover", 89.99), ("Boreal Insulated Vest", 119.99), ("Trailblazer Softshell", 149.99),
                  ("Glacier Ski Jacket", 329.99), ("Lakeshore Windbreaker", 79.99), ("Summit Puffer", 229.99),
                  ("Tundra Snow Pants", 139.99)],
    "Camping": [("Summit 2-Person Tent", 299.99), ("Boreal 4-Person Tent", 449.99), ("Cedar Sleeping Bag -10C", 189.99),
                ("Trailhead Camp Stove", 69.99), ("Lakeshore Cooler 24L", 89.99), ("Ridge Sleeping Pad", 79.99),
                ("Aurora Headlamp", 39.99), ("Granite Camp Chair", 54.99), ("Pine Hammock", 64.99),
                ("Timber Camp Axe", 44.99)],
    "Fitness": [("Cedar Yoga Mat", 44.99), ("Boreal Resistance Bands", 29.99), ("Lakeshore Dumbbell Set", 129.99),
                ("Summit Kettlebell 16kg", 69.99), ("Trailhead Foam Roller", 34.99), ("Ridge Jump Rope", 19.99),
                ("Aurora Fitness Tracker", 129.99), ("Granite Pull-up Bar", 59.99), ("Pine Water Bottle 1L", 24.99),
                ("Timber Gym Bag", 74.99)],
    "Accessories": [("Trail Backpack 30L", 119.99), ("Summit Daypack 20L", 79.99), ("Boreal Wool Toque", 29.99),
                    ("Cedar Merino Gloves", 49.99), ("Lakeshore Sunglasses", 89.99), ("Ridge Trekking Poles", 99.99),
                    ("Aurora Compass", 24.99), ("Granite Multi-tool", 59.99), ("Pine Dry Bag 12L", 29.99),
                    ("Timber Leather Belt", 39.99)],
    "Apparel": [("Cedar Merino Base Layer", 99.99), ("Boreal Thermal Leggings", 79.99), ("Lakeshore Quick-dry Tee", 39.99),
                ("Summit Hiking Pants", 109.99), ("Trailhead Flannel Shirt", 69.99), ("Ridge Hiking Shorts", 59.99),
                ("Aurora Sun Hoodie", 74.99), ("Granite Wool Socks 3-pack", 34.99), ("Pine Rain Pants", 99.99),
                ("Timber Canvas Work Pants", 89.99)],
}
products, pid = [], 200
for cat, items in CATALOG.items():
    for name, price in items:
        pid += 1
        launch = date(2024, 3, 1) + timedelta(days=rng.randint(0, 480))
        products.append([pid, name, cat, price, round(price * rng.uniform(0.45, 0.70), 2), d(launch), None])
for i in (225, 240, 255):  # late launches: very few or zero sales
    products[i - 201][5] = d(date(2026, 10, 24) + timedelta(days=rng.randint(0, 5)))
for i in (206, 219, 233, 248):  # discontinued during the period
    products[i - 201][6] = d(date(2025, 6, 1) + timedelta(days=rng.randint(0, 300)))
write("products", ["product_id", "product_name", "category", "list_price", "cost_price", "launch_date",
                   "discontinued_date"], products)
weights = {p[0]: rng.paretovariate(1.3) for p in products}

# ---------------------------------------------------------------- customers + address history
customers, history = [], []
signup_span = (date(2026, 9, 30) - START).days
for i in range(600):
    cid = 1001 + i
    first, last = rng.choice(FIRST), rng.choice(LAST)
    signup = START + timedelta(days=int(signup_span * rng.random() ** 1.25))  # more recent signups
    city, prov, _ = rng.choices(CITIES, weights=[c[2] for c in CITIES])[0]
    email = f"{first}.{last}{rng.randint(1, 99)}@example.com".lower()
    customers.append([cid, first, last, email, city, prov, d(signup), pick(CHANNELS)])
no_city = set(rng.sample(range(600), 18))
for i in no_city:
    customers[i][4] = customers[i][5] = None
hid = 0
for c in customers:
    if c[4] is None:
        continue
    signup = date.fromisoformat(c[6])
    cur_city, cur_prov = c[4], c[5]
    stops = [(signup, cur_city, cur_prov)]
    if rng.random() < 0.22 and signup < date(2026, 8, 1):
        old = rng.choices(CITIES, weights=[x[2] for x in CITIES])[0]
        if old[0] != cur_city:
            move = signup + timedelta(days=rng.randint(40, max(41, (date(2026, 9, 30) - signup).days)))
            stops = [(signup, old[0], old[1]), (move, cur_city, cur_prov)]
    for j, (frm, city, prov) in enumerate(stops):
        hid += 1
        last_stop = j == len(stops) - 1
        to = "9999-12-31" if last_stop else d(stops[j + 1][0] - timedelta(days=1))
        history.append([hid, c[0], f"{rng.randint(10, 999)} {rng.choice(STREETS)}", city, prov, d(frm), to,
                        1 if last_stop else 0])
# duplicate customers (same person registered twice, messy email), these have no orders
for k, i in enumerate(rng.sample(range(600), 12)):
    src = customers[i]
    mess = rng.choice([src[3].upper(), " " + src[3], src[3].capitalize(), src[3] + " "])
    customers.append([1601 + k, src[1], src[2], mess, src[4], src[5],
                      d(date.fromisoformat(src[6]) + timedelta(days=rng.randint(2, 40))), src[7]])
write("customers", ["customer_id", "first_name", "last_name", "email", "city", "province", "signup_date",
                    "acquisition_channel"], customers)
write("customer_address_history", ["history_id", "customer_id", "address_line", "city", "province", "valid_from",
                                   "valid_to", "is_current"], history)

# ---------------------------------------------------------------- orders + order_items
COUPONS = [("WELCOME10", 10), ("SPRING15", 15), ("FALL20", 20), ("VIP25", 25)]
SEASON = {1: 0.8, 2: 0.8, 3: 0.9, 4: 1.0, 5: 1.1, 6: 1.1, 7: 1.0, 8: 1.0, 9: 1.0, 10: 1.2, 11: 1.6, 12: 1.7}
raw_orders = []
for c in customers[:600]:
    if rng.random() < 0.16:  # never ordered
        continue
    signup = date.fromisoformat(c[6])
    n_target = 1 if rng.random() < 0.2 else max(2, min(40, int(3 * rng.paretovariate(1.4))))
    when = signup + timedelta(days=rng.randint(0, 20))
    for _ in range(n_target):
        if when > END:
            break
        raw_orders.append((when, c[0]))
        gap = rng.expovariate(1 / 24) / SEASON[when.month] + 3
        when += timedelta(days=int(gap))
raw_orders.sort()
orders, items, oid, iid = [], [], 10000, 50000
pids = [p[0] for p in products]
pinfo = {p[0]: p for p in products}
for when, cid in raw_orders:
    oid += 1
    status = rng.choices(["completed", "cancelled", "returned"], weights=[88, 7, 5])[0]
    channel = rng.choices(["web", "mobile", "store"], weights=[60, 30, 10])[0]
    coupon, pct = (None, 0)
    if rng.random() < 0.25:
        coupon, pct = rng.choice(COUPONS)
    orders.append([oid, cid, d(when), status, channel, coupon])
    live = [p for p in pids if pinfo[p][5] <= d(when) and (pinfo[p][6] is None or d(when) <= pinfo[p][6])]
    chosen = []
    for _ in range(rng.choices([1, 2, 3, 4], weights=[45, 30, 17, 8])[0]):
        p = rng.choices(live, weights=[weights[x] for x in live])[0]
        if p in chosen:
            continue
        chosen.append(p)
        iid += 1
        items.append([iid, oid, p, rng.choices([1, 2, 3], weights=[70, 22, 8])[0], pinfo[p][3], pct])
write("orders", ["order_id", "customer_id", "order_date", "status", "channel", "coupon_code"], orders)
write("order_items", ["order_item_id", "order_id", "product_id", "quantity", "unit_price", "discount_pct"], items)

# ---------------------------------------------------------------- daily logins (for streaks)
logins = []
ld_start, ld_end = date(2026, 8, 1), date(2026, 10, 31)
for c in rng.sample(customers[:600], 220):
    p_cont, p_start = rng.uniform(0.45, 0.92), rng.uniform(0.05, 0.35)
    on, day = rng.random() < 0.5, ld_start
    while day <= ld_end:
        on = rng.random() < (p_cont if on else p_start)
        if on and day >= date.fromisoformat(c[6]):
            logins.append([c[0], d(day)])
        day += timedelta(days=1)
logins.sort(key=lambda r: (r[0], r[1]))
write("daily_logins", ["customer_id", "login_date"], logins)
