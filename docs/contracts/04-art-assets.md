# 04 · 美术素材与提示词契约

> **状态：草案 v0.1**
> 依据：`03-表现/美术风格.md`（美术的唯一依据）· ComfyUI 工作流（现状登记见 §1）
>
> 规则一句话：**每个素材 = 一个 `art_` ID = 一个提示词文件（源，进 git）+ 一张产出图（按 ID 命名）。**

---

## 1. 工作流现状登记（本机）

| 项 | 值 |
|---|---|
| 工作流目录 | `C:\Users\BeiFengXiaoYue\Desktop\ComfyUI_windows_portable\ComfyUI\user\default\workflows\` |
| 出图工作流 | `generate img.json` —— **参考图 + 提示词 → 风格迁移出图** |
| 模型栈 | UNET `z_image_turbo_fp8_e4m3fn` · VAE `z-image-ae` · CLIP `qwen_3_4b_fp8_mixed`（qwen_image）|
| 出视频工作流 | `generate video.json` —— 图生视频（循环动画用，`fx` / 动画类素材）|

### 1.1 提示词节点映射（image 工作流）

| 填什么 | 节点 | 说明 |
|---|---|---|
| 正面提示词 | `CLIPTextEncode` title=**正面**（id 7）| 粘贴素材文件的「正向」代码块全文 |
| 负面提示词 | `CLIPTextEncode` title=**负面**（id 8）| 粘贴「负向」代码块全文 |
| 参考图 | `LoadImage`（id 1）→ `ImageScaleToTotalPixels`（0.5）| 构图/风格参考；`ref` 为空时用工作流当前载入图 |
| 随机种子 | `ZImageTurboStyleTransfer.widgets[3]` | **生成后把 seed 回填到素材文件 frontmatter** |

> 节点内其余参数（0.55 / 8 / 0.85 等）含义以节点自带说明为准；**改动前先在 1 张素材上验证**，验证通过再用于批产。

### 1.2 生产流程（每次照做）

1. 打开素材的 `.md`，确认 `status: approved`；
2. ComfyUI 载入 `generate img.json`，粘贴正/负提示词，按需换参考图（建议把 SaveImage 的 `filename_prefix` 填为 `art_id`）；
3. 出图 → 按 ID 改名，存入 `assets/raw/<category>/<art_id>.png`（多版加 `__s<seed>` 后缀）；
4. 后处理（抠底 / 裁边 / 缩放至美术 §14.1 规格）→ 存入 `assets/textures/<category>/<art_id>.png`；
5. 回填 `seed`（与 `canvas`、参考图），`status: generated` → 提交。

---

## 2. 存放位置（唯一合法位置）

```
assets/
├─ prompts/                    ★ 提示词（源数据）
│  ├─ _style.md                全局风格前缀 + 通用负向（唯一出处）
│  └─ <category>/<art_id>.md   一个素材一个文件
├─ refs/                       ★ 参考图（风格迁移输入）
│  └─ <art_id>.(png|jpg|webp)
├─ raw/                        ★ 生成原图（AI 直接输出，保真留档）
│  └─ <category>/<art_id>.png
└─ textures/                   ★ 游戏成品（Godot 唯一导入的素材目录）
   └─ <category>/<art_id>.png
```

| 目录 | 内容 | Godot 导入 | 进 git | 命名 |
|---|---|---|---|---|
| `prompts/` | 提示词 + 风格前缀 | ✗（`.gdignore`）| ✅ | `<art_id>.md` |
| `refs/` | 参考图 | ✗（`.gdignore`）| ✅ | `<art_id>.<ext>` |
| `raw/` | AI 原始输出（未处理） | ✗（`.gdignore`）| ✅ | `<art_id>.png`；多版 `<art_id>__s<seed>.png` |
| `textures/` | 抠底 / 缩放后的成品 | ✅ | ✅ | `<art_id>.png` |

**四条硬规则**：

1. **提示词只存在 `prompts/`**，文件名 = `art_id`，与 `raw/`、`textures/` 的 `<art_id>` 一一对应。
2. **`raw/` 是可复现的源**：一律保存 AI 原始输出（原尺寸、原背景），**永不直接进游戏**。
3. **`textures/` 是游戏唯一引用的素材目录**：后处理（抠底、裁边、缩放至美术 §14.1 规格）后的成品放这里；切帧 / 图集在 Godot 内配置，不额外产生文件。
4. **引用方式**：代码与数据一律用 `art_id`，路径由 `res://assets/textures/<category>/<art_id>.png` 推导，**不得**写死文件名。

---

## 3. 素材 ID 与命名

- 前缀 `art_`（补入 00 契约前缀表），格式：`art_<category>_<slug>`，slug 用拼音（与项目 ID 纪律一致）。
- 命名：文件 `<art_id>.md` / `<art_id>.png`；**ID 即文件名即引用键**。

