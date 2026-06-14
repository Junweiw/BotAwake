# Handoff — BotAwake

A guide for picking up this project on **any Mac** (not tied to the original machine).

## ⏩ Current work (2026-06): Lid-Closed Awake mode — read this first

A `lidClosed` mode using `pmset disablesleep` so the bot stays reachable with
the lid closed, **even on battery**.

- **State (2026-06-15): SHIPPED.** Implemented in `Sources/main.swift` with
  10/20/30% battery floors, crash recovery, and auto-clear on mode switch/quit.
  The one-time root setup now happens through macOS's **native auth dialog**
  (`osascript … with administrator privileges`, `installSudoers()`) — **no
  Terminal needed**; it writes `/etc/sudoers.d/botawake` once, then toggles are
  password-free. README updated to match.
- **History:** stages 1–2 (fact-check + decisions locked) and the stage-3 design
  proposal are preserved below for context.
- **Resume here:** `docs/process/2026-06-13-lid-closed-design-proposal-DRAFT.md`
  (the proposal to re-present for approval) and
  `docs/process/2026-06-12-dev-process-map.md` (12-stage lifecycle map, locked
  decisions, artifact conventions). Live map mirror: Feishu doc
  `CzBrdlphhohbqgxHhE6c31L5nsY` (check off stages as they complete).
- **Next action:** get design approved → stage 4 PoC (5-min real-machine test)
  → stage 5 spec in `docs/superpowers/specs/`.

## What this is

A macOS menu-bar switch that keeps the Mac awake so background services (chat
bots, sync daemons, long-running listeners) stay reachable — while still letting
the screen sleep and lock. It is a thin wrapper around the built-in `caffeinate`
tool, with no third-party dependencies.

**Origin:** built to fix a Lark/Feishu bot that appeared to go silent unless a
terminal was open. The real cause was the Mac sleeping (on battery, with
wake-on-network off), which drops the bot bridge's WebSocket. BotAwake keeps the
Mac awake on demand so the bridge stays connected.

## Get it running on a new Mac

**Requirements**
- macOS 14 (Sonoma) or later.
- Xcode command-line tools (for `swiftc`): `xcode-select --install`.

**Install**
```bash
git clone https://github.com/Junweiw/BotAwake.git
cd BotAwake
chmod +x build.sh install.sh uninstall.sh
./install.sh
```

`install.sh` builds `BotAwake.app`, copies it to `~/Applications`, and registers
a login agent (`~/Library/LaunchAgents/ai.botawake.app.plist`) so the menu-bar
cup icon returns every login. It starts in **Normal** mode (nothing kept awake).

**Uninstall:** `./uninstall.sh` (removes the app + login agent; system power
settings are never modified, so there is nothing else to undo).

## Repo layout

| Path | What |
|------|------|
| `Sources/main.swift` | The entire app (AppKit menu-bar agent). |
| `Resources/Info.plist` | Bundle metadata; `LSUIElement` (no Dock icon), `CFBundleIconFile`. |
| `Resources/AppIcon.icns` | App icon (cup & saucer). |
| `build.sh` | Builds `dist/BotAwake.app`. |
| `install.sh` / `uninstall.sh` | Install to `~/Applications` + login agent / remove. |
| `docs/` | README assets (menu screenshot, demo GIF). |

> `dist/` is a build artifact (git-ignored). Don't keep it on the Desktop long-term —
> a stray `dist/BotAwake.app` shows up as a duplicate app in Spotlight/Launchpad.

## How it works

- **Modes** map to a `caffeinate` child process:
  - Stay awake / Awake on power only / Timed → `caffeinate -i -m -s`
    (prevents idle **system** sleep; display may sleep & lock).
  - Keep screen on too → adds `-d` (also prevents display sleep).
  - Timed → adds `-t <seconds>`; app returns to Normal when it elapses.
- **Awake on power only** polls `pmset -g batt` every 15s and runs `caffeinate`
  only while on AC.
- The **menu-bar glyph** is an SF Symbol drawn by the app (`cup.and.saucer[.fill]`),
  separate from the bundle's `.icns` (the icon seen in Finder/Launchpad).
- Choosing **Normal** or quitting stops `caffeinate` immediately.

## Reachability rules (important for users)

| Situation | Reachable? |
|-----------|------------|
| Lid open, screen off / locked, a keep-awake mode on | ✅ |
| Lid **closed**, power **+ external display** (clamshell) | ✅ |
| Lid closed, power only (no display) | ❌ sleeps |
| Lid closed, on battery | ❌ sleeps |

A lid-closed **override exists** (`sudo pmset -a disablesleep 1`; works on
battery too). Originally left out (heat risk in a bag; system-wide change), that
decision was **reversed in 2026-06**: it is now being built in as the
`lidClosed` mode with safety fallbacks — see "Current work" at the top.

## Modifying / rebuilding

- Edit `Sources/main.swift`, then `./install.sh` to rebuild + reinstall.
- After changing the icon or bundle, macOS may cache the old icon; log out/in to
  force a refresh.
- The icon was generated from an HTML mockup rendered with headless Chrome, then
  `sips` + `iconutil`. (The README screenshot and demo GIF were produced the same
  way — HTML → headless Chrome → PNG/Pillow GIF — rather than live screen capture,
  because screenshot hotkeys dismiss an open macOS menu.)

## Known caveats

- **Icon cache lag** after reinstall (see above).
- **Clamshell privacy:** lid-closed-on-power shows your *unlocked* desktop on the
  external display; press `⌃⌘Q` to lock (the Mac stays awake, bot stays reachable).
- For true 24/7 reachability with the lid closed and no monitor, host the bridge
  on an always-on machine instead — no local switch can beat the lid-closed sleep rule.

## Optional follow-ups (none blocking)

- Add a repo description + topics on GitHub for discoverability.
- Tag a `v1.0.0` release.
