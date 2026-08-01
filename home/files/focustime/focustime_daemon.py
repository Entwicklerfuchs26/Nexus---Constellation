#!/usr/bin/env python3
"""FocusTime — App-Nutzungs-Tracking-Daemon fuer Hyprland (Nexus Dashboard).

Ermittelt die aktive App im 1s-Takt (Hyprland-socket2 fuer schnelle Reaktion,
`hyprctl activewindow -j` als Poll-Fallback), puffert Sekunden im Speicher und
flusht periodisch in SQLite. Schreibt zusaetzlich eine Live-JSON-Momentaufnahme
fuer die Dashboard-Karte.
"""
import datetime
import json
import os
import signal
import socket
import subprocess
import sys
import threading
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from focustime_stats import compute_stats, connect, iso, resolve_app_info  # noqa: E402

STATE_DIR = os.environ.get("QS_STATE_FOCUSTIME", os.path.expanduser("~/.local/state/focustime"))
RUN_DIR = os.environ.get("QS_RUN_FOCUSTIME", "/tmp/focustime")
DB_PATH = os.path.join(STATE_DIR, "focustime.db")
LIVE_JSON_PATH = os.path.join(RUN_DIR, "live.json")

FLUSH_INTERVAL = 15
LIVE_WRITE_INTERVAL = 5

QUICKSHELL_CLASSES = {"quickshell", "org.quickshell"}


