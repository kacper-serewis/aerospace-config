# Working on this repository

## This directory is the live config

The repository root is `~/.config/aerospace`, the directory AeroSpace actually
reads. There is no build, no symlink and no install step: editing a file here
edits the running configuration. AeroSpace resolves
`$XDG_CONFIG_HOME/aerospace/aerospace.toml` and falls back to `~/.config` when
that variable is unset, which is the case on this machine.

Two consequences worth keeping in mind:

- A broken commit breaks the window manager, so validate before committing.
- `~/.aerospace.toml` must stay absent. If it comes back it is dead weight that
  the XDG path shadows, and it will confuse the next person who edits it.
- Paths inside `aerospace.toml` are absolute and hardcoded to this user's home
  directory, because AeroSpace does not expand `~` in a `run` command.

## Validating a change

`aerospace reload-config` applies the file and prints parse errors with line
numbers. It is the fastest check and should be run after every edit:

```sh
aerospace reload-config
```

A clean run prints nothing. Do not trust a silent success to mean the config
loaded, though, since AeroSpace falls back to its defaults when parsing fails.
To prove a specific file is the one being read, append a deliberate syntax
error, reload, confirm the reported line number matches, then revert.

## Editing `aerospace.toml`

Rules in `[[on-window-detected]]` are evaluated in order and the first match
wins. The spreading rule at the bottom of the file matches every window, so
anything added below it is dead. New app rules go above it.

The `[workspace-to-monitor-force-assignment]` values are fallback chains rather
than single monitors. That is deliberate: the same file has to work at home
with three external displays and at work with the laptop plus two. Keep the
chains rather than pinning a workspace to one monitor name.

Comments in this file explain why a setting is the way it is, including the
`on-focus-changed` line that is commented out on purpose. Preserve that
reasoning when editing near it, and add the same kind of note for anything
non-obvious.

## Editing `spread-window.sh`

The script runs from an `on-window-detected` callback, which is where
`AEROSPACE_WINDOW_ID` comes from. It is the only way AeroSpace exposes the new
window to an external command, and both `list-windows` and
`move-node-to-monitor` accept that id explicitly.

Counting only covers windows on each monitor's visible workspace, since hidden
workspaces are not competing for screen space. The window being placed is
excluded from the counts because the callback races with AeroSpace's own
placement.

To see what it decides, point `SPREAD_LOG` at a file and every decision is
appended as `win=<id> target=<monitor or none>`:

```sh
SPREAD_LOG=/tmp/spread.log ~/.config/aerospace/spread-window.sh
```

The placement logic lives in a single `awk` program, which is testable without
touching real windows. Feed it synthetic `M|<monitor>` and
`W|<window>|<monitor>|<visible>` lines and check the monitor it prints.

## Testing a placement change for real

`osascript -e 'tell application "TextEdit" to make new document'` reuses an
existing blank window rather than opening a second one, so it cannot fill a
monitor. Open distinct files instead, one per window, and leave a couple of
seconds between them so each callback finishes:

```sh
open -a TextEdit /tmp/a.txt
open -a TextEdit /tmp/b.txt
```

Then read the result with:

```sh
aerospace list-windows --monitor all --format '%{monitor-id} %{window-id} %{app-name}' | sort
```

Close the test windows afterwards.
