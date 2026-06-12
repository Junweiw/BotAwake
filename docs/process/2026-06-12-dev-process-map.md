# BotAwake 合盖保活模式 — 产品开发全流程地图（本地镜像）

> 活地图（随进度打卡）：飞书文档 [2026-0612-BotAwake 产品开发全流程地图](https://tunnu.feishu.cn/docx/CzBrdlphhohbqgxHhE6c31L5nsY)
> 本文件是其本地镜像，里程碑变更时同步更新。

## 流程与状态

| # | 阶段 | 做什么 | 本案例的产物 | 状态 |
|---|------|--------|--------------|------|
| 1 | 想法与事实核查 | 验证想法技术上是否成立 | 结论：`pmset disablesleep` 可行（含电池供电），与 Amphetamine/Sleepless 同机制 | ✅ 2026-06-12 |
| 2 | 需求澄清（Brainstorm） | 一次一个问题锁定关键决策 | Root = sudoers 白名单；电量保护 = 10/20/30% 子菜单 | ✅ 2026-06-12 |
| 3 | 方案设计（Design） | 架构/组件/数据流/错误处理，获批准 | 设计提案（对话呈现，批准后落入 spec） | ▶ 进行中 |
| 4 | 规格（Spec） | 写成可评审文档 | `docs/superpowers/specs/2026-06-12-lid-closed-mode-design.md` | ⬜ |
| 5 | 实施计划（Plan） | 拆成可验证的小步骤 | `docs/superpowers/plans/2026-06-12-lid-closed-mode-plan.md` | ⬜ |
| 6 | 编码实现 | 小步实现、随做随验 | `Sources/main.swift` 新模式 + `install.sh` sudoers 步骤 | ⬜ |
| 7 | 验证与审查 | 真机合盖实测 + code review | 实测记录（合盖后 Lark 发提示词、bot 应答） | ⬜ |
| 8 | 发布（Ship） | README/HANDOFF 更新、commit、tag | v1.1.0 | ⬜ |
| 9 | 复盘（Retro） | 经验写回 brain | `context-infrastructure/contexts/memory/OBSERVATIONS.md` 条目 | ⬜ |

## 已锁定的设计决策

| 决策点 | 选择 | 理由 |
|--------|------|------|
| 保活机制 | `pmset disablesleep 1/0`（内核 SleepDisabled 标志） | caffeinate 越不过合盖睡眠；Amphetamine/Sleepless 同机制，Apple Silicon + 当前 macOS 已验证 |
| Root 权限 | `/etc/sudoers.d/botawake` 白名单，仅两条精确命令 | 无人值守回退必须免密；密码弹窗在最需要时失效；范围最小 |
| 电量保护线 | 子菜单 10% / 20% / 30%，低于即回退 Normal + 系统通知 | 兜底防止包里耗干电池 |
| 回退保障 | 模式切换 / 应用退出 / 启动崩溃恢复 三处强制 `disablesleep 0` | 标志持久生效，崩溃不清理则 Mac 永不睡眠 |
| 网络依赖（边界） | 菜单提醒：在外需 Wi-Fi/热点，无网 = bot 不可达 | 本模式只解决"醒着"，不解决联网 |

## 产物存放约定

所有过程产物随代码进 git，集中在 `docs/` 下：

```
BotAwake/
├── docs/
│   ├── process/        ← 本流程地图镜像、真机实测记录
│   ├── superpowers/
│   │   ├── specs/      ← 阶段 4：设计规格
│   │   └── plans/      ← 阶段 5：实施计划
│   ├── menu.png        ← （原有）README 素材
│   └── demo.gif
├── Sources/main.swift
└── ...
```

复盘（阶段 9）按 workspace 写入政策落在 brain（context-infrastructure），不在本仓库。
