#!/usr/bin/env python3
"""Start a practice file: copies the questions (without answers) from solutions/ to practice/.

    python3 start.py 5      creates practice/05-<topic>.sql
    python3 start.py        lists all the topics
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).parent
SOL = sorted((ROOT / "solutions").glob("*.sql"))


def questions_only(text):
    """Keep the title lines and each question's comment lines. Drop the SQL and any notes after it."""
    out, mode = [], "head"
    for line in text.splitlines():
        if re.match(r"--\s*Q\d+\b", line):
            out += ["", "", line] if out else [line]
            mode = "question"
        elif mode == "head":
            out.append(line)
        elif mode == "question":
            if line.strip().startswith("--"):
                out.append(line)
            elif line.strip():
                mode = "sql"
    return "\n".join(out).rstrip() + "\n\n\n"


if len(sys.argv) == 1:
    for f in SOL:
        n_q = len(re.findall(r"^--\s*Q\d+\b", f.read_text(encoding="utf-8"), re.M))
        print(f"  {f.name:42s}{n_q:>3} questions")
    sys.exit()

n = sys.argv[1].zfill(2)
match = [f for f in SOL if f.name.startswith(n + "-")]
if not match:
    sys.exit(f"No topic numbered {n}. Run `python3 start.py` to see the list.")
dest = ROOT / "practice" / match[0].name
if dest.exists():
    sys.exit(f"{dest.relative_to(ROOT)} already exists. Open it in VS Code and keep going.")
dest.parent.mkdir(exist_ok=True)
text = match[0].read_text(encoding="utf-8")
# keep the title comment lines at the top, then only the question comments
dest.write_text(questions_only(text), encoding="utf-8")
print(f"Created {dest.relative_to(ROOT)}. Write each answer under its question, then run:")
print(f"  python3 run.py {dest.relative_to(ROOT)}")
print(f"  python3 check.py {int(n)}")