| category | 用途 | 例 |
|---|---|---|
| `scene` | 整幅场景（含光照基调） | `art_scene_workshop` |
| `char` | 角色精灵（sheet） | `art_char_hero_walk` |
| `prop` | 物件（可交互 / 装饰） | `art_prop_crucible_clay` |
| `tile` | 地形图块、高度侧面 | `art_tile_forest_ground` |
| `ui` | 面板、纸页、图标 | `art_ui_letter_paper` |
| `mob` | 怪物 | `art_mob_yelang` |
| `fx` | 特效、循环动画（可走 video 工作流） | `art_fx_bubbles` |

---

## 4. 提示词文件格式

YAML frontmatter + 三节正文：

```markdown
---
id: art_scene_workshop
category: scene
purpose: 炼药工坊——坩埚是唯一强光源，墙角全暗
status: draft            # draft | approved | generated
workflow: generate img.json
ref: null                # 参考图文件名（assets/refs/ 下）；null = 用工作流当前载入图
canvas: 1024x576         # 生成尺寸（≠ 游戏内尺寸）
seed: null               # 生成后回填
tier: demo               # demo | full
---

## 正向
（完整、可直接粘贴——风格前缀 + 本条内容描述）

## 负向
（完整、可直接粘贴——通用负向 + 类别负向）

## 备注
- 构图与交互物件位置（供 Godot 摆放）
- 游戏内规格（见美术文档 §14.1）
```

- **「正向 / 负向」必须是拼好的完整字符串**（便于直接复制），拼装规则见 §5。
- `canvas` 建议：场景 `1024x576`（16:9）· 物件/角色/图标 `1024x1024` · 特殊情况单独注明。生成尺寸与游戏内规格无关，后期缩放。

---

## 5. 提示词书写规则

### 5.1 语言与结构

- **一律英文**（模型训练语料以英文为主；中文描述仅出现在 `purpose`/备注里）。
- **正向 = 风格前缀 + 内容描述 + 类别修饰**：

| 段 | 来源 | 例 |
|---|---|---|
| 风格前缀 | `_style.md`（唯一出处，全库一致） | `hand-drawn 2D game asset, Don't Starve ink illustration style, …` |
| 内容描述 | 本素材文件（这条专有的） | `a small alchemy workshop interior with a clay crucible in the center…` |
| 类别修饰 | `_style.md` 的类别段 | 场景 → `orthographic top-down view at 45 degrees, flat 2D, no perspective` |

- **负向 = 通用负向（`_style.md`）+ 类别负向**（如角色可加 `multiple characters`，物件可加 `scene background`）。

### 5.2 美术文档 → 提示词 tag 映射（写素材时逐条对照）

| 美术文档 | 正向 tag | 负向 tag |
|---|---|---|
| §二 笔触·饥荒 | `thick dark ink outlines, rough hand-drawn linework, exaggerated shapes` | — |
| §二 光影·锈湖 | `moody chiaroscuro lighting, heavy dark shadows` | `bright daylight, flat lighting` |
| §三 不是像素画 | `hand-drawn illustration, painterly` | `pixel art, 8-bit, retro game sprite` |
| §五 正交 45° | `orthographic top-down view, 45-degree angle, flat 2D` | `perspective, vanishing point, isometric 3D, depth of field, tilt-shift` |
| §6.1 描边 | `dark ink outline, color #1A1714, never pure black` | `pure black #000000, pure white #FFFFFF` |
| §6.2 笔触材质 | `visible dry-brush edges, canvas paper texture` | `smooth airbrush, plastic look` |
| §6.3 比例（角色） | `1:2.5 head-to-body ratio, big head, thin limbs` | `realistic human proportions` |
| §7.1 明暗 | `60-70% of frame in shadow, one limited warm highlight` | `evenly lit, high-key lighting` |
| §7.2 光源 | `single warm amber light source #D98C3F` | `multiple light sources, neon lights` |
| §八 色板 | `muted desaturated cold palette, aged wood brown #5C4B3A, grey stone #6E6A63, moss green #4A5240, faded blue #3E4A55, bone white #C9BFA8` | `saturated candy colors, neon, bright pastel` |
| §12.1 主角 | `blank expressionless face, two dot eyes, single line mouth` | `detailed facial features, cartoon smile` |
| §12.2 幻影怪 | `no shadow, outline not closed, translucent` | （幻影怪条目专用）`ground shadow, solid body` |
| §十三 特效 | `hand-drawn particles, scratch-out highlights` | `soft bloom, glow blur, modern VFX` |
| §十五 红线（汇总） | — | 见 `_style.md` 通用负向（已含全部红线） |

### 5.3 内容描述写法

