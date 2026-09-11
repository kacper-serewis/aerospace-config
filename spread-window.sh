#!/bin/bash
# Send a freshly detected window to the least crowded monitor.
#
# AeroSpace exports AEROSPACE_WINDOW_ID to exec-and-forget inside an
# on-window-detected callback. Only windows on a monitor's *visible*
# workspace count: those are the ones actually competing for screen space.
#
# Called from ~/.aerospace.toml. Set SPREAD_LIMIT below to taste.

set -u

AERO=/opt/homebrew/bin/aerospace
LIMIT=${SPREAD_LIMIT:-3}
LOG=${SPREAD_LOG:-}

win=${AEROSPACE_WINDOW_ID:-}
[ -n "$win" ] || exit 0

# No wait before reading: by the time on-window-detected fires, the window is
# already in AeroSpace's tree and list-windows resolves its monitor. A settle
# sleep only widens the gap in which you see the window on the wrong monitor
# before it is moved, so the move is issued as soon as the decision is made.

target=$(
  {
    "$AERO" list-monitors --format 'M|%{monitor-id}'
    "$AERO" list-windows --monitor all \
      --format 'W|%{window-id}|%{monitor-id}|%{workspace-is-visible}'
  } | awk -F'|' -v self="$win" -v limit="$LIMIT" '
      $1 == "M" { mon[$2] = 1; count[$2] += 0 }
      $1 == "W" && $2 == self { cur = $3 }
      $1 == "W" && $4 == "true" && $2 != self { count[$3]++ }
      END {
        if (cur == "" || count[cur] < limit) exit
        best = ""; bestc = 0
        for (m in mon) {
          if (count[m] >= limit) continue
          if (best == "" || count[m] < bestc ||
              (count[m] == bestc && m + 0 < best + 0)) { best = m; bestc = count[m] }
        }
        if (best != "" && best != cur) print best
      }
    '
)

[ -n "$LOG" ] && echo "$(date '+%F %T') win=$win target=${target:-none}" >>"$LOG"
[ -n "$target" ] || exit 0

exec "$AERO" move-node-to-monitor --focus-follows-window --window-id "$win" "$target"
