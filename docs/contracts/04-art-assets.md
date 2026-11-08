# 04 · 美术素材与提示词契约

> **状态：草案 v0.2**
> 依据：`03-表现/美术风格.md`（美术的唯一依据）· ComfyUI 工作流（现状登记见 §1）
>
> 规则一句话：**每个素材 = 一个 `art_` ID = 一个提示词文件（源，进 git）+ 一张产出图（按 ID 命名）。**
>
> **v0.2 变更**：出图统一走**纯文生图**（`无参考生图.json`），不再使用参考图、不再做风格迁移；`refs/` 暂停使用；状态机简化为 `draft → generated`。

---

## 1. 工作流现状登记（本机）

| 项 | 值 |
|---|---|
| 工作流目录 | `C:\Users\BeiFengXiaoYue\Desktop\ComfyUI_windows_portable\ComfyUI\user\default\workflows\` |
| **出图工作流（唯一）** | `无参考生图.json` —— **纯文生图**：正/负提示词 + 尺寸 → 出图，**不使用参考图** |
| 模型栈 | UNET `z_image_turbo_fp8_e4m3fn` · VAE `z-image-ae` · CLIP `qwen_3_4b_fp8_mixed`（qwen_image）|
| 出视频工作流 | `generate video.json` —— 图生视频（循环动画用，`fx` / 动画类素材）|
| **参考生图（i2i，已验证）** | `generate img.json` —— 参考图 + 提示词 → 重绘。**不改姿势**（0.45 / 0.75 实测都只是重绘同一张），用途仅限：统一风格、修细节、放大定稿图。逐帧动作仍走文生图 |

### 1.1 提示词节点映射（`无参考生图.json`）

> 节点 id 会因重新保存而变，**以 title / class_type 为准**；下表 id 是 2026-11 的实际值。

| 填什么 | 节点 | API 键 | 说明 |
|---|---|---|---|
| 正面提示词 | `CLIPTextEncode` title=**正面**（id 5）| `text` | 粘贴素材文件的「正向」代码块全文 |
| 负面提示词 | `CLIPTextEncode` title=**负面**（id 4）| `text` | 粘贴「负向」代码块全文 |
| 尺寸 | `EmptyLatentImage`（id 7）| `width` / `height` | 由 frontmatter 的 `canvas` 决定，**必须是 8 的倍数** |
| 随机种子 | `KSampler`（id 8）| `seed` | **生成后把 seed 回填到素材文件 frontmatter** |
| 采样参数 | `KSampler`（id 8）| `steps` / `cfg` / `sampler_name` / `scheduler` / `denoise` | 用 §1.2 的全局值，不逐张调 |
| 输出前缀 | `SaveImage`（id 9）| `filename_prefix` | 填 `art_id` |

### 1.2 全局生成参数（唯一出处，不逐张改）

| 项 | 值 |
|---|---|
| steps | `8` |
| cfg | `1.0` |
| sampler / scheduler | `res_multistep` / `simple` |
| denoise | `1.0` |
| 每素材抽几张 | **4 张，人眼挑 1 张** |
| 本机实测 | RTX 5060 Laptop 8GB；768×768 **实测 18 秒/张**（2026-11-03，服务已热）。冷启动另有一次性模型加载约 1~2 分钟 |

> **参数定死，不再调。** 之前 cfg 1.0 / 1.5 各抽过一张，但 seed 不同、差异无法归因，不作为调参依据；低成本定位下这点画质差别不值得停线。

### 1.3 生产流程（每次照做）

1. 打开素材的 `.md`，确认 `status: draft`、正/负向完整；
2. ComfyUI 载入 `无参考生图.json`：按 `canvas` 填 `EmptyLatentImage` 宽高，`SaveImage` 的 `filename_prefix` 填 `art_id`，粘贴正/负提示词；
3. 抽 **4 张**，人眼挑 1 张；
4. 四张一律按 seed 改名，存入 `assets/raw/<category>/<art_id>__s<seed>.png`（挑中的也是这个格式）；
5. 挑中的那张做后处理（抠底 / 裁边 / 缩放至美术 §14.1 规格）→ `assets/textures/<category>/<art_id>.png`；
6. 回填 `seed`（从 PNG 的 `prompt` 元数据里读，**不要手抄**），`status: generated` → 提交。

> **透明背景**：纯文生图不出 alpha。正向里统一写 `isolated on a plain flat dark grey background`（底色一致才好批量抠），透明由第 5 步后处理获得。

---

## 2. 存放位置（唯一合法位置）

```
assets/
├─ prompts/                    ★ 提示词（源数据）
│  ├─ _style.md                全局风格前缀 + 通用负向（唯一出处）
│  └─ <category>/<art_id>.md   一个素材一个文件
├─ refs/                       ○ 参考图（**暂停使用**；恢复图生图时才启用）
│  └─ <art_id>.(png|jpg|webp)
├─ raw/                        ○ 生成原图（AI 直接输出，本地留档，不入库）
│  └─ <category>/<art_id>__s<seed>.png
└─ textures/                   ★ 游戏成品（Godot 唯一导入的素材目录）
   └─ <category>/<art_id>.png
