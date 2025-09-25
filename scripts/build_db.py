"""
Builds a SQLite database (data.sqlite) from SQL parts under data/sql.

Usage:
  python scripts/build_db.py

Requirements:
  - Python 3.9+
  - Standard library only (uses sqlite3)

Output:
  - data/data.sqlite (created/overwritten)
"""
from __future__ import annotations

import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SQL_DIR = ROOT / "data" / "sql"
OUT_DB = ROOT / "data" / "data.sqlite"
ALL_IN_ONE_SQL = SQL_DIR / "zz_all_in_one.sql"


def run_sql(conn: sqlite3.Connection, path: Path) -> None:
    sql = path.read_text(encoding="utf-8")
    conn.executescript(sql)


def main() -> None:
    OUT_DB.parent.mkdir(parents=True, exist_ok=True)
    if OUT_DB.exists():
        OUT_DB.unlink()
    conn = sqlite3.connect(str(OUT_DB))
    try:
        conn.execute("PRAGMA foreign_keys=ON;")
        # Apply in order
        parts = ["00_schema.sql"]
        gen_sql = SQL_DIR / "50_generated_data.sql"
        if gen_sql.exists():
            parts.append("50_generated_data.sql")
        else:
            parts.append("90_sample_data.sql")  # fallback
        parts.append("99_fts.sql")
        for name in parts:
            run_sql(conn, SQL_DIR / name)
        conn.commit()
        print(f"Built: {OUT_DB}")
        # Also emit an all-in-one SQL for first-run initialization in app
        combined = []
        for name in parts:
            p = SQL_DIR / name
            combined.append(f"-- >>> {name}\n")
            combined.append(p.read_text(encoding="utf-8"))
            combined.append("\n")
        ALL_IN_ONE_SQL.write_text("\n".join(combined), encoding="utf-8")
        print(f"Wrote: {ALL_IN_ONE_SQL}")
    finally:
        conn.close()


if __name__ == "__main__":
    main()