class FocusTimeDaemon:
    def __init__(self):
        os.makedirs(STATE_DIR, exist_ok=True)
        os.makedirs(RUN_DIR, exist_ok=True)
        self.lock = threading.Lock()
        self.buffer = {}  # (datum, minute_idx, app_class) -> seconds
        self.title_cache = {}
        self.current_display = "Desktop"
        self.current_class = ""
        self.running = True
        self._last_flush = time.time()
        self._last_live_write = 0.0
        self._socket_state = {"class": None, "title": None}
        self._socket_lock = threading.Lock()

    def _hyprctl_active_window(self):
        try:
            out = subprocess.run(
                ["hyprctl", "activewindow", "-j"], capture_output=True, text=True, timeout=2
            )
            if out.returncode != 0 or not out.stdout.strip():
                return "", ""
            data = json.loads(out.stdout)
            return data.get("class", "") or "", data.get("title", "") or ""
        except Exception:
            return "", ""

    def _is_locked(self):
        try:
            out = subprocess.run(["pgrep", "-x", "hyprlock"], capture_output=True, timeout=2)
            return out.returncode == 0
        except Exception:
            return False

    def _socket2_path(self):
        sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
        runtime = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
        if not sig:
            return None
        return os.path.join(runtime, "hypr", sig, ".socket2.sock")

    def _socket_reader(self):
        path = self._socket2_path()
        if not path:
            return
        while self.running:
            try:
                with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
                    s.settimeout(5)
                    s.connect(path)
                    s.settimeout(None)
                    buf = b""
                    while self.running:
                        chunk = s.recv(4096)
                        if not chunk:
                            break
                        buf += chunk
                        while b"\n" in buf:
                            line, buf = buf.split(b"\n", 1)
                            self._handle_socket_line(line.decode("utf-8", "ignore"))
            except Exception:
                time.sleep(2)

    def _handle_socket_line(self, line):
        if line.startswith("activewindow>>"):
            payload = line[len("activewindow>>"):]
            cls, _, title = payload.partition(",")
            with self._socket_lock:
                self._socket_state["class"] = cls
                self._socket_state["title"] = title

    def _classify(self):
        if self._is_locked():
            return "Locked", "", ""

        cls, title = None, None
        with self._socket_lock:
            if self._socket_state["class"] is not None:
                cls, title = self._socket_state["class"], self._socket_state["title"]
        if cls is None:
            cls, title = self._hyprctl_active_window()

        cls = (cls or "").strip()
        title = (title or "").strip()

        if not cls:
            return "Desktop", "", ""
        if cls.lower() in QUICKSHELL_CLASSES:
            return "Quickshell", "", ""
        return "app", cls, title

    def tick(self):
        state, cls, title = self._classify()

        if state != "app":
            self.current_display = state
            self.current_class = ""
            return

        name, _icon = resolve_app_info(cls)
        self.current_display = name
        self.current_class = cls
        if title:
            self.title_cache[cls] = title

        now = datetime.datetime.now()
        datum = iso(now.date())
        minute_idx = now.hour * 60 + now.minute

        with self.lock:
            key = (datum, minute_idx, cls)
            self.buffer[key] = self.buffer.get(key, 0) + 1

    def flush(self):
        with self.lock:
            if not self.buffer:
                return
            pending = self.buffer
            self.buffer = {}
            titles = dict(self.title_cache)

        conn = connect(DB_PATH)
        try:
            day_totals = {}
            for (datum, minute_idx, cls), seconds in pending.items():
                conn.execute(
                    """INSERT INTO focus_minutes (datum, minute_idx, app_class, seconds)
                       VALUES (?, ?, ?, ?)
                       ON CONFLICT(datum, minute_idx, app_class)
                       DO UPDATE SET seconds = seconds + excluded.seconds""",
                    (datum, minute_idx, cls, seconds),
                )
                day_totals[(datum, cls)] = day_totals.get((datum, cls), 0) + seconds

            for (datum, cls), seconds in day_totals.items():
                conn.execute(
                    """INSERT INTO focus_log (datum, app_class, seconds, app_title)
                       VALUES (?, ?, ?, ?)
                       ON CONFLICT(datum, app_class)
                       DO UPDATE SET seconds = seconds + excluded.seconds, app_title = excluded.app_title""",
                    (datum, cls, seconds, titles.get(cls, "")),
                )
            conn.commit()
        finally:
            conn.close()

    def _pending_today_by_app(self):
        today = iso(datetime.date.today())
        with self.lock:
            out = {}
            for (datum, _minute_idx, cls), seconds in self.buffer.items():
                if datum == today:
                    out[cls] = out.get(cls, 0) + seconds
            return out

    def write_live_json(self):
        today = iso(datetime.date.today())
        stats = compute_stats(DB_PATH, today, app_filter=None, current_app=self.current_display)

        pending = self._pending_today_by_app()
        if pending:
            extra_total = sum(pending.values())
            stats["total"] += extra_total

            by_class = {a["class"]: a for a in stats["apps"]}
            for cls, seconds in pending.items():
                if cls in by_class:
                    by_class[cls]["seconds"] += seconds
                else:
                    name, icon = resolve_app_info(cls)
                    entry = {"class": cls, "name": name, "icon": icon, "seconds": seconds, "percent": 0}
                    stats["apps"].append(entry)
                    by_class[cls] = entry
            new_total = sum(a["seconds"] for a in stats["apps"]) or 1
            for a in stats["apps"]:
                a["percent"] = round(a["seconds"] * 100.0 / new_total, 1)
            stats["apps"].sort(key=lambda a: a["seconds"], reverse=True)

            now = datetime.datetime.now()
            bucket = min(47, (now.hour * 60 + now.minute) // 30)
            stats["hourly"][bucket] += extra_total

            for w in stats["week"]:
                if w["is_target"]:
                    w["total"] += extra_total
                    break

            for i, w in enumerate(stats["week"]):
                if w["is_target"] and i < len(stats["week_heatmap"]):
                    stats["week_heatmap"][i][now.hour] += extra_total
                    break

            for m in stats["month"]:
                if m.get("date") == today:
                    m["total"] += extra_total
                    break

        tmp_path = LIVE_JSON_PATH + ".tmp"
        with open(tmp_path, "w") as f:
            json.dump(stats, f)
        os.replace(tmp_path, LIVE_JSON_PATH)

    def handle_signal(self, signum, frame):
        self.running = False
        self.flush()
        sys.exit(0)

    def run(self):
        signal.signal(signal.SIGTERM, self.handle_signal)
        signal.signal(signal.SIGINT, self.handle_signal)

        reader = threading.Thread(target=self._socket_reader, daemon=True)
        reader.start()

        next_tick = time.time()
        while self.running:
            self.tick()

            now = time.time()
            if now - self._last_flush >= FLUSH_INTERVAL:
                self.flush()
                self._last_flush = now
            if now - self._last_live_write >= LIVE_WRITE_INTERVAL:
                try:
                    self.write_live_json()
                except Exception as e:
                    print(f"focustime: live json write failed: {e}", file=sys.stderr)
                self._last_live_write = now

            next_tick += 1.0
            sleep_time = next_tick - time.time()
            if sleep_time > 0:
                time.sleep(sleep_time)
            else:
                next_tick = time.time()


if __name__ == "__main__":
    FocusTimeDaemon().run()
