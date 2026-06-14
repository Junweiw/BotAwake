# Lesson — 2026-06-15: Native auth dialog, never "open Terminal"

**Tags:** `auth` · `workflow`

## English

**Challenge.** A macOS menu-bar app needed root (`pmset disablesleep`) for the
keep-awake-with-lid-closed feature. The shipped code handled it by popping an
alert that told users to copy-paste a `sudo` command into Terminal — while the
README already promised a "no Terminal" experience the code didn't deliver.

**Why.** The app is locally built and unsigned, so the proper Apple
privileged-helper route (SMJobBless) wasn't available, and the easy path was to
have the user set up a sudoers rule by hand. That offloads system-level friction
onto the end user and breaks the one-click promise of a menu-bar utility.

**How it was resolved.** Replaced the Terminal-instruction alert with an
`osascript` `do shell script "…" with administrator privileges with prompt "…"`
call (`installSudoers()`), triggering macOS's native Touch ID / password dialog
from inside the app. One approval writes the NOPASSWD sudoers rule once; every
toggle after is instant. Cancel keeps the app in safe (Normal) mode. README and
code were brought back in sync.

**What I learned.** When a desktop app needs a privileged operation, never ship
"open Terminal and paste this" as the UX. Reach for the OS-native auth affordance
(`with administrator privileges` on macOS) so setup is one click — and keep docs
and code telling the **same** story; a README that promises an experience the
code doesn't deliver is a bug.

## 中文

**挑战。** 一个 macOS 菜单栏应用需要 root 权限（`pmset disablesleep`）来实现
"合盖保持唤醒"功能。已发布的代码却弹窗让用户把 `sudo` 命令复制粘贴到终端执行——
而 README 早已承诺"无需终端"，代码与文档自相矛盾。

**为什么。** 该应用本地编译且未签名，无法使用 Apple 正规的特权辅助工具方案
（SMJobBless），于是走了捷径：让用户手动配置 sudoers。这把系统级的设置摩擦甩给了
终端用户，也违背了菜单栏小工具"一键搞定"的初衷。

**如何解决。** 用 `osascript` 的 `do shell script "…" with administrator privileges
with prompt "…"`（`installSudoers()`）替换终端说明弹窗，从应用内部直接触发 macOS
原生的 Touch ID / 密码授权弹窗。批准一次即写入免密 sudoers 规则，此后每次切换都是
即时的；取消则应用安静地留在安全（Normal）模式。同时让 README 与代码重新对齐。

**学到了什么。** 桌面应用需要提权操作时，绝不要把"打开终端粘贴这条命令"作为用户
体验。优先使用操作系统原生的授权能力（macOS 上的 `with administrator privileges`），
让设置一键完成；并且让文档和代码讲**同一个**故事——README 承诺了代码做不到的体验，
本身就是一个 bug。
