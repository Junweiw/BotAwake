# BotAwake ☕

A tiny macOS **menu-bar switch** that keeps your Mac awake so background services
(chat bots, sync daemons, long-running listeners) stay reachable — **while still
letting the screen sleep and lock**.

It was built to solve a specific annoyance: a Lark/Feishu bot whose background
listener went silent whenever the Mac dozed off, and only replied once the
machine was woken again. BotAwake fixes that with one click — and reminds you of
the lid/power/privacy rules right in the menu so you always know what to expect.

No third-party dependencies. Just a thin, friendly wrapper around the built-in
`caffeinate` tool.

---

## What it does

The menu-bar cup icon is filled when a keep-awake mode is active and empty when
the Mac is free to sleep. Click it to choose a mode:

| Mode | What it does | Battery |
|------|--------------|---------|
| **Normal (allow sleep)** | Factory behavior — Mac sleeps when idle. Bot only reachable while you're using the Mac. | Best |
| **Stay awake** | Mac stays awake; screen can sleep & lock; **lid must stay open**. | High |
| **Awake on power only** | Like *Stay awake*, but auto-pauses on battery and resumes when plugged in. *(Recommended default.)* | None — never drains battery |
| **Awake for a set time** | Stays awake for 1h / 4h, then auto-returns to Normal. | Limited |
| **Keep screen on too** | Display also stays lit (no lock). Demos only. | Highest |

### The important rules (also shown inside the menu)

- **Screen off / locked ≠ asleep.** Keeping the Mac awake still lets the display
  turn off and the screen lock. Underneath, the Mac keeps running, so the bot
  stays reachable. Locking does **not** stop the bot.
- **Closing the lid = sleep**, no matter the mode — *unless* the Mac is plugged
  into power **and** connected to an external display (clamshell mode).
- **Privacy in clamshell:** with the lid closed on power + external display,
  macOS shows your **unlocked desktop** on the monitor. Press <kbd>⌃</kbd><kbd>⌘</kbd><kbd>Q</kbd>
  to lock — the bot stays reachable while locked.

### Reachability at a glance

| Situation | Bot reachable? |
|-----------|----------------|
| Lid open, screen off / locked, keep-awake on | ✅ |
| Lid closed, power **+ external display** (clamshell) | ✅ |
| Lid closed, power only (no display) | ❌ sleeps |
| Lid closed, on battery | ❌ sleeps |

---

## Requirements

- macOS 14 (Sonoma) or later — uses menu-item subtitles and SF Symbols.
- Xcode command-line tools (`swiftc`). Install with `xcode-select --install`.

> **macOS only.** BotAwake is built on Apple frameworks (`Cocoa` / `AppKit`,
> the `caffeinate` and `pmset` command-line tools, and `launchd`). It does not
> run on Windows or Linux.

---

## Install

```bash
git clone https://github.com/<your-username>/BotAwake.git
cd BotAwake
chmod +x build.sh install.sh uninstall.sh
./install.sh
```

This builds `BotAwake.app`, copies it to `~/Applications`, and registers a login
agent so the cup icon returns automatically each time you log in. It starts in
**Normal** mode (nothing kept awake) — a safe default.

### Build only (no install)

```bash
./build.sh          # produces dist/BotAwake.app
open dist/BotAwake.app
```

### Uninstall

```bash
./uninstall.sh
```

Your system sleep settings are never modified, so there is nothing else to undo.

---

## How it works

BotAwake never changes your system power settings. Each mode simply launches (or
stops) a `caffeinate` process with the right flags:

- **Stay awake / Awake on power only / Timed:** `caffeinate -i -m -s`
  (prevents idle **system** sleep; the display is free to sleep and lock).
- **Keep screen on too:** adds `-d` (also prevents display sleep).
- **Awake on power only:** the app polls the power source (`pmset -g batt`) and
  keeps `caffeinate` running only while on AC.
- **Timed:** adds `-t <seconds>`; when it elapses, the app returns to Normal.

Quitting BotAwake (or choosing **Normal**) stops `caffeinate` immediately and the
Mac is free to sleep again.

---

## License

MIT — see [LICENSE](LICENSE).
