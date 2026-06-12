# BotAwake 合盖保活模式 — 产品全生命周期地图（本地镜像）

> 活地图（随进度打卡）：飞书文档 [2026-0612-BotAwake 产品开发全流程地图](https://tunnu.feishu.cn/docx/CzBrdlphhohbqgxHhE6c31L5nsY)
> 本文件是其本地镜像，里程碑变更时同步更新。
> 范围 = 完整生命周期：造 (Build) → 卖 (GTM/Launch) → 学 (Feedback/Improve)，阶段 12 回流到阶段 2-3 形成迭代小循环。

## 流程与状态

| 大段 | # | 阶段 | 做什么 | 本案例的产物 | 状态 |
|------|---|------|--------|--------------|------|
| 造 Build | 1 | 想法与事实核查 | 验证想法技术上是否成立 | 结论：`pmset disablesleep` 可行（含电池供电），Amphetamine/Sleepless 同机制 | ✅ 2026-06-12 |
| 造 | 2 | 需求澄清（Brainstorm） | 一次一个问题锁定关键决策 | Root = sudoers 白名单；电量保护 = 10/20/30% 子菜单 | ✅ 2026-06-12 |
| 造 | 3 | 方案设计（Design） | 架构/组件/数据流/错误处理，获批准 | 设计提案（对话呈现，批准后落入 spec） | ▶ 进行中 |
| 造 | 4 | PoC 概念验证 | 最小成本真实环境验证核心假设 | 真机 5 分钟实测：disablesleep 1 → 合盖 → 手机 Lark 发提示词 → bot 应答 → 还原 | ⬜ |
| 造 | 5 | 规格（Spec） | 写成可评审文档 | `docs/superpowers/specs/2026-06-12-lid-closed-mode-design.md` | ⬜ |
| 造 | 6 | 实施计划（Plan） | 拆成可验证的小步骤 | `docs/superpowers/plans/2026-06-12-lid-closed-mode-plan.md` | ⬜ |
| 造 | 7 | 编码实现 | 小步实现、随做随验 | `Sources/main.swift` 新模式 + `install.sh` sudoers 步骤 | ⬜ |
| 造 | 8 | 验证与审查 | 真机合盖实测 + code review | 实测记录（`docs/process/`） | ⬜ |
| 卖 Sell | 9 | GTM 上市策略 | 定位/受众/渠道/定价（开源 = 许可与分发） | 一句话定位「合上 MacBook，bot 继续干活」+ README 改版方案 + 渠道清单（GitHub topics / Show HN / V2EX / r/macapps / Twitter） | ⬜ |
| 卖 | 10 | 发布（Launch） | 版本、发布物、发布帖 | v1.1.0 tag + GitHub Release + 渠道发布帖 | ⬜ |
| 学 Learn | 11 | 反馈收集 | 定义信号、跟踪、滤噪 | stars/issues/评论 + 自用一周记录（合盖时长、地板触发次数） | ⬜ |
| 学 | 12 | 迭代改进 + 复盘 | backlog 回流阶段 2-3；经验入脑 | 迭代 backlog + OBSERVATIONS.md 条目 | ⬜ |

## 已锁定的设计决策

| 决策点 | 选择 | 理由 |
|--------|------|------|
| 保活机制 | `pmset disablesleep 1/0`（内核 SleepDisabled 标志） | caffeinate 越不过合盖睡眠；Amphetamine/Sleepless 同机制，Apple Silicon + 当前 macOS 已验证 |
| Root 权限 | `/etc/sudoers.d/botawake` 白名单，仅两条精确命令 | 无人值守回退必须免密；密码弹窗在最需要时失效；范围最小 |
| 电量保护线 | 子菜单 10% / 20% / 30%，低于即回退 Normal + 系统通知 | 兜底防止包里耗干电池 |
| 回退保障 | 模式切换 / 应用退出 / 启动崩溃恢复 三处强制 `disablesleep 0` | 标志持久生效，崩溃不清理则 Mac 永不睡眠 |
| 网络依赖（边界） | 菜单提醒：在外需 Wi-Fi/热点，无网 = bot 不可达 | 本模式只解决"醒着"，不解决联网 |
| 许可/定价 | MIT 开源（维持现状） | 个人工具，分发即 GitHub |

## 产物存放约定

所有过程产物随代码进 git，集中在 `docs/` 下：

```
BotAwake/
├── docs/
│   ├── process/        ← 本地图镜像、PoC/实测记录、GTM 方案
│   ├── superpowers/
│   │   ├── specs/      ← 阶段 5：设计规格
│   │   └── plans/      ← 阶段 6：实施计划
│   ├── menu.png        ← （原有）README 素材
│   └── demo.gif
├── Sources/main.swift
└── ...
```

复盘（阶段 12）按 workspace 写入政策落在 brain（context-infrastructure），不在本仓库。
