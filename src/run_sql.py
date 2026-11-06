"""Run SQL files against data/project.db; optionally load processed CSVs.
Usage: python3 src/run_sql.py sql/01_schema.sql --load
"""
import sqlite3
import sys
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
DB = ROOT / "data" / "project.db"
PROCESSED = ROOT / "data" / "processed"
TABLES = ["tga_episodes", "pbs_public_monthly", "pbs_ingredient_lookup"]


def run_sql_file(con, path):
    con.executescript(Path(path).read_text(encoding="utf-8"))
    con.commit()
    print(f"ran {path}")


def load_processed(con):
    for t in TABLES:
        df = pd.read_csv(PROCESSED / f"{t}.csv")
        df.to_sql(t, con, if_exists="append", index=False)
        n = con.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0]
        status = "OK" if n == len(df) else "MISMATCH"
        print(f"{t}: csv={len(df)} db={n} {status}")
    con.commit()


def main():
    args = sys.argv[1:]
    files = [a for a in args if a != "--load"]
    with sqlite3.connect(DB) as con:
        for f in files:
            run_sql_file(con, f)
        if "--load" in args:
            load_processed(con)


if __name__ == "__main__":
    main()
