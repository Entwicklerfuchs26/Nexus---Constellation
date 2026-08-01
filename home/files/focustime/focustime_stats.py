#!/usr/bin/env python3
"""FocusTime — gemeinsame Stats-Engine fuer Daemon und get_stats.py.

Schema (vereinfacht gegenueber der Referenz-Idee): zwei Tabellen statt vier.
focus_minutes liefert genug Aufloesung, um sowohl die 48x30min-Tageskurve
als auch die 7x24h-Wochen-Heatmap per SQL-Aggregation abzuleiten, ohne
redundante Zwischentabellen (focus_hourly/focus_intervals) zu pflegen.
"""
import datetime
import os
import sqlite3

DAY_NAMES_DE = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]

_desktop_cache = {}
_desktop_index = {}
_desktop_index_built = False


def _xdg_desktop_dirs():
    home = os.path.expanduser("~")
    dirs = [os.path.join(home, ".local/share/applications")]
    xdg_data_dirs = os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share")
    for d in xdg_data_dirs.split(":"):
        if d:
            dirs.append(os.path.join(d, "applications"))
    dirs.append(os.path.join(home, ".local/share/flatpak/exports/share/applications"))
    dirs.append("/var/lib/flatpak/exports/share/applications")
    dirs.append("/var/lib/snapd/desktop/applications")
    seen = set()
    result = []
    for d in dirs:
        if d not in seen and os.path.isdir(d):
            seen.add(d)
            result.append(d)
    return result


def _parse_desktop_file(path):
    name = None
    icon = None
    wm_class = None
    try:
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            in_entry = False
            for line in f:
                line = line.strip()
                if line == "[Desktop Entry]":
                    in_entry = True
                    continue
                if line.startswith("[") and line != "[Desktop Entry]":
                    if in_entry:
                        break
                    continue
                if not in_entry:
                    continue
                if line.startswith("Name=") and name is None:
                    name = line[len("Name="):].strip()
                elif line.startswith("Icon=") and icon is None:
                    icon = line[len("Icon="):].strip()
                elif line.startswith("StartupWMClass="):
                    wm_class = line[len("StartupWMClass="):].strip()
    except OSError:
        pass
    return name, icon, wm_class


def _build_desktop_index():
    global _desktop_index_built
    if _desktop_index_built:
        return
    for d in _xdg_desktop_dirs():
        try:
            entries = os.listdir(d)
        except OSError:
            continue
        for fname in entries:
            if not fname.endswith(".desktop"):
                continue
            name, icon, wm_class = _parse_desktop_file(os.path.join(d, fname))
            if not name:
                continue
            stem = fname[:-len(".desktop")]
            keys = {stem.lower()}
            if wm_class:
                keys.add(wm_class.lower())
            for k in keys:
                if k not in _desktop_index:
                    _desktop_index[k] = (name, icon or stem)
    _desktop_index_built = True


def resolve_app_info(app_class):
    if app_class in _desktop_cache:
        return _desktop_cache[app_class]
    _build_desktop_index()
    key = (app_class or "").lower()
    info = _desktop_index.get(key)
    if not info:
        short = key.split(".")[-1]
        info = _desktop_index.get(short)
    if not info:
        display = app_class.replace("-", " ").replace("_", " ").title() or "Unbekannt"
        info = (display, key)
    _desktop_cache[app_class] = info
    return info


def connect(db_path):
    os.makedirs(os.path.dirname(db_path), exist_ok=True)
    conn = sqlite3.connect(db_path)
    conn.execute(
        """CREATE TABLE IF NOT EXISTS focus_log (
            datum TEXT NOT NULL,
            app_class TEXT NOT NULL,
            seconds INTEGER NOT NULL DEFAULT 0,
            app_title TEXT,
            PRIMARY KEY (datum, app_class)
        )"""
    )
    conn.execute(
        """CREATE TABLE IF NOT EXISTS focus_minutes (
            datum TEXT NOT NULL,
            minute_idx INTEGER NOT NULL,
            app_class TEXT NOT NULL,
            seconds INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY (datum, minute_idx, app_class)
        )"""
    )
    return conn


def iso(d):
    return d.strftime("%Y-%m-%d")


def _parse_date(s):
    return datetime.date.fromisoformat(s)


def week_bounds(d):
    monday = d - datetime.timedelta(days=d.weekday())
    sunday = monday + datetime.timedelta(days=6)
    return monday, sunday


def _day_total(conn, date_str, app_filter=None):
    if app_filter:
        row = conn.execute(
            "SELECT COALESCE(SUM(seconds),0) FROM focus_log WHERE datum=? AND app_class=?",
            (date_str, app_filter),
        ).fetchone()
    else:
        row = conn.execute(
            "SELECT COALESCE(SUM(seconds),0) FROM focus_log WHERE datum=?", (date_str,)
        ).fetchone()
    return int(row[0] or 0)


