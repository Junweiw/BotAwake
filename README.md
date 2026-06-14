# BotAwake ☕

> Keep your Mac awake — background services stay alive while the screen sleeps and locks.
> 保持 Mac 唤醒——屏幕可正常关闭和锁定，后台服务始终在线。

A tiny macOS **menu-bar switch** that prevents idle sleep so chat bots, sync daemons, and
long-running listeners stay reachable. One click to enable, one click to disable.

No third-party dependencies. Just a thin wrapper around Apple's built-in `caffeinate` and `pmset`.

> **Origin story:** Built to solve a specific annoyance — a Feishu/Lark bot whose background
> listener went silent whenever the Mac dozed off, and only replied once the machine woke again.

![BotAwake demo](docs/demo.gif)

---

## 功能 / Features

The menu-bar cup icon is **filled** when a keep-awake mode is active, **empty** when the
Mac is free to sleep. Click it to choose a mode:

菜单栏茶杯图标 **实心** = 保持唤醒中，**空心** = Mac 可正常休眠。点击选择模式：

![BotAwake menu](docs/menu.png)

### 模式一览 / Modes

| Mode 模式 | What it does 行为 | Battery 电池 |
|-----------|-------------------|--------------|
| **Normal (allow sleep)** / 正常（允许休眠） | Factory behavior — Mac sleeps when idle. | Best 最佳 |
| **Stay awake** / 保持唤醒 | Mac stays awake; screen can sleep & lock; **lid must stay open**. | High 较高 |
| **Awake on power only** / 仅电源下唤醒 | Auto-pauses on battery, resumes when plugged in. ★ Default. | None — 不耗电 |
| **Awake for a set time** / 定时唤醒 | 1h / 4h, then auto-returns to Normal. | Limited 有限 |
| **Stay awake with lid closed** / 合盖唤醒 | Uses `pmset disablesleep` — lid can close. Battery floor protection (10/20/30%). | Medium 中等 |
| **Keep screen on too** / 屏幕常亮 | Display stays lit, no lock. Demos only. | Highest 最高 |

### 合盖模式 / Lid-closed Mode

The **"Stay awake with lid closed"** option uses `pmset -a disablesleep 1` to prevent macOS
from sleeping when the lid is closed — even on battery. Three battery floor levels (10/20/30%)
provide safety: if battery drops below the floor, the mode auto-disengages.

> **One-time setup:** The first time you select this mode, macOS will show a standard
> authentication dialog asking for your admin password. This creates a sudoers whitelist
> at `/etc/sudoers.d/botawake` so the app can run `sudo pmset disablesleep` without
> prompting again. No Terminal commands needed.

**安全机制 / Safety features:**
- **Mode switch:** Switching away from lid-closed mode clears `disablesleep` immediately
- **Quit:** Quitting BotAwake clears `disablesleep`
- **Crash recovery:** If the app crashes or is force-killed while `disablesleep` is on, it
  detects and clears the flag on next launch

### 重要规则 / Important Rules

| 规则 Rule | 详情 Detail |
|-----------|------------|
| 屏幕关闭 ≠ 休眠 | Screen off/locked ≠ asleep. The Mac keeps running underneath; the bot stays reachable. |
| 合盖 = 休眠 | Closing the lid = sleep in all normal modes — use **lid-closed mode** to override. |
| 合盖 + 外接显示器 | Clamshell mode (lid closed, power + external display) works with any keep-awake mode. |

### 可达性速查 / Reachability at a Glance

| 场景 Situation | Bot reachable? 机器人可达？ |
|---------------|----------------------------|
| 开盖、屏幕关闭/锁定、保持唤醒中 | ✅ |
| Lid open, screen off/locked, keep-awake on | ✅ |
| 合盖、外接电源 + 外接显示器（翻盖模式） | ✅ |
| Lid closed, power + external display (clamshell) | ✅ |
| 合盖、仅外接电源（无显示器） | ❌ 休眠 |
| Lid closed, power only (no display) | ❌ 休眠 |
| 合盖、仅电池 | ❌ 休眠 |
| Lid closed, on battery | ❌ 休眠 |
| 合盖 + 合盖唤醒模式 | ✅ |
| Lid closed + lid-closed mode | ✅ |

---

## 系统要求 / Requirements

- **macOS 14 (Sonoma)** or later — uses menu-item subtitles and SF Symbols
- **Xcode command-line tools** (`swiftc`). Install with `xcode-select --install`.

> **macOS only.** Built on Apple frameworks (`Cocoa` / `AppKit`, `caffeinate`, `pmset`, `launchd`).
> Does not run on Windows or Linux.

---

## 安装 / Install

```bash
git clone https://github.com/Junweiw/BotAwake.git
cd BotAwake
chmod +x build.sh install.sh uninstall.sh
./install.sh
```

This builds `BotAwake.app`, copies it to `~/Applications`, and registers a login agent so
the cup icon returns automatically each time you log in. It starts in **Normal** mode (safe default).

安装脚本会编译 `BotAwake.app`，复制到 `~/Applications`，并注册登录启动项。每次登录茶杯图标自动出现。

### 仅编译 / Build Only (No Install)

```bash
./build.sh          # produces dist/BotAwake.app
open dist/BotAwake.app
```

### 卸载 / Uninstall

```bash
./uninstall.sh
```

Your system sleep settings are never modified, so there is nothing else to undo.
系统休眠设置不会被修改，无需额外清理。

---

## 原理 / How It Works

BotAwake never changes your system power settings. Each mode simply launches (or stops)
a background process with the right flags:

BotAwake 不修改系统电源设置。每种模式只是启动或停止后台进程：

| Mode 模式 | Mechanism 机制 |
|-----------|---------------|
| Stay awake / Power only / Timed 保持唤醒/仅电源/定时 | `caffeinate -i -m -s` — prevents idle **system** sleep; display is free to sleep and lock |
| Keep screen on too 屏幕常亮 | adds `-d` — also prevents display sleep |
| Power only 仅电源 | polls `pmset -g batt`, keeps caffeinate running only on AC |
| Timed 定时 | adds `-t <seconds>`; auto-returns to Normal when timer ends |
| Lid closed 合盖唤醒 | `pmset -a disablesleep 1` via sudo (whitelisted in sudoers) — works with lid closed |

Quitting BotAwake (or choosing **Normal**) stops the process immediately — the Mac is free to sleep again.

---

## License 许可证

MIT — see [LICENSE](LICENSE).
