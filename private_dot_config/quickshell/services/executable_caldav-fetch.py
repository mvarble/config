#!/usr/bin/env python3
"""Read-only CalDAV fetcher for the Quickshell calendar panel.

Fetches events from a Fastmail (or any CalDAV) account, expands recurring
events within a time window around today, and prints them as a JSON array
on stdout. It never writes anything to the server.

Credentials (a JSON blob {"url", "user", "password"}) are looked up in this
order:
  1. Secret Service: secret-tool lookup service quickshell-calendar
  2. ~/.local/state/quickshell/caldav-credentials.json (keep chmod 600)

Fastmail setup (app password with CalDAV access):
  secret-tool store --label="Quickshell calendar" service quickshell-calendar
  # then paste:
  # {"url":"https://caldav.fastmail.com/dav/","user":"you@fastmail.com","password":"<app password>"}
"""

import argparse
import json
import subprocess
import sys
from datetime import datetime, timedelta
from pathlib import Path

import caldav
import recurring_ical_events
import tzlocal
from icalendar import Calendar as ICal

CREDS_FILE = Path.home() / ".local/state/quickshell/caldav-credentials.json"


def load_credentials():
    """Return {"url", "user", "password"} from the wallet or the fallback file."""
    try:
        out = subprocess.run(
            ["secret-tool", "lookup", "service", "quickshell-calendar"],
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        )
        if out.returncode == 0 and out.stdout.strip():
            return json.loads(out.stdout)
    except (OSError, subprocess.SubprocessError, json.JSONDecodeError):
        pass
    try:
        return json.loads(CREDS_FILE.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        pass
    sys.exit(
        "caldav-fetch: no credentials found. Store them with:\n"
        '  secret-tool store --label="Quickshell calendar" service quickshell-calendar\n'
        f"(or create {CREDS_FILE}, chmod 600)"
    )


def to_local_ms(value, local_tz):
    """Convert an icalendar date/datetime to (epoch ms, all_day) in local time."""
    if isinstance(value, datetime):
        dt = value if value.tzinfo else value.replace(tzinfo=local_tz)
        return int(dt.astimezone(local_tz).timestamp() * 1000), False
    # Plain date: interpret as local midnight, no timezone shift.
    d = datetime(value.year, value.month, value.day, tzinfo=local_tz)
    return int(d.timestamp() * 1000), True


def events_from_ics(ics_text, calendar_name, window_start, window_end, local_tz):
    """Expand one VCALENDAR (one event UID, possibly recurring) into dicts."""
    out = []
    cal = ICal.from_ical(ics_text)
    for vev in recurring_ical_events.of(cal).between(window_start, window_end):
        start_raw = vev.decoded("DTSTART")
        start_ms, all_day = to_local_ms(start_raw, local_tz)
        if "DTEND" in vev:
            end_ms, _ = to_local_ms(vev.decoded("DTEND"), local_tz)
        elif "DURATION" in vev:
            end_ms, _ = to_local_ms(start_raw + vev.decoded("DURATION"), local_tz)
        else:
            end_ms = start_ms + (86400000 if all_day else 3600000)
        out.append(
            {
                "uid": str(vev.get("UID", "")),
                "summary": str(vev.get("SUMMARY", "(no title)")),
                "start": start_ms,
                "end": end_ms,
                "allDay": all_day,
                "location": str(vev.get("LOCATION", "") or ""),
                "calendar": calendar_name,
            }
        )
    return out


def main():
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    ap.add_argument(
        "--calendars",
        default="",
        metavar="NAMES",
        help="comma-separated calendar display names to include (default: all)",
    )
    ap.add_argument(
        "--past-days",
        type=int,
        default=62,
        help="how many days before today to fetch (default: 62)",
    )
    ap.add_argument(
        "--future-days",
        type=int,
        default=186,
        help="how many days ahead of today to fetch (default: 186)",
    )
    args = ap.parse_args()

    creds = load_credentials()

    local_tz = tzlocal.get_localzone()
    now = datetime.now(local_tz)
    window_start = now - timedelta(days=args.past_days)
    window_end = now + timedelta(days=args.future_days)

    try:
        client = caldav.DAVClient(
            url=creds["url"], username=creds["user"], password=creds["password"]
        )
        calendars = client.principal().calendars()
    except Exception as e:
        sys.exit(f"caldav-fetch: connection failed:\n{e}")

    wanted = {n.strip().lower() for n in args.calendars.split(",") if n.strip()}

    events = []
    for cal in calendars:
        name = str(cal.name or "Calendar")
        if wanted and name.lower() not in wanted:
            continue
        try:
            ics_objects = cal.events()
        except Exception as e:
            print(f"caldav-fetch: cannot list events of {name!r}: {e}", file=sys.stderr)
            continue
        for obj in ics_objects:
            try:
                events.extend(
                    events_from_ics(obj.data, name, window_start, window_end, local_tz)
                )
            except Exception as e:
                print(
                    f"caldav-fetch: skipping broken event in {name!r}: {e}",
                    file=sys.stderr,
                )

    events.sort(key=lambda e: (e["start"], e["summary"]))
    json.dump(events, sys.stdout)


if __name__ == "__main__":
    main()