def _apps_for_range(conn, start_str, end_str):
    rows = conn.execute(
        """SELECT app_class, SUM(seconds) FROM focus_log
           WHERE datum BETWEEN ? AND ? GROUP BY app_class ORDER BY SUM(seconds) DESC""",
        (start_str, end_str),
    ).fetchall()
    total = sum(r[1] for r in rows) or 1
    out = []
    for app_class, seconds in rows:
        name, icon = resolve_app_info(app_class)
        out.append(
            {
                "class": app_class,
                "name": name,
                "icon": icon,
                "seconds": int(seconds),
                "percent": round(seconds * 100.0 / total, 1),
            }
        )
    return out


def _hourly_buckets(conn, date_str, app_filter=None, buckets=48):
    per_bucket = [0] * buckets
    bucket_minutes = 1440 // buckets
    if app_filter:
        rows = conn.execute(
            "SELECT minute_idx, SUM(seconds) FROM focus_minutes WHERE datum=? AND app_class=? GROUP BY minute_idx",
            (date_str, app_filter),
        ).fetchall()
    else:
        rows = conn.execute(
            "SELECT minute_idx, SUM(seconds) FROM focus_minutes WHERE datum=? GROUP BY minute_idx",
            (date_str,),
        ).fetchall()
    for minute_idx, seconds in rows:
        b = min(buckets - 1, minute_idx // bucket_minutes)
        per_bucket[b] += int(seconds)
    return per_bucket


def _week_heatmap(conn, monday, sunday):
    grid = [[0] * 24 for _ in range(7)]
    d = monday
    idx = 0
    while d <= sunday:
        rows = conn.execute(
            "SELECT minute_idx, SUM(seconds) FROM focus_minutes WHERE datum=? GROUP BY minute_idx",
            (iso(d),),
        ).fetchall()
        for minute_idx, seconds in rows:
            hour = min(23, minute_idx // 60)
            grid[idx][hour] += int(seconds)
        d += datetime.timedelta(days=1)
        idx += 1
    return grid


def _month_grid(conn, d):
    first = d.replace(day=1)
    if first.month == 12:
        next_month = first.replace(year=first.year + 1, month=1)
    else:
        next_month = first.replace(month=first.month + 1)
    last = next_month - datetime.timedelta(days=1)

    lead_pad = first.weekday()
    result = [{"total": -1} for _ in range(lead_pad)]

    cur = first
    while cur <= last:
        date_str = iso(cur)
        result.append({"date": date_str, "total": _day_total(conn, date_str)})
        cur += datetime.timedelta(days=1)
    return result


def _peak_usage_str(heatmap):
    hour_totals = [0] * 24
    for day in heatmap:
        for h in range(24):
            hour_totals[h] += day[h]
    peak_hour = max(range(24), key=lambda h: hour_totals[h])
    if hour_totals[peak_hour] <= 0:
        return "–"
    return f"{peak_hour:02d}:00–{(peak_hour + 1) % 24:02d}:00"


def _fmt_week_range(monday, sunday):
    return f"{monday.day}.–{sunday.day}. {sunday.strftime('%b')}"


def compute_stats(db_path, date_str, app_filter=None, current_app=None):
    conn = connect(db_path)
    try:
        d = _parse_date(date_str)
        monday, sunday = week_bounds(d)

        total = _day_total(conn, date_str, app_filter)
        yesterday = _day_total(conn, iso(d - datetime.timedelta(days=1)), app_filter)

        days_elapsed = (d - monday).days + 1
        week_to_date_total = 0
        cur = monday
        while cur <= d:
            week_to_date_total += _day_total(conn, iso(cur))
            cur += datetime.timedelta(days=1)
        average = int(week_to_date_total / days_elapsed) if days_elapsed > 0 else 0

        apps = _apps_for_range(conn, date_str, date_str)
        week_apps = _apps_for_range(conn, iso(monday), iso(sunday))

        week = []
        cur = monday
        for name in DAY_NAMES_DE:
            date_iso = iso(cur)
            week.append(
                {
                    "date": date_iso,
                    "day": name,
                    "total": _day_total(conn, date_iso),
                    "is_target": date_iso == date_str,
                }
            )
            cur += datetime.timedelta(days=1)

        month = _month_grid(conn, d)
        hourly = _hourly_buckets(conn, date_str, app_filter)
        heatmap = _week_heatmap(conn, monday, sunday)
        peak = _peak_usage_str(heatmap)

        return {
            "selected_date": date_str,
            "total": total,
            "average": average,
            "week_range": _fmt_week_range(monday, sunday),
            "yesterday": yesterday,
            "current": current_app or "",
            "apps": apps,
            "week_apps": week_apps,
            "week": week,
            "month": month,
            "hourly": hourly,
            "week_heatmap": heatmap,
            "peak_usage_str": peak,
        }
    finally:
        conn.close()
