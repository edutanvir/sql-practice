#!/usr/bin/env python3
"""Build practice.db from schema.sql and the CSV files in ./data.

Run it whenever you want a fresh database:   python3 build_db.py
(If the CSVs are missing, run `python3 generate_data.py` first.)
"""
import csv
import sqlite3
import sys
from pathlib import Path

ROOT = Path(__file__).parent
DB = ROOT / "practice.db"
ORDER = ["departments", "employees", "products", "customers", "customer_address_history", "orders", "order_items",
         "daily_logins"]

if sqlite3.sqlite_version_info < (3, 25):
    sys.exit(f"SQLite {sqlite3.sqlite_version} is too old. Window functions need 3.25 or newer.")
missing = [t for t in ORDER if not (ROOT / "data" / f"{t}.csv").exists()]
if missing:
    sys.exit("Missing CSV files: " + ", ".join(missing) + ". Run: python3 generate_data.py")

DB.unlink(missing_ok=True)
con = sqlite3.connect(DB)
con.executescript((ROOT / "schema.sql").read_text(encoding="utf-8"))
for table in ORDER:
    with open(ROOT / "data" / f"{table}.csv", newline="", encoding="utf-8") as f:
        rows = csv.reader(f)
        cols = next(rows)
        data = [[None if v == "" else v for v in r] for r in rows]
    con.executemany(f"INSERT INTO {table} ({','.join(cols)}) VALUES ({','.join('?' * len(cols))})", data)
    print(f"{table:26s}{len(data):>7,} rows")
con.commit()
fk = con.execute("PRAGMA foreign_key_check").fetchall()
print("foreign key problems:", len(fk))
con.close()
print(f"\nBuilt {DB.name} with SQLite {sqlite3.sqlite_version}")
