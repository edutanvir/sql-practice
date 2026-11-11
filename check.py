#!/usr/bin/env python3
"""Check your answers against the solutions.

    python3 check.py 5                              check practice/05-*.sql
    python3 check.py practice/05-subqueries.sql    the same, by path

Each question passes when your query returns the same rows as the solution
(column names and row order do not matter, unless the solution has a final ORDER BY
and then you only get a hint). Results are saved in progress.md.
"""
import re
import sqlite3
import sys
from datetime import date
from pathlib import Path

ROOT = Path(__file__).parent
DB = ROOT / "practice.db"


def blocks(text):
    """Return {'Q1': (tag, sql)}. SQL is the non-comment lines under each '-- Q<n> [tag]' line."""
    out, cur, tag, buf = {}, None, "", []
    for line in text.splitlines():
        m = re.match(r"--\s*(Q\d+)\b\s*(?:\[(\w+)\])?", line)
        if m:
            if cur:
                out[cur] = (tag, "\n".join(buf).strip())
            cur, tag, buf = m.group(1), (m.group(2) or "").lower(), []
        elif cur and not line.strip().startswith("--"):
            buf.append(line)
    if cur:
        out[cur] = (tag, "\n".join(buf).strip())
    return out


def norm(v):
    """Round floats to 2 decimals, and treat 5.0 and 5 as the same number."""
    if isinstance(v, float):
        v = round(v, 2)
        return int(v) if v == int(v) else v
    return v


def run(con, sql):
    rows = con.execute(sql.strip().rstrip(";")).fetchall()
    return [tuple(norm(v) for v in r) for r in rows]


def has_final_order_by(sql):
    """True if the statement has an ORDER BY outside any parentheses (so not inside OVER or a CTE)."""
    s, depth, out = re.sub(r"'[^']*'", "''", sql), 0, []
    for ch in s:
        depth += (ch == "(") - (ch == ")")
        out.append(ch if depth == 0 else " ")
    return bool(re.search(r"\border\s+by\b", "".join(out), re.I))


def key(r):
    return tuple((v is None, str(v)) for v in r)


def find_files(arg):
    p = Path(arg)
    if p.exists():
        return p, ROOT / "solutions" / p.name
    n = arg.zfill(2)
    mine = sorted((ROOT / "practice").glob(f"{n}-*.sql"))
    sol = sorted((ROOT / "solutions").glob(f"{n}-*.sql"))
    if not sol:
        sys.exit(f"No solution file numbered {n}. Look in the solutions folder.")
    if not mine:
        sys.exit(f"You have not started file {n} yet. Run:  python3 start.py {int(n)}")
    return mine[0], sol[0]


def update_progress(name, passed, total):
    path = ROOT / "progress.md"
    rows = {}
    if path.exists():
        for line in path.read_text(encoding="utf-8").splitlines():
            m = re.match(r"\|\s*(\S+\.sql)\s*\|(.*)\|", line)
            if m:
                rows[m.group(1)] = line
    rows[name] = f"| {name} | {date.today().isoformat()} | {passed} / {total} |"
    body = "\n".join(rows[k] for k in sorted(rows))
    path.write_text("# My SQL progress\n\nUpdated automatically by `check.py`.\n\n"
                    "| File | Last checked | Passed |\n| --- | --- | --- |\n" + body + "\n", encoding="utf-8")


def main(arg):
    mine_path, sol_path = find_files(arg)
    con = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
    mine, sol = blocks(mine_path.read_text(encoding="utf-8")), blocks(sol_path.read_text(encoding="utf-8"))
    passed = total = 0
    print(f"\nChecking {mine_path.name}\n")
    for q, (tag, sol_sql) in sol.items():
        if tag == "explore":
            print(f"  {q}  explore: no right answer to check, compare with solutions/{sol_path.name}")
            continue
        total += 1
        my_sql = mine.get(q, ("", ""))[1]
        if not re.sub(r"--.*", "", my_sql).strip(" ;\n\t"):
            print(f"  {q}  not attempted yet")
            continue
        want = run(con, sol_sql)
        try:
            got = run(con, my_sql)
        except sqlite3.Error as e:
            print(f"  {q}  error: {e}")
            continue
        if sorted(map(key, got)) == sorted(map(key, want)):
            passed += 1
            note = ""
            if has_final_order_by(sol_sql) and got != want:
                note = "  (rows match, but the solution sorts them differently)"
            print(f"  {q}  correct{note}")
            continue
        wc = len(want[0]) if want else 0
        gc = len(got[0]) if got else 0
        msg = f"expected {len(want)} rows, got {len(got)}"
        if want and got and wc != gc:
            msg += f"; expected {wc} columns, got {gc}"
        print(f"  {q}  not yet: {msg}")
        missing = [r for r in want if r not in got][:2]
        extra = [r for r in got if r not in want][:2]
        for r in missing:
            print(f"        missing: {tuple(fmt(v) for v in r)}")
        for r in extra:
            print(f"        extra:   {tuple(fmt(v) for v in r)}")
    print(f"\nScore: {passed} / {total}")
    update_progress(mine_path.name, passed, total)


def fmt(v):
    return "NULL" if v is None else (str(v)[:30])


if len(sys.argv) != 2:
    sys.exit(__doc__)
main(sys.argv[1])
