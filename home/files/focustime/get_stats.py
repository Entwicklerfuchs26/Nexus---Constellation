#!/usr/bin/env python3
"""FocusTime — Stats-Query fuer historische Tage / App-Detailansicht.

Aufruf: get_stats.py <ISO-Datum> [--app <class>] [--db-dir <dir>]
Gibt das gemeinsame JSON-Schema (siehe focustime_stats.py) auf stdout aus.
"""
import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from focustime_stats import compute_stats  # noqa: E402


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("date")
    parser.add_argument("--app", default=None)
    parser.add_argument(
        "--db-dir",
        default=os.environ.get("QS_STATE_FOCUSTIME", os.path.expanduser("~/.local/state/focustime")),
    )
    args = parser.parse_args()

    db_path = os.path.join(args.db_dir, "focustime.db")
    try:
        stats = compute_stats(db_path, args.date, app_filter=args.app)
    except ValueError as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)
    print(json.dumps(stats))


if __name__ == "__main__":
    main()
