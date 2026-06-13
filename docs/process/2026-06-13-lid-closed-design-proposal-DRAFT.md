# Lid-Closed Awake Mode — Design Proposal (DRAFT, pending approval)

> **Status: NOT approved. HARD GATE — no implementation code, no spec, until the
> user approves this design.** This file exists so the proposal survives a
> device/session handoff; it was originally presented only in conversation
> (2026-06-12). Once approved, the formal spec goes to
> `docs/superpowers/specs/` per the process map
> (`docs/process/2026-06-12-dev-process-map.md`).

## Problem

BotAwake's current modes wrap `caffeinate`, which **cannot** override lid-closed
sleep. Closing the MacBook (especially on battery, away from a desk) drops the
Lark bot bridge's WebSocket — the exact scenario the user wants to survive:
*close the lid, bot keeps working*.

## Mechanism (fact-checked 2026-06-12)

- The only software path past lid-closed sleep is the kernel `SleepDisabled`
  flag: `sudo pmset -a disablesleep 1` / `... 0`.
- Works **on battery too** (verified, incl. macOS 26.x success reports).
- Amphetamine and Sleepless use this same mechanism.
- The flag is semi-documented (current `man pmset` no longer lists it) — hence
  a 5-minute real-machine PoC is required before shipping (stage 4).

## Proposed design

1. **New mode, existing skeleton.** Add a `lidClosed` case to the existing
   `Mode` enum in `Sources/main.swift`. No new processes or daemons.
2. **Reuse the 15s reconcile loop** (the one "Awake on power only" already uses
   to poll `pmset -g batt`) to enforce the battery floor while in `lidClosed`.
3. **Root via sudoers whitelist.** `install.sh` gains a step that writes
   `/etc/sudoers.d/botawake` allowing exactly **two** precise commands,
   NOPASSWD: `pmset -a disablesleep 1` and `pmset -a disablesleep 0`. Rationale:
   the unattended fallback (battery floor) must work without a password prompt;
   whitelist keeps the surface minimal. `uninstall.sh` removes the file.
4. **Battery protection floor.** Submenu choices 10% / 20% / 30%. Below the
   floor → forced revert to Normal (`disablesleep 0`) + a system notification.
5. **Three forced-fallback points** running `disablesleep 0` (flag persists
   across crashes; a leak means the Mac never sleeps again):
   - switching away from `lidClosed` to any other mode;
   - app quit;
   - app launch (crash recovery: if the flag is set at startup, clear it).
6. **Network-dependency reminder** in the menu: this mode only keeps the Mac
   *awake*; away from home it still needs Wi-Fi/hotspot — no network means the
   bot is unreachable. Boundary, not a bug.

## Locked decisions (do not re-litigate)

See "已锁定的设计决策" in `docs/process/2026-06-12-dev-process-map.md`:
mechanism = `pmset disablesleep`; root = sudoers two-command whitelist;
battery floor = 10/20/30% submenu; three-point fallback; network boundary =
menu reminder; license stays MIT.

## Next actions (in order)

1. Re-present this proposal to the user → **get approval** (the gate).
2. Stage 4 PoC: real machine, 5 min — `disablesleep 1` → close lid → send
   prompt from phone via Lark → bot answers → restore.
3. Stage 5 spec into `docs/superpowers/specs/`, then plan, then code.

## Hardware alternative (rejected for this project, noted for users)

HDMI dummy plug + AC power = Apple's official clamshell path, no root needed.
