# Changelog

All notable changes to BotAwake are documented here.

## [1.0.1] — 2026-06-19

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

## [1.0.0] — 2026-06-14

### Added

- Menu-bar app with six awake modes: Normal, Stay awake, Awake on power only, Timed,
  Stay awake with lid closed, Keep screen on too.
- Lid-closed mode via `pmset disablesleep` with battery floor (10 / 20 / 30%).
- One-click native macOS admin dialog for sudoers setup (no Terminal).
- Login agent install via `install.sh`; crash recovery on launch.
