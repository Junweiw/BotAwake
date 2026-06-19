# Changelog

All notable changes to BotAwake are documented here.

## [1.1.1] — 2026-06-19

### Fixed

- **Normal mode now reliably lets the Mac sleep again** after using lid-closed mode.
  Earlier builds looked for `disablesleep 1` in `pmset` output, but macOS reports the
  kernel flag as `SleepDisabled 1`, so crash recovery and mode switching could leave the
  Mac permanently awake even with an empty cup icon.
- Normal mode, quit, and launch now all call `ensureDisableSleepOff()` to clear a stuck
  `SleepDisabled` flag.
- Lid-closed sudo uses `sudo -n` so the menu-bar app fails fast (and notifies) instead of
  hanging when the sudoers whitelist is missing.

### Added

- Notification when BotAwake cannot clear the sleep lock (with manual recovery command).
- README troubleshooting: how to tell BotAwake vs other apps/settings are blocking sleep.
- Menu status shows "clearing sleep lock…" when Normal detects a stuck flag.

## [1.1.0] — 2026-06-14

### Added

- **Stay awake with lid closed** mode via `pmset disablesleep`, with battery floor
  protection (10 / 20 / 30%).
- One-click native macOS admin dialog for sudoers setup (no Terminal).
- Crash recovery, auto-clear on mode switch and quit.
- Updated README screenshots and menu copy for lid-closed mode.

## [1.0.0] — 2026-06-14

### Added

- Menu-bar app with modes: Normal, Stay awake, Awake on power only, Timed, Keep screen on.
- `caffeinate`-based keep-awake with 15s power polling.
- Login agent install via `install.sh`.
