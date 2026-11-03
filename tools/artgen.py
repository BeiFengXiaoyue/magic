#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""artgen.py —— 按 04 契约把提示词批量变成图片。

做三件事：
  1. 读 assets/prompts/<category>/<art_id>.md 的 frontmatter 与「正向 / 负向」代码块；
  2. 填进 ComfyUI 的 `无参考生图.json`（节点结构自动解析，不写死节点 id）；
  3. 出图后按契约命名落到 assets/raw/<category>/<art_id>__s<seed>.png。

设计约束（这台机器 8GB 内存 / 8GB 显存，模型共 11.5GB）：
  - 严格串行：一次只提交 1 张，等落盘再下一张；
  - 断点续跑：已有 raw 图的 art_id 默认跳过；
  - 内存看门狗：每次提交前查 /system_stats，内存过低就等；
  - 单张超时隔离：超时/报错只标记该张失败，不中断整批。

用法见 `python tools/artgen.py -h`，或 README.md。
"""

from __future__ import annotations

import argparse
import copy
import json
import random
import re
import shutil
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

# ── 本机路径（换机器只改这一段）────────────────────────────────────────────
PORTABLE = Path(r"C:\Users\BeiFengXiaoYue\Desktop\ComfyUI_windows_portable")
COMFY_PY = PORTABLE / "python_embeded" / "python.exe"
COMFY_MAIN = PORTABLE / "ComfyUI" / "main.py"
WORKFLOW = PORTABLE / "ComfyUI" / "user" / "default" / "workflows" / "无参考生图.json"
COMFY_URL = "http://127.0.0.1:8188"

REPO = Path(__file__).resolve().parents[1]
PROMPTS = REPO / "assets" / "prompts"
RAW = REPO / "assets" / "raw"
TEXTURES = REPO / "assets" / "textures"
STATE = Path(__file__).resolve().parent / ".artgen_state.json"

# ── 契约 §1.2 全局生成参数（唯一出处，改这里就够）──────────────────────────
STEPS = 8
CFG = 1.0
SAMPLER = "res_multistep"
SCHEDULER = "simple"
DENOISE = 1.0
DEFAULT_COUNT = 4          # 每素材候选数（实测 18 秒/张，4 张约 1 分钟）
MIN_FREE_RAM = 1.2 * 1024 ** 3   # 低于此值就等内存
MIN_FREE_VRAM = 0.3 * 1024 ** 3
CONTROL_VALUES = {"fixed", "increment", "decrement", "randomize"}

sys.stdout.reconfigure(encoding="utf-8", errors="replace")


# ── 提示词文件解析 ─────────────────────────────────────────────────────────
def parse_frontmatter(text: str) -> tuple[dict, str]:
    if not text.startswith("---"):
        raise ValueError("缺少 YAML frontmatter")
    end = text.find("\n---", 3)
    if end < 0:
        raise ValueError("frontmatter 未闭合")
    head, body = text[3:end], text[end + 4:]
    meta = {}
    for line in head.splitlines():
        line = line.strip()
        if not line or line.startswith("#") or ":" not in line:
            continue
        key, _, val = line.partition(":")
        val = re.sub(r"\s+#.*$", "", val).strip()
        if len(val) >= 2 and val[0] == val[-1] and val[0] in "\"'":
            val = val[1:-1]
        meta[key.strip()] = None if val in ("", "null", "~") else val
    return meta, body


def parse_block(body: str, heading: str) -> str:
    """取 `## 正向` 之类小节里的第一个 ``` 代码块。"""
    m = re.search(rf"^##\s*{heading}\s*$(.*?)(?=^##\s|\Z)", body, re.M | re.S)
    if not m:
        raise ValueError(f"找不到小节「{heading}」")
    m2 = re.search(r"```[a-zA-Z]*\n(.*?)\n```", m.group(1), re.S)
    if not m2:
        raise ValueError(f"「{heading}」小节里没有代码块")
    return m2.group(1).strip()


def load_prompt(path: Path) -> dict:
    meta, body = parse_frontmatter(path.read_text(encoding="utf-8"))
    art_id = meta.get("id") or path.stem
    canvas = meta.get("canvas") or ""
    mm = re.fullmatch(r"\s*(\d+)\s*[x×]\s*(\d+)\s*", str(canvas))
    if not mm:
        raise ValueError(f"{path.name}: canvas 无法解析：{canvas!r}")
    w, h = int(mm.group(1)), int(mm.group(2))
    if w % 8 or h % 8:
        raise ValueError(f"{path.name}: canvas {w}x{h} 不是 8 的倍数")
    return {
        "path": path,
        "art_id": art_id,
        "category": meta.get("category") or path.parent.name,
        "status": meta.get("status") or "draft",
        "canvas": f"{w}x{h}",
        "width": w,
        "height": h,
        "seed": meta.get("seed"),
        "purpose": str(meta.get("purpose") or ""),
        "body": body,
        "positive": parse_block(body, "正向"),
        "negative": parse_block(body, "负向"),
    }


def discover() -> list[dict]:
    items = []
    for p in sorted(PROMPTS.glob("*/*.md")):
        if p.name.startswith("_"):
            continue
        try:
            items.append(load_prompt(p))
        except Exception as exc:                      # noqa: BLE001
            print(f"[跳过] {p.relative_to(REPO)}: {exc}")
    return items


# ── 工作流 → API 格式 ──────────────────────────────────────────────────────
def build_graph(workflow: Path) -> dict:
    """把 ComfyUI 的 UI 格式工作流转成 /prompt 需要的 API 格式。

    逐个节点按 inputs 顺序走：有 link 就填 [源节点id, 槽位]，
    没有 link 就消费一个 widgets_values（跳过 seed 后面那个 randomize/fixed）。
    """
    ui = json.loads(workflow.read_text(encoding="utf-8"))
    links = {l[0]: (l[1], l[2]) for l in ui.get("links", [])}
    graph = {}

    for node in ui["nodes"]:
        vals = node.get("widgets_values") or []
        if not isinstance(vals, list):
            vals = [vals]
        vals = list(vals)
        vi = 0
        inputs = {}

        for inp in node.get("inputs") or []:
            name = inp["name"]
            lid = inp.get("link")
            if lid is not None:
                if lid not in links:
                    raise ValueError(f"节点 {node['id']} 的连线 {lid} 不存在")
                origin, slot = links[lid]
                inputs[name] = [str(origin), slot]
                continue
            if vi >= len(vals):
                # 没连线的可选输入（例如未接的 image 输入），跳过
                continue
            inputs[name] = vals[vi]
            vi += 1
            if vi < len(vals) and isinstance(vals[vi], str) and vals[vi] in CONTROL_VALUES:
                vi += 1                                  # seed 的 control_after_generate

        graph[str(node["id"])] = {
            "class_type": node["type"],
            "inputs": inputs,
            "_meta": {"title": node.get("title") or node["type"]},
        }
    return graph


def locate(graph: dict) -> dict:
    """按连线关系定位关键节点，而不是靠 id / title。"""
    ksampler = next((nid for nid, n in graph.items() if n["class_type"] == "KSampler"), None)
    if not ksampler:
        raise ValueError("工作流里没有 KSampler")
    ks = graph[ksampler]["inputs"]
    return {
        "ksampler": ksampler,
        "positive": ks["positive"][0],
        "negative": ks["negative"][0],
        "latent": ks["latent_image"][0],
        "save": next(nid for nid, n in graph.items() if n["class_type"] == "SaveImage"),
    }


def build_payload(base: dict, ids: dict, item: dict, seed: int) -> dict:
    g = copy.deepcopy(base)
    g[ids["positive"]]["inputs"]["text"] = item["positive"]
    g[ids["negative"]]["inputs"]["text"] = item["negative"]
    g[ids["latent"]]["inputs"].update(width=item["width"], height=item["height"], batch_size=1)
    g[ids["ksampler"]]["inputs"].update(
        seed=seed, steps=STEPS, cfg=CFG, sampler_name=SAMPLER,
        scheduler=SCHEDULER, denoise=DENOISE,
    )
    g[ids["save"]]["inputs"]["filename_prefix"] = item["art_id"]
    return g


# ── HTTP ───────────────────────────────────────────────────────────────────
def http_json(path: str, payload: dict | None = None, timeout: float = 30):
    url = COMFY_URL + path
    data = None
    headers = {}
    if payload is not None:
        data = json.dumps(payload).encode("utf-8")
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=data, headers=headers)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode("utf-8"))


def http_bytes(path: str, timeout: float = 120) -> bytes:
    with urllib.request.urlopen(COMFY_URL + path, timeout=timeout) as r:
        return r.read()


def server_stats() -> dict | None:
    try:
        return http_json("/system_stats", timeout=5)
    except Exception:                                # noqa: BLE001
        return None


def wait_for_server(seconds: int = 180) -> bool:
    for _ in range(seconds // 3):
        if server_stats() is not None:
            return True
        time.sleep(3)
    return False


def launch_server() -> bool:
    import subprocess
    if server_stats() is not None:
        print("ComfyUI 已在运行")
        return True
    if not COMFY_MAIN.exists():
        print(f"[错误] 找不到 {COMFY_MAIN}")
        return False
    print("启动 ComfyUI（首次加载模型约 1~3 分钟）…")
    subprocess.Popen(
        [str(COMFY_PY), "-s", str(COMFY_MAIN), "--port", "8188", "--disable-auto-launch"],
        cwd=str(PORTABLE), creationflags=getattr(subprocess, "CREATE_NEW_CONSOLE", 0),
    )
    return wait_for_server(240)


def guard_memory(label: str, tries: int = 20) -> bool:
    for i in range(tries):
        st = server_stats()
        if st is None:
            print("[等待] ComfyUI 无响应，稍后重试…")
            time.sleep(10)
            continue
        ram = float(st.get("system", {}).get("ram_free", 0) or 0)
        dev = (st.get("devices") or [{}])[0]
        vram = float(dev.get("vram_free", 0) or 0)
        if ram >= MIN_FREE_RAM and vram >= MIN_FREE_VRAM:
            return True
        print(f"[等待] 内存不足（RAM {ram/1024**3:.1f}GB / 显存 {vram/1024**3:.1f}GB），30 秒后重试")
        time.sleep(30)
    print(f"[放弃] {label}: 内存一直不足")
    return False


# ── 生成 ───────────────────────────────────────────────────────────────────
def generate_one(payload: dict, timeout: int) -> tuple[bool, list[dict], str]:
    cid = f"artgen-{random.getrandbits(32):08x}"
    try:
        resp = http_json("/prompt", {"prompt": payload, "client_id": cid})
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", "replace")[:800]
        return False, [], f"提交被拒 HTTP {exc.code}: {detail}"
    except Exception as exc:                          # noqa: BLE001
        return False, [], f"提交失败: {exc}"

    pid = resp.get("prompt_id")
    if not pid:
        return False, [], f"未返回 prompt_id: {resp}"
    if resp.get("node_errors"):
        return False, [], f"节点报错: {json.dumps(resp['node_errors'], ensure_ascii=False)[:600]}"

    start = time.time()
    while time.time() - start < timeout:
        time.sleep(2)
        try:
            hist = http_json(f"/history/{pid}", timeout=15)
        except Exception:                              # noqa: BLE001
            continue
        if pid not in hist:
            continue
        entry = hist[pid]
        status = entry.get("status") or {}
        if status.get("status_str") == "error":
            msgs = [m for m in status.get("messages", []) if m and m[0] == "execution_error"]
            return False, [], f"执行出错: {json.dumps(msgs[:1], ensure_ascii=False)[:600]}"
        images = []
        for node_out in (entry.get("outputs") or {}).values():
            images.extend(node_out.get("images") or [])
        if images:
            return True, images, ""
    return False, [], f"超时 {timeout}s"


def save_images(images: list[dict], item: dict, seed: int) -> list[Path]:
    out_dir = RAW / item["category"]
    out_dir.mkdir(parents=True, exist_ok=True)
    saved = []
    for i, img in enumerate(images):
        q = urllib.parse.urlencode(
            {"filename": img["filename"], "subfolder": img.get("subfolder", ""), "type": img.get("type", "output")}
        )
        data = http_bytes("/view?" + q)
        suffix = "" if len(images) == 1 else f"_{i + 1}"
        dst = out_dir / f"{item['art_id']}__s{seed}{suffix}.png"
        dst.write_bytes(data)
        saved.append(dst)
    return saved


def load_state() -> dict:
    if STATE.exists():
        try:
            return json.loads(STATE.read_text(encoding="utf-8"))
        except Exception:                              # noqa: BLE001
            pass
    return {"done": {}, "failed": {}}


def save_state(state: dict) -> None:
    STATE.write_text(json.dumps(state, ensure_ascii=False, indent=2), encoding="utf-8")


def has_raw(item: dict) -> bool:
    return any((RAW / item["category"]).glob(f"{item['art_id']}__s*.png"))


# ── 规范检查（lint）────────────────────────────────────────────────────────
STYLE_MD = PROMPTS / "_style.md"
NEGATION = re.compile(r"\b(no|without|never|not)\b", re.I)


def _fence_after(text: str, start_pat: str) -> str:
    m = re.search(start_pat, text, re.M | re.S)
    if not m:
        raise ValueError(f"_style.md 里找不到 {start_pat}")
    m2 = re.search(r"```[a-zA-Z]*\n(.*?)\n```", text[m.end():], re.S)
    if not m2:
        raise ValueError(f"{start_pat} 后面没有代码块")
    return m2.group(1).strip()


def load_style_spec() -> dict:
    text = STYLE_MD.read_text(encoding="utf-8")
    spec = {
        "prefix": _fence_after(text, r"^##\s*1\.\s*风格前缀"),
        "common": _fence_after(text, r"^##\s*2\.\s*通用负向"),
        "suffixes": {},
    }
    # 注意：第 3 节的表不止一张，还接着「**类别负向**」。必须在这之前截断，
    # 否则同一 category 会取到负向那一行（曾因此把负向文本写进正向）。
    sec = re.search(r"^###?\s*3\.\s*类别修饰段(.*?)(?=^\*\*类别负向|\Z)", text, re.M | re.S)
    if sec:
        for m in re.finditer(r"^\|\s*`([a-z]+)`\s*\|\s*`([^`]+)`\s*\|", sec.group(1), re.M):
            spec["suffixes"][m.group(1)] = m.group(2).strip()
    return spec


def lint_one(it: dict, spec: dict) -> list[tuple[str, str]]:
    issues: list[tuple[str, str]] = []
    p, n = it["positive"], it["negative"]

    if it["art_id"] != it["path"].stem:
        issues.append(("错误", f"id 与文件名不符：{it['art_id']} vs {it['path'].stem}"))
    if it["category"] != it["path"].parent.name:
        issues.append(("错误", f"category 与目录不符：{it['category']} vs {it['path'].parent.name}"))
    if not p:
        issues.append(("错误", "正向为空"))
    if not n:
        issues.append(("错误", "负向为空"))

    if not p.startswith(spec["prefix"]):
        issues.append(("错误", "正向开头不是当前 _style.md 的风格前缀（规范漂移）"))
    suffix = spec["suffixes"].get(it["category"], "")
    if suffix and suffix not in p:
        issues.append(("错误", f"正向缺少 {it['category']} 的类别修饰段（规范漂移）"))
    if not n.startswith(spec["common"]):
        issues.append(("错误", "负向开头不是当前通用负向（规范漂移）"))

    body = p.split(suffix, 1)[1] if suffix and suffix in p else p
    hits = sorted({m.group(0).lower() for m in NEGATION.finditer(body)})
    if hits:
        issues.append(("警告", f"内容描述含否定式 {hits}，实测无效，建议改肯定句"))

    if it["category"] == "prop" and "plain flat solid mid-grey background" not in p:
        issues.append(("错误", "物件缺少背景子句，背景会混入石头/地面"))
    if it["status"] == "generated" and not it["seed"]:
        issues.append(("错误", "status=generated 但 seed 为空"))

    # canvas 必须落在契约 §4 的档位上
    allowed = {"1024x576", "1024x768"} if it["category"] == "scene" else {"768x768"}
    if it["canvas"] not in allowed:
        issues.append(("警告", f"canvas {it['canvas']} 不在推荐档位 {'/'.join(sorted(allowed))}（§4）"))

    # 模型出不了 alpha，写"透明背景"会误导下游
    if "透明" in it["purpose"] or "透明" in it["body"]:
        issues.append(("警告", "purpose/备注里写了「透明背景」；实际是纯灰底 + 后处理抠底，建议改写"))
    return issues


def cmd_lint(args: argparse.Namespace) -> int:
    try:
        spec = load_style_spec()
    except Exception as exc:                          # noqa: BLE001
        print(f"[错误] 读 _style.md 失败：{exc}")
        return 2
    items = discover()
    if args.only:
        wanted = {s.strip() for s in args.only.split(",") if s.strip()}
        items = [it for it in items if it["art_id"] in wanted]

    errors = warns = 0
    for it in items:
        issues = lint_one(it, spec)
        bad = [i for i in issues if i[0] == "错误"]
        errors += len(bad)
        warns += len(issues) - len(bad)
        mark = "✗" if bad else ("!" if issues else "✓")
        print(f"{mark} {it['art_id']}")
        for level, msg in issues:
            print(f"    {level}: {msg}")
    print("-" * 60)
    print(f"{len(items)} 个素材：{errors} 个错误，{warns} 个警告")
    return 1 if errors else 0


def cmd_list(_: argparse.Namespace) -> int:
    items = discover()
    print(f"{'art_id':30} {'类别':6} {'画布':10} {'状态':10} 已有原图")
    print("-" * 78)
    todo = 0
    for it in items:
        n = len(list((RAW / it["category"]).glob(f"{it['art_id']}__s*.png")))
        if n == 0:
            todo += 1
        print(f"{it['art_id']:30} {it['category']:6} {it['canvas']:10} {it['status']:10} {n}")
    print("-" * 78)
    print(f"共 {len(items)} 个素材，其中 {todo} 个还没有原图")
    return 0


def cmd_plan(args: argparse.Namespace) -> int:
    base = build_graph(WORKFLOW)
    ids = locate(base)
    items = select_items(args)
    if not items:
        print("没有需要生成的素材")
        return 0
    it = items[0]
    payload = build_payload(base, ids, it, 123456789)
    print(f"工作流节点：{len(base)} 个；正面={ids['positive']} 负面={ids['negative']} "
          f"KSampler={ids['ksampler']} Save={ids['save']}")
    print(f"待生成 {len(items)} 个素材 × {args.count} 张 = {len(items) * args.count} 张")
    print(f"示例：{it['art_id']}  {it['canvas']}  seed=123456789")
    print("payload（节选）:")
    for nid, n in payload.items():
        brief = {k: (v[:60] + "…" if isinstance(v, str) and len(v) > 60 else v)
                 for k, v in n["inputs"].items()}
        print(f"  [{nid}] {n['class_type']}: {json.dumps(brief, ensure_ascii=False)}")
    if args.write_plan:
        out = Path(args.write_plan)
        out.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"完整 payload 已写到 {out}")
    return 0


def select_items(args: argparse.Namespace) -> list[dict]:
    items = discover()
    if args.only:
        wanted = {s.strip() for s in args.only.split(",") if s.strip()}
        items = [it for it in items if it["art_id"] in wanted]
        missing = wanted - {it["art_id"] for it in items}
        if missing:
            print(f"[警告] 找不到：{', '.join(sorted(missing))}")
    if not getattr(args, "force", False):
        items = [it for it in items if not has_raw(it)]
    if args.limit:
        items = items[: args.limit]
    return items


def cmd_run(args: argparse.Namespace) -> int:
    if server_stats() is None:
        if args.launch and launch_server():
            pass
        else:
            print("ComfyUI 未运行。先启动它，或加 --launch 让脚本自己拉起。")
            return 2

    base = build_graph(WORKFLOW)
    ids = locate(base)
    items = select_items(args)
    if not items:
        print("没有需要生成的素材（都已有原图，或 --only 没匹配上）")
        return 0

    total = len(items) * args.count
    print(f"开始：{len(items)} 个素材 × {args.count} 张 = {total} 张，串行执行")
    state = load_state()
    ok = fail = skip = 0
    t_all = time.time()

    for idx, it in enumerate(items, 1):
        if not guard_memory(it["art_id"]):
            state.setdefault("failed", {})[it["art_id"]] = "内存不足"
            save_state(state)
            fail += args.count
            continue

        for c in range(args.count):
            seed = random.getrandbits(62)
            payload = build_payload(base, ids, it, seed)
            tag = f"[{idx}/{len(items)} #{c + 1}] {it['art_id']} seed={seed}"
            print(f"{tag} …", end="", flush=True)
            t0 = time.time()
            good, images, err = generate_one(payload, args.timeout)
            dt = time.time() - t0
            if good:
                paths = save_images(images, it, seed)
                ok += 1
                print(f" 完成 {dt:.0f}s → {paths[0].relative_to(REPO)}")
                state.setdefault("done", {}).setdefault(it["art_id"], []).append(seed)
            else:
                fail += 1
                print(f" 失败（{dt:.0f}s）{err}")
                state.setdefault("failed", {})[it["art_id"]] = err
            save_state(state)

    print("-" * 78)
    print(f"结束：成功 {ok}，失败 {fail}，跳过已有 {skip}；总耗时 {(time.time() - t_all) / 60:.1f} 分钟")
    if ok:
        print("下一步：挑图，然后 `python tools/artgen.py pick <art_id> <seed>`")
    if fail:
        print("失败记录见 tools/.artgen_state.json")
        return 1
    return 0


def cmd_pick(args: argparse.Namespace) -> int:
    items = {it["art_id"]: it for it in discover()}
    it = items.get(args.art_id)
    if not it:
        print(f"找不到素材 {args.art_id}")
        return 2
    src = RAW / it["category"] / f"{it['art_id']}__s{args.seed}.png"
    if not src.exists():
        cands = sorted((RAW / it["category"]).glob(f"{it['art_id']}__s*.png"))
        print(f"找不到 {src.relative_to(REPO)}")
        if cands:
            print("可选：" + ", ".join(p.stem.split("__s")[-1] for p in cands))
        return 2

    dst = TEXTURES / it["category"] / f"{it['art_id']}.png"
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(src, dst)

    text = it["path"].read_text(encoding="utf-8")
    text = re.sub(r"(?m)^seed:.*$", f"seed: {args.seed}", text)
    text = re.sub(r"(?m)^status:.*$", "status: generated", text)
    it["path"].write_text(text, encoding="utf-8")

    print(f"已选用 {src.relative_to(REPO)}")
    print(f"成品   {dst.relative_to(REPO)}   （后处理/缩放待做）")
    print("frontmatter 已更新：seed / status: generated")
    return 0


def cmd_launch(_: argparse.Namespace) -> int:
    return 0 if launch_server() else 1


def main() -> int:
    global COMFY_URL
    ap = argparse.ArgumentParser(description="按 04 契约批量出图")
    ap.add_argument("--url", default=COMFY_URL, help="ComfyUI 地址（默认 127.0.0.1:8188）")
    sub = ap.add_subparsers(dest="cmd", required=True)

    sub.add_parser("list", help="列出素材与已有原图").set_defaults(func=cmd_list)
    sub.add_parser("launch", help="启动 ComfyUI 并等待就绪").set_defaults(func=cmd_launch)

    li = sub.add_parser("lint", help="检查提示词是否符合契约与 _style.md")
    li.add_argument("--only", help="只查这些 art_id，逗号分隔")
    li.set_defaults(func=cmd_lint)

    p = sub.add_parser("plan", help="干跑：打印节点解析与示例 payload")
    p.add_argument("--only", help="只处理这些 art_id，逗号分隔")
    p.add_argument("--limit", type=int)
    p.add_argument("--count", type=int, default=DEFAULT_COUNT)
    p.add_argument("--write-plan", help="把完整 payload 写到文件")
    p.set_defaults(func=cmd_plan, force=False)

    r = sub.add_parser("run", help="真正生成")
    r.add_argument("--only", help="只处理这些 art_id，逗号分隔")
    r.add_argument("--limit", type=int, help="最多处理几个素材")
    r.add_argument("--count", type=int, default=DEFAULT_COUNT, help="每个素材抽几张（默认 2）")
    r.add_argument("--timeout", type=int, default=900, help="单张超时秒数")
    r.add_argument("--force", action="store_true", help="已有原图也重跑")
    r.add_argument("--launch", action="store_true", help="未运行则自行启动 ComfyUI")
    r.set_defaults(func=cmd_run)

    k = sub.add_parser("pick", help="挑定一张：复制到 textures 并回填 seed/status")
    k.add_argument("art_id")
    k.add_argument("seed", type=int)
    k.set_defaults(func=cmd_pick)

    args = ap.parse_args()
    COMFY_URL = args.url.rstrip("/")
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
