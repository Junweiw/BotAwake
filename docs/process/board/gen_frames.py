#!/usr/bin/env python3
"""Generate animation frames of the BotAwake lifecycle board (Riso Brut).
Frame k: stages <k done, stage k current, >k pending. Frame 13: all done."""

CREAM, CREAM2, INK, INK2 = "#EFE9D9", "#E4DCC4", "#0F0F0F", "#2A2A2A"
GREEN, PINK, YELLOW = "#1F8A4C", "#F06CA8", "#F5C518"
ARC = {"build": GREEN, "sell": PINK, "learn": YELLOW}

STAGES = [
    (1, "想法与核查", "disablesleep 可行 · 含电池", "build"),
    (2, "需求澄清", "sudoers + 电量地板已锁定", "build"),
    (3, "方案设计", "设计提案等待批准 HARD GATE", "build"),
    (4, "PoC 概念验证", "真机合盖 5 分钟实测", "build"),
    (5, "规格 Spec", "可评审的设计规格文档", "build"),
    (6, "实施计划", "拆成可独立验证的小步骤", "build"),
    (7, "编码实现", "新模式 + sudoers 安装", "build"),
    (8, "验证与审查", "合盖实测 + Code Review", "build"),
    (9, "GTM 上市策略", "定位 · 受众 · 渠道 · 许可", "sell"),
    (10, "发布 Launch", "v1.1.0 + Release + 发布帖", "sell"),
    (11, "反馈收集", "Stars · Issues · 自用记录", "learn"),
    (12, "迭代 + 复盘", "Backlog 回流 · 经验入脑", "learn"),
]

DIAMOND = '<rect x="{x}" y="{y}" width="12" height="12" fill="%s" transform="rotate(45 {cx} {cy})"/>' % INK

def diamond(cx, cy):
    return f'<rect x="{cx-6}" y="{cy-6}" width="12" height="12" fill="{INK}" transform="rotate(45 {cx} {cy})"/>'

def static_parts(subtitle):
    s = []
    s.append(f'<rect x="0" y="0" width="1740" height="830" fill="{CREAM}"/>')
    s.append(f'<rect x="100" y="50" width="640" height="80" fill="{INK}"/>')
    s.append(f'<rect x="90" y="40" width="640" height="80" fill="{GREEN}" stroke="{INK}" stroke-width="4"/>')
    s.append(f'<text x="110" y="93" font-size="30" font-weight="700" fill="{CREAM}">BOTAWAKE · 产品全生命周期</text>')
    s.append(f'<text x="90" y="163" font-size="18" fill="{INK2}">{subtitle}</text>')
    for lx, color, label in [(1130, GREEN, "造 Build 1-8"), (1330, PINK, "卖 Sell 9-10"), (1530, YELLOW, "学 Learn 11-12")]:
        s.append(f'<rect x="{lx}" y="52" width="22" height="22" fill="{color}" stroke="{INK}" stroke-width="3"/>')
        s.append(f'<text x="{lx+32}" y="70" font-size="18" font-weight="700" fill="{INK}">{label}</text>')
    # in-row connectors
    for ry in (275, 475, 675):
        for gx in (460, 870, 1280):
            s.append(f'<line x1="{gx}" y1="{ry}" x2="{gx+36}" y2="{ry}" stroke="{INK}" stroke-width="3"/>')
            s.append(diamond(gx + 36, ry))
    # row transitions
    for (top, mid, bot) in [(340, 375, 404), (540, 575, 604)]:
        s.append(f'<polyline points="1505,{top} 1505,{mid} 275,{mid} 275,{bot}" fill="none" stroke="{INK}" stroke-width="3"/>')
        s.append(diamond(275, bot))
    # loop back
    s.append(f'<polyline points="1505,740 1505,775 45,775 45,180 685,180 685,204" fill="none" stroke="{INK}" stroke-width="3"/>')
    s.append(diamond(685, 204))
    s.append(f'<rect x="640" y="757" width="310" height="36" fill="{CREAM}" stroke="{INK}" stroke-width="3"/>')
    s.append(f'<text x="795" y="781" font-size="17" font-weight="700" fill="{INK}" text-anchor="middle">回流：反馈 → 新一轮需求 / 设计</text>')
    return s

def card(n, title, desc, arc, state):
    col, row = (n - 1) % 4, (n - 1) // 4
    x, y = 90 + col * 410, 210 + row * 200
    shadow = PINK if state == "current" else INK
    body = CREAM2 if state == "done" else CREAM
    off = 12 if state == "current" else 10
    s = [
        f'<rect x="{x+off}" y="{y+off}" width="370" height="130" fill="{shadow}"/>',
        f'<rect x="{x}" y="{y}" width="370" height="130" fill="{body}" stroke="{INK}" stroke-width="4"/>',
        f'<rect x="{x+4}" y="{y+4}" width="14" height="122" fill="{ARC[arc]}"/>',
        f'<circle cx="{x+55}" cy="{y+45}" r="24" fill="{YELLOW}" stroke="{INK}" stroke-width="4"/>',
        f'<text x="{x+55}" y="{y+53}" font-size="22" font-weight="700" fill="{INK}" text-anchor="middle">{n}</text>',
        f'<text x="{x+95}" y="{y+52}" font-size="24" font-weight="700" fill="{INK}">{title}</text>',
        f'<text x="{x+95}" y="{y+92}" font-size="16" fill="{INK2}">{desc}</text>',
    ]
    if state == "done":
        s.append(f'<rect x="{x+255}" y="{y+12}" width="96" height="30" fill="{GREEN}" stroke="{INK}" stroke-width="3"/>')
        s.append(f'<text x="{x+303}" y="{y+33}" font-size="15" font-weight="700" fill="{CREAM}" text-anchor="middle">✓ 完成</text>')
    elif state == "current":
        s.append(f'<rect x="{x+255}" y="{y+12}" width="96" height="30" fill="{PINK}" stroke="{INK}" stroke-width="3"/>')
        s.append(f'<text x="{x+303}" y="{y+33}" font-size="15" font-weight="700" fill="{CREAM}" text-anchor="middle">▶ 当前</text>')
    return s

for k in range(1, 14):
    if k <= 12:
        sub = f"合盖保活模式 Lid-Closed Awake · 12 阶段 · 当前：阶段 {k} {STAGES[k-1][1]}"
    else:
        sub = "合盖保活模式 Lid-Closed Awake · 12 阶段全部完成 · 回流开启新一轮"
    parts = static_parts(sub)
    for n, title, desc, arc in STAGES:
        state = "done" if (n < k or k == 13) else ("current" if n == k else "pending")
        parts += card(n, title, desc, arc, state)
    svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1740 830">\n' + "\n".join(parts) + "\n</svg>\n"
    open(f"frame_{k:02d}.svg", "w").write(svg)
    print(f"frame_{k:02d}.svg")
