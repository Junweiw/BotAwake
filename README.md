# BotAwake ☕

<div align="center">

[🇬🇧 English](#english) · [🇨🇳 中文](#中文)

</div>

---

## English

A tiny macOS **menu-bar switch** that prevents idle sleep so chat bots, sync daemons, and
long-running listeners stay reachable. One click to enable, one click to disable.

No third-party dependencies. Just a thin wrapper around Apple's built-in `caffeinate` and `pmset`.

> **Origin story:** Built to solve a specific annoyance — a Feishu/Lark bot whose background
> listener went silent whenever the Mac dozed off, and only replied once the machine woke again.

![BotAwake demo](docs/demo.gif)

### Features

The menu-bar cup icon is **filled** when a keep-awake mode is active, **empty** when the
Mac is free to sleep. Click it to choose a mode:

![BotAwake menu](docs/menu.png)

#### Modes

| Mode | What it does | Battery |
|------|-------------|---------|
| **Normal (allow sleep)** | Factory behavior — Mac sleeps when idle. | Best |
| **Stay awake** | Mac stays awake; screen can sleep & lock; **lid must stay open**. | High |
| **Awake on power only** | Auto-pauses on battery, resumes when plugged in. ★ Default. | None — never drains battery |
| **Awake for a set time** | 1h / 4h, then auto-returns to Normal. | Limited |
| **Stay awake with lid closed** | Uses `pmset disablesleep` — lid can close. Battery floor protection (10/20/30%). | Medium |
| **Keep screen on too** | Display stays lit, no lock. Demos only. | Highest |

#### Lid-closed Mode

The **"Stay awake with lid closed"** option uses `pmset -a disablesleep 1` to prevent macOS
from sleeping when the lid is closed — even on battery. Three battery floor levels (10/20/30%)
provide safety: if battery drops below the floor, the mode auto-disengages.

> **One-time setup:** The first time you select this mode, macOS will show a standard
> authentication dialog asking for your admin password. This creates a sudoers whitelist
> at `/etc/sudoers.d/botawake` so the app can run `sudo pmset disablesleep` without
> prompting again. No Terminal commands needed.

**Safety features:**
- **Mode switch:** Switching away from lid-closed mode clears `disablesleep` immediately
- **Quit:** Quitting BotAwake clears `disablesleep`
- **Crash recovery:** If the app crashes or is force-killed while `disablesleep` is on, it
  detects and clears the flag on next launch

#### Important Rules

- **Screen off / locked ≠ asleep.** Keeping the Mac awake still lets the display turn off
  and the screen lock. Underneath, the Mac keeps running, so the bot stays reachable.
- **Closing the lid = sleep** in all normal modes — use **lid-closed mode** to override.
- **Clamshell mode** (lid closed, power + external display) works with any keep-awake mode.
- **Privacy in clamshell:** macOS shows your **unlocked desktop** on the external monitor.
  Press <kbd>⌃</kbd><kbd>⌘</kbd><kbd>Q</kbd> to lock — the bot stays reachable while locked.

#### Reachability at a Glance

| Situation | Bot reachable? |
|-----------|----------------|
| Lid open, screen off / locked, keep-awake on | ✅ |
| Lid closed, power + external display (clamshell) | ✅ |
| Lid closed, power only, no display | ❌ sleeps |
| Lid closed, on battery | ❌ sleeps |
| Lid closed + lid-closed mode | ✅ |

### Requirements

- **macOS 14 (Sonoma)** or later — uses menu-item subtitles and SF Symbols
- **Xcode command-line tools** (`swiftc`). Install with `xcode-select --install`.

> **macOS only.** Built on Apple frameworks (`Cocoa` / `AppKit`, `caffeinate`, `pmset`, `launchd`).
> Does not run on Windows or Linux.

### Install

```bash
git clone https://github.com/Junweiw/BotAwake.git
cd BotAwake
chmod +x build.sh install.sh uninstall.sh
./install.sh
```

This builds `BotAwake.app`, copies it to `~/Applications`, and registers a login agent so
the cup icon returns automatically each time you log in. It starts in **Normal** mode (safe default).

#### Build Only (No Install)

```bash
./build.sh          # produces dist/BotAwake.app
open dist/BotAwake.app
```

#### Uninstall

```bash
./uninstall.sh
```

Your system sleep settings are never modified, so there is nothing else to undo.

#### Agent Install

> For AI agents, automation scripts, or any non-interactive environment. `install.sh`
> calls `sudo` directly which requires a TTY and password prompt — agents need a
> different approach for the lid-closed sudoers setup.

**Step 1 — Create the sudoers whitelist via native auth dialog (osascript):**

```bash
osascript -e 'do shell script "
echo \"# BotAwake: allow NOPASSWD pmset disablesleep for lid-closed mode\" > /etc/sudoers.d/botawake
echo \"Cmnd_Alias BOTAWAKE = /usr/bin/pmset -a disablesleep 1, /usr/bin/pmset -a disablesleep 0\" >> /etc/sudoers.d/botawake
echo \"ALL ALL=(ALL) NOPASSWD: BOTAWAKE\" >> /etc/sudoers.d/botawake
chmod 0440 /etc/sudoers.d/botawake
" with administrator privileges with prompt "BotAwake needs to create a sudoers whitelist for lid-closed awake mode."'
```

This triggers the standard macOS authentication dialog — no Terminal interaction needed.

**Step 2 — Run the install script (sudo part will be skipped):**

```bash
./install.sh
```

If your agent cannot trigger GUI dialogs, skip Step 1 and rely on the app to prompt
the user the first time they select lid-closed mode from the menu.

### How It Works

BotAwake never changes your system power settings. Each mode simply launches (or stops)
a background process with the right flags:

| Mode | Mechanism |
|------|-----------|
| Stay awake / Power only / Timed | `caffeinate -i -m -s` — prevents idle **system** sleep; display is free to sleep and lock |
| Keep screen on too | adds `-d` — also prevents display sleep |
| Power only | polls `pmset -g batt`, keeps caffeinate running only on AC |
| Timed | adds `-t <seconds>`; auto-returns to Normal when timer ends |
| Lid closed | `pmset -a disablesleep 1` via sudo (whitelisted in sudoers) — works with lid closed |

Quitting BotAwake (or choosing **Normal**) stops the process immediately — the Mac is free to sleep again.

### License

MIT — see [LICENSE](LICENSE).

[⬆ Back to top](#botawake-)

---

## 中文

一款极简的 macOS **菜单栏开关**，防止 Mac 空闲休眠，让聊天机器人、同步守护进程、长时间运行的监听器始终在线。
一键开启，一键关闭。

无第三方依赖，仅封装了 Apple 内置的 `caffeinate` 和 `pmset`。

> **诞生故事：** 为了解决一个具体痛点——飞书机器人在 Mac 休眠后静默无响应，只有唤醒机器后才回复消息。

![BotAwake 演示](docs/demo.gif)

### 功能

菜单栏茶杯图标 **实心** = 保持唤醒中，**空心** = Mac 可正常休眠。点击选择模式：

![BotAwake 菜单](docs/menu.png)

#### 模式一览

| 模式 | 行为 | 电池 |
|------|------|------|
| **Normal（允许休眠）** | 默认行为，Mac 空闲时自动休眠 | 最佳 |
| **保持唤醒（Stay awake）** | Mac 保持唤醒；屏幕可关闭锁定；**必须开盖** | 较高 |
| **仅电源下唤醒（Awake on power only）** | 使用电池时自动暂停，接通电源时恢复。★ 推荐默认 | 不耗电 |
| **定时唤醒（Awake for a set time）** | 保持唤醒 1 小时或 4 小时，到期自动恢复 Normal | 有限 |
| **合盖唤醒（Stay awake with lid closed）** | 使用 `pmset disablesleep`，可合盖运行。电池电量底线保护 (10/20/30%) | 中等 |
| **屏幕常亮（Keep screen on too）** | 显示器保持点亮，不锁定。仅限演示 | 最高 |

#### 合盖模式

**"Stay awake with lid closed"（合盖唤醒）** 使用 `pmset -a disablesleep 1` 阻止 macOS
在合盖时休眠——即使使用电池也有效。三种电池电量底线（10/20/30%）提供安全保护：
当电量低于设定值时，模式自动解除。

> **一次性设置：** 首次选择此模式时，macOS 会弹出标准认证对话框，要求输入管理员密码。
> 这会在 `/etc/sudoers.d/botawake` 创建一个 sudoers 白名单，此后应用即可免密执行
> `sudo pmset disablesleep`。无需终端操作。

**安全机制：**
- **切换模式：** 切换离开合盖模式时，立即清除 `disablesleep` 标志
- **退出：** 退出 BotAwake 时清除 `disablesleep`
- **崩溃恢复：** 如果应用在 `disablesleep` 开启时崩溃或被强制退出，下次启动时会检测并清除该标志

#### 重要规则

- **屏幕关闭/锁定 ≠ 休眠。** Mac 仍在运行，机器人始终可达。
- **合盖 = 休眠**（普通模式下）——使用**合盖唤醒模式**可覆盖。
- **翻盖模式**（合盖 + 外接电源 + 外接显示器）在任意保持唤醒模式下均可工作。
- **隐私提醒：** 翻盖模式下，macOS 会在外接显示器上显示**未锁定的桌面**。
  按 <kbd>⌃</kbd><kbd>⌘</kbd><kbd>Q</kbd> 锁定——机器人锁定状态下仍可达。

#### 可达性速查

| 场景 | 机器人可达？ |
|------|------------|
| 开盖，屏幕关闭/锁定，保持唤醒中 | ✅ |
| 合盖 + 外接电源 + 外接显示器（翻盖模式） | ✅ |
| 合盖 + 仅外接电源（无显示器） | ❌ 休眠 |
| 合盖 + 电池供电 | ❌ 休眠 |
| 合盖 + 合盖唤醒模式 | ✅ |

### 系统要求

- **macOS 14 (Sonoma)** 或更高版本——使用菜单项副标题和 SF Symbols
- **Xcode 命令行工具**（`swiftc`）。运行 `xcode-select --install` 安装

> **仅限 macOS。** 基于 Apple 框架构建（`Cocoa` / `AppKit`、`caffeinate`、`pmset`、`launchd`）。
> 不支持 Windows 或 Linux。

### 安装

```bash
git clone https://github.com/Junweiw/BotAwake.git
cd BotAwake
chmod +x build.sh install.sh uninstall.sh
./install.sh
```

安装脚本会编译 `BotAwake.app`，复制到 `~/Applications`，并注册登录启动项，每次登录时茶杯图标自动出现。
启动后默认为 **Normal** 模式（安全默认值）。

#### 仅编译（不安装）

```bash
./build.sh          # 生成 dist/BotAwake.app
open dist/BotAwake.app
```

#### 卸载

```bash
./uninstall.sh
```

系统休眠设置不会被修改，无需额外清理。

#### 自动化安装（面向 AI 代理）

> 适用于 AI 代理、自动化脚本等非交互式环境。`install.sh` 中的 `sudo` 需要终端交互输入密码，
> 自动化工具需改用以下方式。

**步骤 1 — 通过系统认证对话框创建 sudoers 白名单：**

```bash
osascript -e 'do shell script "
echo \"# BotAwake: allow NOPASSWD pmset disablesleep for lid-closed mode\" > /etc/sudoers.d/botawake
echo \"Cmnd_Alias BOTAWAKE = /usr/bin/pmset -a disablesleep 1, /usr/bin/pmset -a disablesleep 0\" >> /etc/sudoers.d/botawake
echo \"ALL ALL=(ALL) NOPASSWD: BOTAWAKE\" >> /etc/sudoers.d/botawake
chmod 0440 /etc/sudoers.d/botawake
" with administrator privileges with prompt "BotAwake needs to create a sudoers whitelist for lid-closed awake mode."'
```

此命令会触发 macOS 标准认证对话框，无需终端交互。

**步骤 2 — 运行安装脚本（sudoers 部分会自动跳过）：**

```bash
./install.sh
```

如果代理无法触发 GUI 对话框，可跳过步骤 1，应用会在用户首次选择合盖模式时自动弹出认证对话框。

### 原理

BotAwake 不修改系统电源设置。每种模式只是启动或停止后台进程：

| 模式 | 机制 |
|------|------|
| 保持唤醒 / 仅电源 / 定时 | `caffeinate -i -m -s` — 阻止空闲**系统**休眠；显示器可正常关闭锁定 |
| 屏幕常亮 | 增加 `-d` — 同时阻止显示器休眠 |
| 仅电源 | 轮询 `pmset -g batt`，仅在接通电源时运行 caffeinate |
| 定时 | 增加 `-t <秒>`；计时结束自动返回 Normal |
| 合盖唤醒 | 通过 sudo 执行 `pmset -a disablesleep 1`（sudoers 白名单）——合盖有效 |

退出 BotAwake（或选择 **Normal**）会立即停止进程，Mac 恢复正常休眠。

### 许可证

MIT — 详见 [LICENSE](LICENSE)。

[⬆ 返回顶部](#botawake-)