```

| 目录 | 内容 | Godot 导入 | 进 git | 命名 |
|---|---|---|---|---|
| `prompts/` | 提示词 + 风格前缀 | ✗（`.gdignore`）| ✅ | `<art_id>.md` |
| `refs/` | 参考图（**当前流程不产出**） | ✗（`.gdignore`）| ✅ | `<art_id>.<ext>` |
| `raw/` | AI 原始输出（未处理） | ✗（`.gdignore`）| ❌（本地保留）| `<art_id>.png`；多版 `<art_id>__s<seed>.png` |
| `textures/` | 抠底 / 缩放后的成品 | ✅ | ✅ | `<art_id>.png` |

**四条硬规则**：

1. **提示词只存在 `prompts/`**，文件名 = `art_id`，与 `raw/`、`textures/` 的 `<art_id>` 一一对应。
2. **`raw/` 是可复现的源**：一律保存 AI 原始输出（原尺寸、原背景），**永不直接进游戏**；候选图体积大，**只在本地保留，不进 git**（`.gitignore` 已忽略 `assets/raw/`）。
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
status: draft            # draft | generated（approved 仅用于全局风格变更，见 §6）
workflow: 无参考生图.json
ref: null                # 当前流程恒为 null（纯文生图）；恢复图生图时填参考图文件名
canvas: 1024x576         # 生成尺寸（≠ 游戏内尺寸）；宽高必须是 8 的倍数
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
- `canvas` 按**游戏内宽高比**定，不用拍脑袋：
  - 室内场景 `1024x576`（16:9，铺 1280×720）；
  - 森林地图 `1024x768`（4:3，与 `forest.json` 的 3200×2400 同比例，放大 3.125×）；
  - 其余（物件 / 角色 / 图标 / 地形 / 特效）`768x768`；
  - 8GB 显存下 768×768 比 1024×1024 快约 40%，成品反正要缩到 §14.1 规格，画布更大没有收益；
  - 宽高必须是 **8 的倍数**（`EmptyLatentImage` 的硬约束）。

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

### 5.4 负向与否定式的实际效力（实测）

纯文生图 + `cfg 1.0` 下的实测结论（cfg 1.0 / 1.5 两次抽图都出现同样现象），写提示词时按这个来：

| 写法 | 实测表现 | 建议 |
|---|---|---|
| 负向 `drop shadow` / `scene background` | **仍出现落地投影、背景石头与地面纹理** | 负向只当"人眼核对清单"，**不当作生成保证** |
| 正向里的否定句（`no side faces visible` / `no ground shadow` / `no background scenery`） | **基本无效** | 改肯定句 |
| 正向补 `isolated on a completely plain flat solid mid-grey background, empty background, nothing else in the frame` | **有效**：同一提示词下背景石头与地面纹理消失，边缘可抠 | 物件类**必须**带这句（已写进 `_style.md` 的 prop 段，9 份物件文件已同步）|
| `orthographic top-down view` | 部分生效，单个物件仍可能出 3/4 体积 | 场景多抽；物件可接受轻微体积感 |

> 结论：**约束靠肯定句 + 多抽 + 人挑**，不靠负向。负向仍维护（换模型 / 改 cfg 时立刻能用）。

### 5.5 硬规则（可机械校验，`python tools/artgen.py lint`）

提示词可能由别的 AI 撰写，所以规则必须是**能自动检查**的。写素材前先读这一节，写完跑 lint，`0 个错误` 才算交活。

| # | 规则 | lint 级别 |
|---|---|---|
| 1 | 正向 = **当前 `_style.md` 的风格前缀 + 类别修饰段 + 本条内容描述**，三段按序拼接 | 错误（漂移即报）|
| 2 | 负向 = **当前通用负向 + 类别负向** | 错误 |
| 3 | 物件（`prop`）正向必须含背景子句，精确字符串见 `_style.md` prop 段 | 错误 |
| 4 | 内容描述里**不写否定式**（`no` / `without` / `never` / `not`） | 警告 |
| 5 | `id` = 文件名 = 目录对应的 category；`canvas` 是 8 的倍数 | 错误 |
| 6 | `status: generated` 必须有 `seed` | 错误 |
| 7 | `canvas` 落在 §4 的档位（场景 1024×576 / 1024×768，其余 768×768） | 警告 |
| 8 | `purpose` 与备注里**不写「透明背景」**（模型出不了 alpha，实际是纯灰底 + 后处理抠底） | 警告 |

> 为什么单列第 1 条：前缀和类别段是**全库乘数**，`_style.md` 一改，所有文件都得跟。lint 直接比对当前 `_style.md` 的原文，能一次抓出没跟上的文件（实测抓到 9 个）。
>
> 第 4 条只报警告：`no gradients` 这类短语是风格前缀的一部分（已被第 1 条覆盖）。但**内容描述里的否定式建议全部改写**——12 份素材已做到 0 警告，新素材按这个标准来。
>
> 第 7、8 条是"文案与事实一致"的检查：`canvas` 写大了只是慢，写"透明背景"会让下游误以为模型能出 alpha。

---

## 6. 状态机与变更纪律

```
draft ──抽 4 张、人眼挑 1 张、回填 seed──▶ generated
```

- **不做"风格前缀预验证"这一步**：项目定位是低成本小游戏，风格"够用且一致"即可，不追求单图质量。一致性来自 `_style.md` 的同一段前缀 + §1.2 的同一组参数，而不是逐张打磨。
- **`approved` 保留但日常不用**：仅在"要改 `_style.md`"这种全库事件前，先用 1 张场景 + 1 张物件确认新前缀方向，再全库替换。
- 风格前缀变更 = 全库事件：改 `_style.md` 后，用 `rg` 把旧前缀段替换到所有素材文件，并在提交信息里注明影响范围。
- `generated` 之后改提示词，必须注明"旧图是否作废"，并重跑该素材。

---

## 7. 素材清单（Demo 最小集）

> 来源：Demo 计划 §三「美术 A1~A4」+ 美术文档 §14.2。**本表是唯一清单**，新增素材先在此登记再建文件。

| ID | category | 用途 | 里程碑 | 状态 |
|---|---|---|---|---|
| `art_scene_workshop` | scene | 炼药工坊（坩埚强光、大暗部） | M2 | generated |
| `art_scene_shop` | scene | 小店（柜台、信件桌、公告板） | M2 | generated |
| `art_scene_forest` | scene | 晨暮森林·南坡（清露草、路径、雾） | M2 | generated |
| `art_scene_attic` | scene | 阁楼（旧箱、尘埃、极暗） | M3 | todo |
| `art_char_hero_walk` | char | 主角**左右两向**行走 sheet（上下移动复用左右，纯垂直时沿用上一朝向） | M2 | generated |
| `art_prop_crucible_clay` | prop | 陶土坩埚（M1 核心交互） | M1 | generated |
| `art_prop_ingredient_rack` | prop | 原料架 | M1 | generated |
| `art_prop_journal_desk` | prop | 手记台 | M1 | generated |
| `art_prop_counter` | prop | 小店柜台 | M2 | generated |
| `art_prop_door_wood` | prop | 室内木门（嵌墙、通用） | M2 | generated |
| `art_prop_cave_entrance` | prop | 森林洞穴入口（回工坊） | M2 | generated |
| `art_prop_hearth` | prop | 壁炉（火烤交互） | M3 | todo |
| `art_prop_water_basin` | prop | 水盆（蘸水交互） | M3 | todo |
| `art_prop_bed` | prop | 床（睡眠存档） | M4 | generated |
| `art_tile_forest_ground` | tile | 森林地表（草/土/苔） | M2 | todo |
| `art_prop_qinglucao` | prop | 清露草采集点（雾中） | M2 | generated |
| `art_prop_taiyi` | prop | 苔衣固定采集点（老树根） | M2 | generated |
| `art_prop_fengshisha` | prop | 风蚀砂野生采集点（山脊） | M2 | generated |
| `art_prop_shiyingsha` | prop | 石英砂固定采集点（河床） | M2 | generated |
| `art_prop_tree_set` | prop | 乔木 ×2 + 灌木 ×2 | M2 | todo |
| `art_ui_letter_paper` | ui | 信件纸页（羊皮纸、撕裂边） | M3 | todo |
| `art_ui_journal` | ui | 手记面板（配方 / 记录两页） | M3 | todo |
| `art_ui_panel_frame` | ui | 通用面板九宫格（大面板备用） | M2 | generated |
| `art_ui_icon_clock` | ui | 时钟图标（HUD 时间） | M3 | generated |
| `art_ui_icon_coin` | ui | 金币图标（HUD 金币） | M3 | generated |
| `art_ui_icon_letter` | ui | 信件图标（HUD 未读） | M3 | generated |
| `art_ui_icon_potion` | ui | 药瓶图标（背包成品） | M3 | generated |
| `art_mob_yelang` | mob | 野狼（实体怪，有影子） | M4 | todo |
| `art_mob_dushe` | mob | 毒蛇（实体怪） | M4 | todo |
| `art_fx_bubbles` | fx | 坩埚气泡/蒸气（循环，video 工作流） | M1 | todo |
| `art_fx_alchemy_glow` | fx | 炼金发光（药绿） | M2 | todo |

> 状态：`todo` → 建文件后 `draft` → 抽 4 挑 1、回填 seed 后 `generated`。
> **素材提示词文件可随时写**；写完即可进 §1.3 流程。

---

## 8. 本契约新定的决策（待评审确认）

| # | 决策 | 理由 |
|---|---|---|
| 1 | 提示词文件用 **Markdown + YAML frontmatter**（而非 JSON）| 人要读、要复制粘贴；结构化字段仍可被脚本解析 |
| 2 | 「正向 / 负向」在素材文件里是**拼好的完整字符串**（不写占位符） | 使用体验优先（复制即用）；一致性靠 §6 的全库替换纪律 |
| 3 | 提示词**一律英文** | 模型语料以英文为主；中文只进 `purpose` 与备注 |
| 4 | 素材 ID 采用 `art_` + 拼音 slug | 与项目既有 ID 纪律（00 契约 §3）一致 |
| 5 | `prompts/` 与 `refs/` 放 `.gdignore` | 防止 Godot 把源数据当资产导入 |
| 6 | ~~风格前缀验证前不批产~~ → **改为：lint 比对 + 抽 4 挑 1** | 前缀仍是全局乘数，但用机器比对（§5.5）比人工预验证便宜且不会漏 |
| 7 | **生成资源分两级：`raw/`（原图）与 `textures/`（成品）** | 原图保真可复现、不进游戏包；引擎只引用成品，来源与产物不混 |
| 8 | 后处理不产生新 art_id | 成品与源共用一个 ID，追溯简单（提示词 → raw → textures 同名） |
| 9 | **全量走纯文生图**（`无参考生图.json`），不装 ControlNet、不装抠底模型 | 8GB 显存 + 低成本定位；结构靠提示词 + 多抽 |
| 10 | `refs/` **暂停使用**，`generate img.json` 降为备用 | 参考图会把 25 个素材的构图互相污染 |
| 11 | 状态机去掉 `approved` 常态环节 | 小游戏不需要单图质量把关；验证成本高于返工成本 |
| 12 | 负向降级为核对清单，约束改写为**肯定句** | 实测 cfg 1.0 / 1.5 下负向与否定式均不可靠 |
| 13 | 全局生成参数（§1.2）**定死，不调参** | 未固定 seed 的差异无法归因，收益抵不上停机时间 |
| 14 | **保留"拼好的完整字符串"**（不改为脚本拼装） | 还要手动开 ComfyUI 贴提示词；一致性改由 §5.5 的 lint 保证 |
| 15 | **提示词可由外部 AI 撰写，验收闸门是 `artgen.py lint`** | 规则只有能自动检查才守得住；文档再细也不会被逐条执行 |
