#!/usr/bin/env python3
"""Run a .sql file (or one query) against practice.db and show the results as tables.

    python3 run.py practice/05-subqueries.sql          run every query in the file
    python3 run.py practice/05-subqueries.sql 3        run only Q3
    python3 run.py -c "SELECT * FROM products LIMIT 5" run one query
    add  --rows 50  to show more than 20 rows per query
"""
import re
import sqlite3
import sys
from pathlib import Path

DB = Path(__file__).parent / "practice.db"


def split_statements(text):
    """Yield (label, sql) pairs. A '-- Q<n>' comment sets the label for the statements after it."""
    label, buf = "", []
    for line in text.splitlines():
        started = any(b.strip() and not b.strip().startswith("--") for b in buf)
        m = re.match(r"--\s*(Q\d+)\b", line)
        if m and not started:
            label, buf = m.group(1), []
            continue
        if not started and (not line.strip() or line.strip().startswith("--")):
            continue
        buf.append(line)
        sql = "\n".join(buf)
        if sqlite3.complete_statement(sql):
            yield label, sql.strip()
            buf = []
    if "\n".join(buf).strip():
        yield label, "\n".join(buf).strip()


def fmt(v):
    if v is None:
        return "NULL"
    if isinstance(v, float):
        return f"{v:.2f}".rstrip("0").rstrip(".") if v != int(v) else str(int(v))
    return str(v)


def show(cur, rows_limit):
    if cur.description is None:
        print("(no result)")
        return
    head = [d[0] for d in cur.description]
    rows = cur.fetchall()
    shown = [[fmt(v)[:34] for v in r] for r in rows[:rows_limit]]
    widths = [max([len(h)] + [len(r[i]) for r in shown]) for i, h in enumerate(head)]
    line = "  ".join(h.ljust(w) for h, w in zip(head, widths))
    print(line)
    print("  ".join("-" * w for w in widths))
    for r in shown:
        print("  ".join(c.ljust(w) for c, w in zip(r, widths)))
    extra = len(rows) - len(shown)
    print(f"({len(rows)} rows" + (f", showing {len(shown)}" if extra > 0 else "") + ")")


def main(argv):
    rows_limit = 20
    if "--rows" in argv:
        i = argv.index("--rows")
        rows_limit = int(argv[i + 1])
        del argv[i:i + 2]
    if not argv:
        sys.exit(__doc__)
    if not DB.exists():
        sys.exit("practice.db not found. Run: python3 build_db.py")
    con = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
    if argv[0] == "-c":
        stmts = [("", " ".join(argv[1:]))]
    else:
        stmts = list(split_statements(Path(argv[0]).read_text(encoding="utf-8")))
        if len(argv) > 1:
            want = "Q" + argv[1].lstrip("Qq")
            stmts = [s for s in stmts if s[0] == want]
    ran = 0
    for label, sql in stmts:
        if not re.sub(r"--.*", "", sql).strip(" ;\n\t"):
            continue
        ran += 1
        print(f"\n=== {label or 'query'} " + "=" * 50)
        try:
            show(con.execute(sql), rows_limit)
        except sqlite3.Error as e:
            print(f"ERROR: {e}")
    if not ran:
        print("No queries found. Write your SQL under a '-- Q1' line and end each query with a semicolon.")


main(sys.argv[1:])