- 先**构图**（画面里有什么、在哪），再**明暗**（光从哪来、哪里是暗部），最后**焦点**（玩家该看哪里）。
- 数量词写明确（`a single crucible`、`three shelves`），避免"许多、丰富"这类模糊词。
- 交互物件（坩埚、柜台、床…）在描述里点名，并在「备注」里写它在画面中的大致位置。

---

## 6. 状态机与变更纪律

```
draft ──试生成 1~2 张、人工核对风格──▶ approved ──批产──▶ generated
```

- **风格前缀（`_style.md`）未验证前，不批量生成**：先出 1 张场景 + 1 张物件，核对 §5.2 映射是否成立，再推进其余。
- 风格前缀变更 = 全库事件：改 `_style.md` 后，用 `rg` 把旧前缀段替换到所有素材文件，并在提交信息里注明影响范围。
- `status: approved` 之前，任何素材可自由改写；`generated` 之后改提示词，必须同时注明"旧图是否作废"。

---

## 7. 素材清单（Demo 最小集）

> 来源：Demo 计划 §三「美术 A1~A4」+ 美术文档 §14.2。**本表是唯一清单**，新增素材先在此登记再建文件。

| ID | category | 用途 | 里程碑 | 状态 |
|---|---|---|---|---|
| `art_scene_workshop` | scene | 炼药工坊（坩埚强光、大暗部） | M2 | todo |
| `art_scene_shop` | scene | 小店（柜台、信件桌、公告板） | M2 | todo |
| `art_scene_forest` | scene | 晨暮森林·南坡（清露草、路径、雾） | M2 | todo |
| `art_scene_attic` | scene | 阁楼（旧箱、尘埃、极暗） | M3 | todo |
| `art_char_hero_walk` | char | 主角 4 向行走 sheet | M2 | todo |
| `art_prop_crucible_clay` | prop | 陶土坩埚（M1 核心交互） | M1 | todo |
| `art_prop_ingredient_rack` | prop | 原料架 | M1 | todo |
| `art_prop_journal_desk` | prop | 手记台 | M1 | todo |
| `art_prop_counter` | prop | 小店柜台 | M2 | todo |
| `art_prop_hearth` | prop | 壁炉（火烤交互） | M3 | todo |
| `art_prop_water_basin` | prop | 水盆（蘸水交互） | M3 | todo |
| `art_prop_bed` | prop | 床（睡眠存档） | M4 | todo |
| `art_tile_forest_ground` | tile | 森林地表（草/土/苔） | M2 | todo |
| `art_node_qinglucao` | prop | 清露草采集点（雾中） | M2 | todo |
| `art_prop_tree_set` | prop | 乔木 ×2 + 灌木 ×2 | M2 | todo |
| `art_ui_letter_paper` | ui | 信件纸页（羊皮纸、撕裂边） | M3 | todo |
| `art_ui_journal` | ui | 手记面板（配方 / 记录两页） | M3 | todo |
| `art_ui_panel_frame` | ui | 通用面板九宫格 | M2 | todo |
| `art_mob_yelang` | mob | 野狼（实体怪，有影子） | M4 | todo |
| `art_mob_dushe` | mob | 毒蛇（实体怪） | M4 | todo |
| `art_fx_bubbles` | fx | 坩埚气泡/蒸气（循环，video 工作流） | M1 | todo |
| `art_fx_alchemy_glow` | fx | 炼金发光（药绿） | M2 | todo |

> 状态：`todo` → 建文件后 `draft` → 风格核定后 `approved` → 批产回填 seed 后 `generated`。
> **素材提示词文件的撰写属执行阶段**（规范核定后统一开工）。

---

## 8. 本契约新定的决策（待评审确认）

| # | 决策 | 理由 |
|---|---|---|
| 1 | 提示词文件用 **Markdown + YAML frontmatter**（而非 JSON）| 人要读、要复制粘贴；结构化字段仍可被脚本解析 |
| 2 | 「正向 / 负向」在素材文件里是**拼好的完整字符串**（不写占位符） | 使用体验优先（复制即用）；一致性靠 §6 的全库替换纪律 |
| 3 | 提示词**一律英文** | 模型语料以英文为主；中文只进 `purpose` 与备注 |
| 4 | 素材 ID 采用 `art_` + 拼音 slug | 与项目既有 ID 纪律（00 契约 §3）一致 |
| 5 | `prompts/` 与 `refs/` 放 `.gdignore` | 防止 Godot 把源数据当资产导入 |
| 6 | **风格前缀验证前不批产** | 前缀是全局乘数，错了会全库返工 |
| 7 | **生成资源分两级：`raw/`（原图）与 `textures/`（成品）** | 原图保真可复现、不进游戏包；引擎只引用成品，来源与产物不混 |
| 8 | 后处理不产生新 art_id | 成品与源共用一个 ID，追溯简单（提示词 → raw → textures 同名） |
