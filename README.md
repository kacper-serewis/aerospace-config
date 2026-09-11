# aerospace-config

My [AeroSpace](https://github.com/nikitabobko/AeroSpace) setup for macOS.

This repository *is* `~/.config/aerospace`, which AeroSpace reads directly, so
there is nothing to symlink and no install step. AeroSpace looks for
`$XDG_CONFIG_HOME/aerospace/aerospace.toml` and falls back to `~/.config` when
that variable is unset, which is the case here.

## Contents

| File | Purpose |
| --- | --- |
| `aerospace.toml` | The whole configuration: gaps, monitor assignment, app rules, keybindings. |
| `spread-window.sh` | Places each new window on the least crowded monitor. |

## Layout

Three monitors, with workspaces pinned to them through
`workspace-to-monitor-force-assignment`. The list for each workspace is a
fallback chain, so the same config works at home with three externals and at
work with the laptop plus two externals.

`alt` plus a number summons a workspace to the focused monitor.
`alt-shift` plus that number sends the focused window there instead.
`alt-shift-semicolon` enters service mode for reload, flatten and join.

## Spreading new windows

AeroSpace has no built-in way to place a window based on how full a monitor is,
but `on-window-detected` exports `AEROSPACE_WINDOW_ID` to `exec-and-forget`,
and both `list-windows` and `move-node-to-monitor` accept an explicit window id.
That is enough to decide in a script.

When a new window lands on a monitor that already holds three or more windows,
`spread-window.sh` moves it to the emptiest monitor holding fewer. Ties go to
the lowest monitor id, and the window stays put when every monitor is equally
full. Only windows on each monitor's visible workspace are counted, since
hidden workspaces are not competing for space.

The rule sits last in `aerospace.toml` and the first matching rule wins, so the
apps listed above it as floating are never moved. It is also guarded by
`if.during-aerospace-startup = false`, so reloading the config never reshuffles
an existing layout.

Change the threshold through `LIMIT` in the script. To see what it decides, set
`SPREAD_LOG` to a file path and every decision is appended to it.

The move is issued without any settle delay. When `on-window-detected` fires the
window is already in AeroSpace's tree, so `list-windows` resolves its monitor
straight away; waiting first only makes the window sit visibly on the wrong
monitor for longer before it jumps.

## When tiling feels slow

A new window sitting at its own size for a second or more, or the remaining
window not filling the gap after you close one, is usually AeroSpace itself
rather than this config. The delay grows with how long the process has been
running. Measured on this machine after three and a half days of uptime: a new
window took 2.5-4.5 s to be tiled and 1.6 s to refill after a close. Restarting
AeroSpace brought that back to roughly 0.3-0.5 s and 0.25 s with the same
config.

```sh
killall AeroSpace && open -a AeroSpace
```

Disabling the spreading rule does not change these numbers, so reach for the
restart before suspecting the rule.
