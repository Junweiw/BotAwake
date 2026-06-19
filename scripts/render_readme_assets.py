#!/usr/bin/env python3
"""Render docs/menu.png and docs/demo.gif from the HTML mockup."""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MOCKUP = ROOT / "docs" / "mockups" / "menu-mockup.html"
OUT_MENU = ROOT / "docs" / "menu.png"
OUT_DEMO = ROOT / "docs" / "demo.gif"
NODE = Path.home() / ".nvm" / "versions" / "node" / "v25.8.0" / "bin" / "node"

DEMO_FRAMES = [
    ("menu=closed&active=0", 900),
    ("menu=open&selected=normal&active=0", 700),
    ("menu=open&selected=powerOnly&active=1", 1100),
    ("menu=closed&active=1", 900),
    ("menu=open&selected=powerOnly&active=1", 800),
    ("menu=open&selected=stayAwake&active=1", 900),
    ("menu=closed&active=1", 700),
    ("menu=open&selected=normal&active=0", 800),
    ("menu=closed&active=0", 900),
]


def find_node() -> str:
    if NODE.exists():
        return str(NODE)
    node = shutil.which("node")
    if not node:
        raise SystemExit("node not found — install Node.js or set NODE path in script")
    return node


def render_png(html_path: Path, query: str, out_path: Path, scale: float = 2) -> None:
    node = find_node()
    script = f"""
const {{ chromium }} = require('playwright');
const path = require('path');
(async () => {{
  const html = {repr(str(html_path))};
  const out = {repr(str(out_path))};
  const query = {repr(query)};
  const scale = {scale};
  const browser = await chromium.launch({{ channel: 'chrome', headless: true }});
  const page = await browser.newPage({{ viewport: {{ width: 1280, height: 800 }}, deviceScaleFactor: scale }});
  await page.goto('file://' + html + '?' + query, {{ waitUntil: 'load' }});
  await page.waitForTimeout(250);
  await page.screenshot({{ path: out, type: 'png' }});
  await browser.close();
}})().catch(e => {{ console.error(e); process.exit(1); }});
"""
    env = dict(os.environ)
    cue_pw = Path.home() / "Desktop" / "Superlinear" / "Cue Card Project" / "cue-cards-html-skill" / "node_modules"
    bot_pw = ROOT / "remotion" / "node_modules"
    for mod in (cue_pw, bot_pw):
        if (mod / "playwright").exists():
            env["NODE_PATH"] = str(mod)
            break
    subprocess.run([node, "-e", script], check=True, cwd=str(ROOT), env=env)


def build_demo_gif(frame_paths: list[Path], durations_ms: list[int], out_path: Path) -> None:
    from PIL import Image

    target = (960, 600)
    images = []
    for p in frame_paths:
        img = Image.open(p).convert("RGB").resize(target, Image.Resampling.LANCZOS)
        images.append(img.convert("P", palette=Image.ADAPTIVE, colors=128))
    images[0].save(
        out_path,
        save_all=True,
        append_images=images[1:],
        duration=durations_ms,
        loop=0,
        optimize=True,
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--menu-only", action="store_true")
    parser.add_argument("--demo-only", action="store_true")
    args = parser.parse_args()

    if not MOCKUP.exists():
        print(f"Missing mockup: {MOCKUP}", file=sys.stderr)
        return 1

    do_menu = not args.demo_only
    do_demo = not args.menu_only

    if do_menu:
        print("Rendering menu.png …")
        render_png(MOCKUP, "menu=open&selected=powerOnly&active=1", OUT_MENU)
        print(f"Wrote {OUT_MENU}")

    if do_demo:
        print("Rendering demo.gif frames …")
        with tempfile.TemporaryDirectory(prefix="botawake-demo-") as tmp:
            tmp_path = Path(tmp)
            pngs: list[Path] = []
            durations: list[int] = []
            for i, (query, ms) in enumerate(DEMO_FRAMES):
                out = tmp_path / f"frame_{i:02d}.png"
                render_png(MOCKUP, query, out, scale=1)
                pngs.append(out)
                durations.append(ms)
            build_demo_gif(pngs, durations, OUT_DEMO)
        print(f"Wrote {OUT_DEMO}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
