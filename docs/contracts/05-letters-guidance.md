# 05 · 信件与引导契约（M3 · 普通信件）

> **状态：草案 v0.2**（M3 范围收窄：只做普通信件，不做解密/交互）
> 依据：`04-技术/Demo 制作计划.md` §三/§四/§六 · `01-叙事/信件与事件.md` §1/§2 · `02-玩法/游戏设计.md` §八/§11.4/§12 · `02-玩法/数值表.md` §5.2/§5.9/§5.10 · `04-技术/架构设计.md` §四/§五
>
> **2026-11-07 范围裁决**：M3 只做**最普通的信件**——到达、阅读、浅层解锁、手记、灵性、指引。
> 火烤 / 蘸水 / 折叠 / 字谜 / 焦页 / 修复全部**不在 M3**，见 §12「后置清单」。这样 M3 的核心是「信驱动玩家」，而不是先做一套解读小游戏。
>
> 00~04 已定义的字段不重复；M3 新增的字段、ID、事件键名以本文为准。

---

## 0. 范围与验收

### 0.1 本契约交付什么

| 编号 | 层 | 交付 | 本文对应 |
|---|---|---|---|
| C5 | 内容 | `content/letters.json`：L01~L05 正文、到达条件、浅层解锁 | §3 |
| D3 | 领域 | `LetterBook` / `LetterState` / `Journal`：到达、阅读、手记 | §5 |
| K5 | 内核 | `Spirituality` 定稿：三层、来源、每日衰减、感知档位 | §4.2 |
| K6 | 内核 | `Knowledge` 定稿：配方 / 地点 / 概念 / 图纸 | §4.3 |
| — | 内核 | `Flags`：布尔世界状态（M3 新增） | §4.1 |
| O4 | 编排 | `LetterUseCase`：到达检查、读信、视图 | §6.1 |
| O5-min | 编排 | `DayUseCase`：每日 T 衰减 + 信件到达检查 | §6.3 |
| E7-lite | 引擎 | `LetterPanel`：信纸阅读（**无互动按钮**） | §7.1 |
| E3 | 引擎 | `JournalPanel`：配方页 / 记录页（散记 → 标准表） | §7.2 |
| — | 引擎 | 旧木箱 / 门口信盘两个交互点；HUD 新信角标 | §7.3/§7.4 |

**明确不做（M3）**：火烤、蘸水、折叠、字谜、翻面、焦页、修复、灰烬残页；阁楼独立场景、商队场景、存档落盘、完整 O5、P 三级锚定、天气、NPC 对话、机械路线。后置理由与扩展点见 §12。

### 0.2 验收路径（30 分钟，M3 人工验收）

> 设计文档的「30 分钟内被 L01~L05 自然引导」与「L02 第 2 天 / L03 第 4 天 / L04 第 6 天 / L05 第 8 天」直接冲突：一天 20 游戏小时 = 15 现实分钟，第 8 天在第 105 分钟。M3 采用**压缩链**（§1.1），日期只作为全量版的备用条件。

| 时间 | 玩家动作 | 期望 | 涉及 |
|---|---|---|---|
| 0~2 min | 开局在工坊，看见旧木箱 | 交互提示「旧木箱」；锅暂时不能开 | L01 到达、坩埚门禁 |
| 2~4 min | 开箱读 L01 | 信纸正文可读；坩埚解锁；门口信盘出现 L02 角标 | `flg_crucible_unlocked` |
| 4~6 min | 读 L02 | 手记配方页出现「温润汤剂」；L03 到达 | `rcp_wenrun_tangji`、`cpt_huohou` |
| 6~12 min | 读 L03，去森林采清露草×3、苔衣×1 | 手记记录页出现「南坡清露草」线索 | notes、`node_qinglucao_rare_01` |
| 12~18 min | 回工坊，微火炼一炉并取出 | 手记记录页出现一条**散记** | O1 + Journal |
| 18~20 min | 去小店卖出 | 金币增加；首次卖出置旗 | `flg_first_sale` |
| 20~24 min | 回工坊，读 L04 | 记录法变**标准表**；退热酊进配方页；「压力」进概念 | `cpt_jilu_biaozhun`、`cpt_yali` |
| 24~28 min | 再炼一炉退热酊（可选） | 新记录以**四栏表**呈现，「压力」灰显 | Journal |
| 28~30 min | 读 L05 | 胡克的信直接点出「压力」；手记线索增加 | `cpt_kongzhi_li`、`flg_pressure_clue` |

**验收硬指标**：

- **浅层永不丢失**：信一旦送达，正文永久可读；M3 没有焦页，所以不存在「读不到」。
- **无教程弹窗**：引导只来自信、环境交互提示与 HUD 的「新信」角标；不出现任务箭头、目标列表、强制对话。
- **确定性**：同一操作序列重放，`letters / journal / flags / spirit` 快照逐字段一致。
- **灵性可见**：同一炉产物在灵性总值 0 与 ≥6 时，`Perception.describe` 返回不同丰富度的文字；手记记录的是**取出当时**的文字，不随后续灵性变化重算。

---

## 1. 设计裁剪与关键裁决

### 1.1 到达节奏：压缩链（Demo）替代日历日

| 设计写法 | 问题 | M3 裁决 |
|---|---|---|
| L02 第 2 天、L03 第 4 天、L04 第 6 天、L05 第 8 天 | 第 8 天 = 105 现实分钟，30 分钟验收不可能 | Demo 用**因果链**：L02 读 L01 后；L03 读 L02 后；L04 在「L03 已读 + 首次卖出」后；L05 读 L04 后。全量版再把 `day` 条件加回数据即可，不改代码 |

- 到达条件由数据描述，`letters.json` 同时支持 `day` / `after_letter` / `flag` / `knowledge`；Demo 只用后三者。
- **为什么 L02 在 L03 前**：信件目录是 L02→L03；「配方先给、材料后指」也成立——玩家读完配方发现没材料，下一封信正好指路。
- **L04 要求「L03 已读 + 首次卖出」两个条件**：只挂首次卖出会让玩家在跳过 L02/L03 时提前拿到 L04，破坏引导链。

### 1.2 阁楼：Demo 不新增场景，旧木箱放工坊

- Demo 范围只有工坊 / 小店 / 森林三场景；阁楼不在其中。
- M3 在工坊内放 `attic_box`（旧木箱）作为 L01 的取信点；全量版再拆出阁楼场景。
- L01 文本里的「阁楼」保持原文；Demo 的箱子上写「旧木箱」，交互提示不写「阁楼」，避免与场景不符。
- L01 浅层原文「去阁楼，看看那口箱子」在 Demo 里是**叙事回响**（信本就在箱中，你已经开了箱）；实际指引由「坩埚解锁」承担。

### 1.3 L01 的门禁：坩埚在读完 L01 前不可用

- 设计写 L01「拾取即得——坩埚与原料架可用」。M2 里坩埚一直可用；M3 把它改成 `flg_crucible_unlocked` 控制，读完 L01 置位。
- 这是 M3 唯一新增的操作门禁；不改变炼制数值与流程，M1/M2 的直接用例测试不受影响。
- 未解锁时交互提示：「锅是冷的。先看看那只旧木箱。」——这是环境提示，不是教程弹窗。

### 1.4 L04 的灵性产出：机械线 = 无

- 信件目录写 L04「T +微量」；游戏设计 §12.7 与「污染来自内容」写**机械路线的信（伊萨克、玛格丽特）无灵性产出**。
- 以 §12.7 为准：L04（玛格丽特）`on_read = null`。其余四封为神秘线：读信 T+2。
- 灵性按**信的数据字段**发放，不按作者硬编码；以后加信只填字段。

### 1.5 感知阈值：Demo 用 4 / 6，并迁入 constants

- 现有 `Perception` 把中/高档阈值写死为 30/60（`no-magic-ok` 占位）。M3 只有「读神秘信 T+2」这一种来源，30 分钟最多 T=8，30/60 永远看不到变化。
- 新增 `constants.perception.spirit_tiers = { "mid": 4, "high": 6 }`；`Perception.describe` 只读常量。
- 这只是**描述丰富度**阈值，不是 P 的「微光/洞见/沉沦」锚定阈值；后者 M4 再定。

### 1.6 L05：普通信，不出谜题

- 设计里 L05 是字谜＋翻面；M3 不做解密，L05 改成**普通信**：胡克直接把谜底「压力」写出来，并补一句「玛格丽特那张表第四栏空着，不是她忘了」。
- 这样玩家不需要词条栏/答错计数/翻面，仍然拿到「压力」概念与加压装置的线索。
- 字谜系统本身不删设计，见 §12；以后加 `puzzle` 字段即可。

### 1.7 其它裁剪

| 项 | 裁决 |
|---|---|
| 商队送达 | M3 不实现商队；L05 投到门口信盘，`carrier = "caravan"` 只作显示文案 |
| 稀有采集点 | `node_qinglucao_rare_01` 一直在森林里；L03 只是把它写进手记（`Knowledge.location`），不做隐藏/生成门禁 |
| 灰烬残页 | M3 不做物品化；焦页/修复整体后置 |
| 旧记录格式 | 每条记录在**创建时**固化 `format`；L04 解锁后不改写旧条目（玩家自己的历史） |
| 知识是否影响炼制 | **不影响**。配方匹配、反应求解、产物生成都不查 `Knowledge`；知识只影响手记显示与指引 |
| `letters` 随机流 | M3 **不消费**。到达条件全是确定的；留作全量版送达抖动/随机信 |
| 每日衰减 | M3 加 `DayUseCase` 最小实现：跨天时 T−2 + 信件到达检查；睡眠/生存/M4 结算不接 |
| 取信快捷键 | 不提供全局取信键；玩家到旧木箱/信盘交互，保持物理投递。`J` 只开手记 |

---

## 2. 数据流总览

```
GameClock.day_passed ──> DayUseCase.on_day_passed()
                          ├─ Spirituality.on_day_passed()      # T -= 2
                          └─ LetterUseCase.refresh()           # 到达检查

SellUseCase.sell() ──成功且首次──> Flags.set("flg_first_sale")

CraftUseCase.take_out() ──成功──> Journal.add_craft_entry()
                                    └─ Perception.describe(result, {spirit_total})

InteractUseCase.handle("attic_box" | "mail_tray")
        └─> panel_requested("letters", {source})

LetterUseCase.open(id)
        ├─ Spirituality.apply_source(on_read)
        ├─ Knowledge.unlock(...) / Flags.set(...)
        ├─ Journal.add_note(...)
        └─ LetterUseCase.refresh()          # 链式下一封
```

**分层纪律**：`LetterBook` / `Journal` 在 `domain/narrative/`，只依赖 `core`（ContentDatabase / GameClock / Spirituality / Knowledge / Flags / Perception）；`LetterUseCase` 在 app 层，把 D3 的结果翻译成事件与 UI 视图；引擎不直接读 `LetterBook` 的状态。

---

## 3. 内容：`content/letters.json`（C5）

### 3.1 文件结构

```json
{
  "schema_version": 1,
  "entries": [ { "id": "ltr_L01", "…": "…" } ]
}
```

与 00 §7.1 一致；ID 前缀 `ltr_`，全库唯一。

### 3.2 字段

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `id` | string | ✅ | `ltr_` 前缀，如 `ltr_L02` |
| `tier` | int 1~3 | ✅ | 信件阶级；M3 不用于修复，保留给后续 |
| `author` | `{id, name, handwriting}` | ✅ | `handwriting` 是美术笔迹资源键（M3 可空字符串） |
| `title` | string | ✅ | 信件标题（面板列表用） |
| `arrival` | object | ✅ | 到达条件与投递点，见 §3.2.1 |
| `body` | string | ✅ | 信纸正文；M3 只有这一层，永久可读 |
| `unlocks` | object | — | 读信后解锁，见 §3.2.2 |
| `spirituality` | `{on_read}` | ✅ | 常量来源 ID 或 `null`，见 §3.2.3 |

> M3 **不出现** `deep` / `puzzle` / `shallow.kind` 等字段；出现即校验失败（后置扩展时再放开）。见 §12。

#### 3.2.1 `arrival`

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `delivery` | `"attic_box"` \| `"mail_tray"` | ✅ | 物理取信点；M3 只有这两个 |
| `carrier` | `"box"` \| `"door"` \| `"caravan"` \| `"npc"` | ✅ | 显示用送达方式；L05 用 `caravan` 但物理仍在信盘 |
| `conditions` | `{ "all": [...] }` 或 `{ "any": [...] }` | ✅ | 二选一；条件数组非空 |

**条件对象**（`type` 必填）：

| `type` | 字段 | 含义 |
|---|---|---|
| `day` | `min: int` | `GameClock.today() >= min` |
| `after_letter` | `id: ltr_*` | 该信 `status == "read"` |
| `flag` | `id: flg_*` | `Flags.has(id)` |
| `knowledge` | `kind: recipe\|location\|concept\|blueprint`, `id` | `Knowledge.has(kind, id)` |

- 同一封信只会投递一次；条件之后变假不回收。
- 到达检查顺序 = `entries` 数组顺序；同一帧内新投递的信可以立刻成为下一封的条件（链式）。
- `delivery = attic_box` 只用于 L01；其余用 `mail_tray`。

#### 3.2.2 `unlocks`

```json
{
  "recipes": ["rcp_wenrun_tangji"],
  "concepts": ["cpt_huohou"],
  "locations": ["node_qinglucao_rare_01"],
  "flags": ["flg_crucible_unlocked"],
  "notes": ["南坡湿地：清露草（野生）"]
}
```

- `recipes` → `Knowledge.unlock("recipe", id)`；`concepts` → `"concept"`；`locations` → `"location"`；`flags` → `Flags.set_flag(id)`。
- `notes` → `Journal.add_note(text, letter_id)`，显示在记录页「线索」区。
- 全部操作幂等；重复 `open` 不重复解锁/发灵性。

#### 3.2.3 `spirituality`

| 字段 | 类型 | 说明 |
|---|---|---|
| `on_read` | source_id \| null | 首次读到正文时发放；对应 `constants.spirituality.sources` |

- M3 只允许 `read_mystic_letter` 或 `null`；机械线（L04）用 `null`。
- `on_deep` 字段后置（§12），M3 不出现。
- 发放由 `LetterBook` 做幂等（`awards.read`），`Spirituality.apply_source` 只负责加减。

### 3.3 L01~L05 的 M3 数据表

> 正文以设计文档为准；本表只定**契约字段的取值**。`day` 条件是全量版备用，Demo 用因果链。

| 信 | 到达（Demo） | 投递 | 正文要点 | 解锁 | 灵性 `on_read` |
|---|---|---|---|---|---|
| `ltr_L01` | `day ≥ 1` | `attic_box` / `box` | 埃利奥特留给后来者；锅、架子、炉子还能用 | `flg_crucible_unlocked` | `read_mystic_letter` |
| `ltr_L02` | `after_letter L01` | `mail_tray` / `door` | 凝定主修复，流转主载；温润汤剂：清露草×3 + 苔衣×1，微火 1h | `rcp_wenrun_tangji`、`cpt_huohou` | `read_mystic_letter` |
| `ltr_L03` | `after_letter L02` | `mail_tray` / `door` | 南坡雾低处有清露草；拔根，根是甜的 | notes「南坡湿地：清露草（野生）」、`node_qinglucao_rare_01`、notes「露根密丛：稀有清露草」 | `read_mystic_letter` |
| `ltr_L04` | `all: after_letter L03, flag flg_first_sale` | `mail_tray` / `door` | 一次只改一个变量；附四栏记录表；退热酊：清露草×2 + 石英砂×1，中火 1h | `rcp_tuire_ding`、`cpt_yali`、`cpt_jilu_biaozhun`、`cpt_kongzhi_bianliang`、notes「记录表：改了什么 / 其他条件 / 结果 / 压力」 | `null` |
| `ltr_L05` | `after_letter L04` | `mail_tray` / `caravan` | 胡克的谜语；直接把谜底「压力」写出，并指向玛格丽特的表 | `cpt_yali`（幂等）、`cpt_kongzhi_li`、`flg_pressure_clue` | `read_mystic_letter` |

- L05 不再要求玩家作答；正文里直接出现「压力」，所以 `cpt_yali` 即使已由 L04 解锁也是幂等 no-op。
- L05 的 `flg_pressure_clue` 在 Demo 只作手记线索，不接购买；加压装置是全量内容。

### 3.4 `constants.concepts`（M3 新增）

```json
"concepts": {
  "cpt_huohou": "火候",
  "cpt_pingheng": "平衡",
  "cpt_nongdu": "浓度",
  "cpt_yali": "压力",
  "cpt_jilu_biaozhun": "标准记录",
  "cpt_kongzhi_bianliang": "控制变量",
  "cpt_kongzhi_li": "控制力"
}
```

- 概念是「玩家已经能命名的词」，不是数值；标签唯一出处在这里。
- `cpt_jilu_biaozhun` 同时是记录格式的开关：`Knowledge.has("concept", "cpt_jilu_biaozhun")` ⇒ 标准表。

### 3.5 `constants.perception`（M3 新增）

```json
"perception": {
  "spirit_tiers": { "mid": 4, "high": 6 }
}
```

- 只用于 `Perception.describe` 的描述丰富度；不是 P 锚定阈值。
- Demo 初值，跑起来再校准；正式值补数值表 §1.1。

### 3.6 `content/nodes.json` 的 M3 增补

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `name` | string | — | 手记显示名，如「露根密丛」；缺省用材料名 |
| `journal_hint` | string | — | 手记里的一句话方位，如「南岸水边，树根背阴处」 |

新增一个固定点（Demo 里一直存在，只是 L03 后才会被写进手记）：

```json
{
  "id": "node_qinglucao_rare_01",
  "material_id": "mat_qinglucao",
  "tier": 1,
  "scene": "scene_forest",
  "position": { "x": 1680, "y": 1760 },
  "action": "gather",
  "amount": 3,
  "name": "露根密丛",
  "journal_hint": "南岸水边，树根背阴处"
}
```

- 不引入 `requires` 字段；「开放」= 写进手记，不是物理生成。
- 原有三个节点可补 `name` / `journal_hint`，不强制。

### 3.7 载入校验（追加到 00 §7.2）

1. `letters.json` 的 `schema_version = 1`；`id` 以 `ltr_` 开头且唯一。
2. `tier ∈ 1~3`；`author.name` 非空；`title` 非空；`body` 非空。
3. `arrival.delivery ∈ {attic_box, mail_tray}`；`carrier ∈ {box, door, caravan, npc}`；`conditions` 恰有 `all` 或 `any` 之一，数组非空。
4. 条件引用存在：`after_letter.id` 是已定义信件；`flag.id` 以 `flg_` 开头；`knowledge.id` 在对应表里；`day.min ≥ 1`。
5. `after_letter` 图无环；L01 不得有 `after_letter` 条件。
6. `unlocks.recipes` 的每个 ID 存在于 `recipes.json`；`concepts` 存在于 `constants.concepts`；`locations` 存在于 `nodes.json`；`flags` 以 `flg_` 开头；`notes` 为字符串数组。
7. `spirituality.on_read` 为 `null` 或 ∈ `constants.spirituality.sources`；M3 只允许 `read_mystic_letter`。
8. M3 **拒绝** `deep` / `puzzle` / `shallow` 字段；出现即报「M3 不实现解密」。
9. L01~L05 在数据里全部可达：从 `day=1` 的初始状态出发，按 `all` 条件求值能依次投递五封（可用测试静态模拟）。
10. `nodes.json` 的 `name` / `journal_hint` 若存在必须为字符串；`node_qinglucao_rare_01` 的 `amount ≥ 1`。

---

## 4. 核心类型（K5 / K6 / Flags / 感知）

### 4.1 `Flags` —— 布尔世界状态（`src/core/flags.gd`，M3 新增）

```gdscript
class_name Flags

var data: Dictionary   # {flag_id: Variant}

func set_flag(id: String, value: Variant = true) -> void
func has(id: String) -> bool          # 只看键是否存在，不判断值真假
func value(id: String) -> Variant
func snapshot() -> Dictionary
func restore(snapshot: Dictionary) -> void
```

- 只存**布尔/简单标量**世界状态；复杂状态（信件、库存）不进 Flags。
- `has(id)` 只看键是否存在；需要真假时用 `value(id)`。
- M3 用到的旗标：
  - `flg_crucible_unlocked`：L01 解锁；控制坩埚可用。
  - `flg_first_sale`：`SellUseCase` 首次成功卖出时置位；L04 到达条件。
  - `flg_pressure_clue`：L05 解锁；Demo 只作手记线索，不接购买。

### 4.2 `Spirituality` —— K5 唯一写入点（定稿）

```gdscript
class_name Spirituality

var p: int   # 永久：只增不减
var s: int   # 粘性
var t: int   # 临时

func total() -> int                                   # = p + s + t
func apply_source(source_id: String) -> void          # 读 constants.spirituality.sources
func add(layer: String, amount: int, source: String) -> void   # layer: "P"|"S"|"T"
func on_day_passed() -> void                          # T -= daily_t_decay，下限 0
func perception_tier() -> String                      # "low" | "mid" | "high"
func snapshot() -> Dictionary                         # {p, s, t}
func restore(snapshot: Dictionary) -> void
```

**行为契约**：

- `add("P", …)` 的 `amount` 必须 ≥ 0；P 只增不减。S/T 允许负值（净化/压制），但结果下限 0。
- `apply_source` 只查 `constants.spirituality.sources`；未知 ID → `push_error` 且不改状态。
- `on_day_passed` 只做 `t = max(0, t - daily_t_decay)`；S 不自然衰减，P 不动。
- `perception_tier` 用 `constants.perception.spirit_tiers`：`total < mid → low`，`mid ≤ total < high → mid`，`≥ high → high`。
- **纪律**：任何领域/编排改灵性，只经 `apply_source` / `add`；禁止直接写 `p/s/t`。M3 不实现 P 三级锚定、净化、压制。
- **每次发灵性必须幂等**：幂等由 `LetterBook` 的 `awards` 负责；`Spirituality` 本身不做去重。

> M3 只消费 `read_mystic_letter`（T+2）；`read_mystic_deep` / `read_forbidden` 等来源保留给 §12 的深层解读与全量内容。

### 4.3 `Knowledge` —— K6（定稿）

```gdscript
class_name Knowledge

func unlock(kind: String, id: String) -> void   # kind: recipe | location | concept | blueprint
func has(kind: String, id: String) -> bool
func list(kind: String) -> Array[String]        # 按解锁顺序
func snapshot() -> Dictionary                   # {recipes, locations, concepts, blueprints}
func restore(snapshot: Dictionary) -> void
```

- `kind` 非法 → `push_error` 且忽略；重复 `unlock` 是 no-op。
- `list` 保持**解锁顺序**（手记很好用；不排序）。
- ID 方案：配方 `rcp_*`、地点 `node_*`（本契约用节点 ID 当地点）、概念 `cpt_*`、图纸 `bp_*`（M4）。
- **知识只影响文档/指引，不影响物理**：`CraftProcess` / `ReactionSolver` / `Economy` 不查 `Knowledge`。

### 4.4 `Perception` —— 阈值迁入 constants

- 删除 `SPIRIT_TIER_MID/HIGH` 硬编码；`describe` 读 `constants.perception.spirit_tiers`。
- 输入 `ctx` 仍为 `{spirit_total: int}`；M3 的记录文字在**取出时**生成一次，之后不重算。
- 三档文字只改「描述丰富度」，不改任何数值；`readings` / `visual` 不变。

---

## 5. 领域 D3（`src/domain/narrative/`）

### 5.1 `LetterState` —— 单封信的运行时状态

```gdscript
class_name LetterState

var id: String
var status: String          # "pending" | "delivered" | "read"
var delivered_day: int      # 0 = 未投递
var read_day: int           # 0 = 未读
var awards: Dictionary      # {read: bool}
```

- `status` 只前进：`pending → delivered → read`；重复打开不改变状态。
- `unread`：`status == "delivered"`（读过就不再算新信）。
- M3 没有深层/焦化/字谜状态；这些字段后置到 §12。

### 5.2 `LetterBook` —— 到达与阅读

```gdscript
class_name LetterBook

func _init(
    db: ContentDatabase,
    clock: GameClock,
    flags: Flags,
    knowledge: Knowledge,
    spirituality: Spirituality,
    journal: Journal
) -> void

# —— 查询 ——
func entry(id: String) -> Dictionary
func state(id: String) -> LetterState
func delivered_ids() -> Array[String]       # 含 read
func unread_ids() -> Array[String]
func is_delivered(id: String) -> bool

# —— 到达 ——
func refresh_arrivals() -> Array[String]    # 新投递的 ID，按 entries 顺序

# —— 阅读 ——
func open(id: String) -> Dictionary
# {ok, reason, letter, unlocks, award}
# reason: "ok" | "not_delivered" | "unknown"

# —— 存档 ——
func snapshot() -> Dictionary
func restore(snapshot: Dictionary) -> void
```

**`open` 的副作用（一次性）**：

1. 若 `status != "read"`：`status = "read"`，`read_day = clock.today()`。
2. 应用 `unlocks`：配方/概念/地点/旗标/线索。
3. 若 `spirituality.on_read != null` 且 `awards.read == false`：`apply_source(on_read)`，置 `awards.read = true`。
4. 返回正文与解锁结果；重复 `open` 只返回视图，不重复副作用。

**`refresh_arrivals`**：

- 遍历 `db.letter_ids()`（entries 顺序），对 `status == "pending"` 的信求值 `arrival.conditions`。
- 满足则 `status = "delivered"`、`delivered_day = clock.today()`，加入返回数组。
- 同一帧内新投递的信可以立刻满足下一封的 `after_letter` 条件。
- 幂等：重复调用不会重复投递。

### 5.3 `Journal` —— 手记（E3 的数据源）

```gdscript
class_name Journal

func _init(db: ContentDatabase, knowledge: Knowledge, perception: Perception) -> void

func add_craft_entry(result: CraftResult, ctx: Dictionary) -> Dictionary
# ctx: {inputs, tier_id, duration_minutes, device_id, spirit_total, day, minute_of_day}
func add_note(text: String, source_letter: String = "") -> void

func record_format() -> String                 # "prose" | "table"
func records_view() -> Array[Dictionary]
func recipes_view() -> Array[Dictionary]
func locations_view() -> Array[Dictionary]
func notes_view() -> Array[Dictionary]
func snapshot() -> Dictionary
func restore(snapshot: Dictionary) -> void
```

**记录条目字段**（`records_view` 的每个元素）：

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | string | `jrn_0001` 递增 |
| `day` | int | 发生日 |
| `minute_of_day` | int | 发生时刻 |
| `format` | `"prose"` \| `"table"` | **创建时固化**，之后不改 |
| `inputs` | `{mat_id:int}` | 改了什么 |
| `tier_id` | string | 火候档 |
| `duration_minutes` | int | 目标时长 |
| `device_id` | string | 设备（陶土坩埚） |
| `observation` | string | `Perception.describe(result, {spirit_total})` 的结果 |
| `dominant` | string | 主产物元素 ID（内部/测试用；表格不显示数字） |
| `yield_ratio` | float | 产率（内部/测试用；表格不显示数字） |
| `spirit_total` | int | 取出时灵性总值 |
| `columns` | object | 仅 `format="table"`：`{changed, conditions, result, pressure}` |
| `text` | string | 仅 `format="prose"`：整段散记 |

**两种格式**：

- **散记（L04 前）**：`text` 为一段口语描述，例如：
  「第 1 天，微火，清露草×3、苔衣×1。一炉温热的混合物。你隐约觉得它以生命为主。」
- **标准表（L04 后）**：四栏，`pressure` 恒为 `null`，UI 显示灰色「—」：
  - 改了什么：`清露草×3、苔衣×1`
  - 其他条件：`微火 · 60 分钟 · 陶土坩埚`
  - 结果：`一炉温热的混合物。你隐约觉得它以生命为主。`
  - 压力：`—`（灰）
- `record_format()` 只决定**新条目**用哪种格式；旧条目保留自己的 `format`。
- `recipes_view`：只列 `Knowledge.list("recipe")` 的配方；从 `recipes.json` 取投料、火候、时长、`source_letter`；未读 L02/L04 时不显示。
- `locations_view`：`Knowledge.list("location")` 的节点 ID → `nodes.json` 的 `name` / `journal_hint` / `scene` / 材料名；用于记录页「已知采集点」。
- `notes_view`：`{text, source}` 数组，按写入顺序。
- M3 不写「修复记录」；`Journal` 只有炼制记录 + 笔记。

### 5.4 指引落地（D3 的「指引」部分）

| 信 | 落地方式 | 数据 |
|---|---|---|
| L01 | 坩埚解锁 | `flg_crucible_unlocked` |
| L03 | 手记记录页出现南坡清露草线索 | `notes` |
| L03 | 稀有采集点写进手记 | `Knowledge.unlock("location", "node_qinglucao_rare_01")` |
| L04 | 记录法切标准表；「压力」进概念 | `cpt_jilu_biaozhun` / `cpt_yali` |
| L05 | 加压装置线索 | `flg_pressure_clue`、`cpt_kongzhi_li` |

- 不做「任务目标」状态机；指引就是信 + 手记 + 环境提示。
- `flg_crucible_unlocked` 是唯一操作门禁；其余解锁只影响文档与提示。

---

## 6. 编排层（O4 / O5-min）

### 6.1 `LetterUseCase` —— O4 读一封信

```gdscript
class_name LetterUseCase

func _init(
    db: ContentDatabase,
    letters: LetterBook,
    journal: Journal,
    spirituality: Spirituality,
    knowledge: Knowledge,
    publisher: CraftEventPublisher
) -> void

func refresh() -> Array[String]          # 到达检查 + 广播；返回新投递 ID
func open(id: String) -> Dictionary      # 正文阅读；成功后自动 refresh（链式下一封）

# —— UI 视图 ——
func list_view(source: String = "") -> Array[Dictionary]   # source: "attic_box"|"mail_tray"|""（全部）
func letter_view(id: String) -> Dictionary
func journal_view(page: String) -> Dictionary   # page: "recipes" | "records"
```

- `open` / `refresh` 成功后发布：
  - `state_changed("letters", {delivered, unread})`
  - `state_changed("letter", {letter_id, status, delivered_day, read_day})`
  - 若灵性变化：`state_changed("spirit", {p,s,t,total,tier})`
  - 若知识/旗标变化：`state_changed("knowledge", …)` / `state_changed("journal", …)` / `state_changed("flags", …)`
  - 新信投递：`cue_requested("mail_arrived", {ids})`
- `list_view(source)` 只返回该取信点送达的信（`entry.arrival.delivery == source`）；空串返回全部。这样旧木箱面板不会凭空看到后来投到信盘的信。
- `letter_view(id)` 的 `unlocks` 已解析为显示名：配方名、概念标签、地点名、备注原文；引擎不需要查内容库。
- `journal_view("recipes")` 返回 `journal.recipes_view()`；`"records"` 返回 `{records, locations, notes, format}`。
- **引擎不直接读 `LetterBook` / `Journal`**；只消费 `LetterUseCase` 的视图字典与事件 payload。

### 6.2 O4 的完整流程

```
引擎: interact("attic_box" | "mail_tray")
  → InteractUseCase → panel_requested("letters", {source})
  → LetterPanel 打开，调用 LetterUseCase.list_view(source)

玩家点一封信
  → action_requested("letter_open", {letter_id})
  → LetterUseCase.open(id)
      → 标记 read；发 on_read；应用 unlocks；写 notes
      → refresh()（可能投递下一封）
      → 返回 letter_view；面板刷新
```

### 6.3 `DayUseCase` —— O5-min

```gdscript
class_name DayUseCase

func _init(spirituality: Spirituality, letters: LetterUseCase) -> void

func on_day_passed(day: int, season: int, year: int) -> void
```

- 顺序：`spirituality.on_day_passed()` → `letters.refresh()`。
- `GameClock.day_passed` 连接到它；M4 的 O5 在这里扩展生存/睡眠/市场/周期事件。
- M3 不处理「2:00 未睡」与睡眠恢复；跨天只发生 T 衰减与信件检查。

### 6.4 O1 / O3 的 M3 钩子

**`CraftUseCase`**（O1）：

- 构造函数增加可选 `journal: Journal = null`、`spirituality: Spirituality = null`；为 `null` 时行为与 M1/M2 完全一致（现有测试不受影响）。
- `take_out()` 成功（`progress >= 1`）后，若 `journal != null`。先取 `var session := _session`，再按现有逻辑 `_session = null`；记录用的是取出前的会话。
  ```gdscript
  journal.add_craft_entry(result, {
      "inputs": session.inputs.duplicate(),
      "tier_id": session.tier_id,
      "duration_minutes": session.duration_minutes,
      "device_id": _db.constant("device.default_id"),
      "spirit_total": spirituality.total() if spirituality != null else 0,
      "day": _clock.today(),
      "minute_of_day": _clock.minute_of_day,
  })
  ```
- **不**在 `take_out` 里发 `daily_routine` / `blind_craft_success` 灵性；M3 的灵性来源只有读信。M4 再接日常经营。

**`SellUseCase`**（O3）：

- 构造函数增加可选 `flags: Flags = null`。
- 成功卖出且 `flags != null` 且 `!flags.has("flg_first_sale")`：`flags.set_flag("flg_first_sale")`，发布 `state_changed("flags", {changed, value})`。
- 不依赖 D3；不直接投递 L04。**装配根在每次成功卖出后调用 `LetterUseCase.refresh()`**（幂等、很便宜），让「L03 已读 + 首次卖出」的 L04 立刻投递。`main._sell_product` 里加这一行即可；测试可直接调 `letters.refresh()`。

**启动与跨天的到达检查**：

- `main._ready()` 组装完成后调用一次 `LetterUseCase.refresh()`，投递 L01（`day ≥ 1`）。
- `DayUseCase.on_day_passed()` 每次跨天再调用一次；`LetterUseCase.open()` 成功后也调用一次（链式下一封）。
- 三处入口都是同一个幂等方法；重复调用不会重复投递。

---

## 7. 引擎层（E7-lite / E3）

### 7.1 `LetterPanel`（`src/engine/ui/letter_panel.gd`）

**布局**：

```
┌──────────────────────────────────────────────────────────────┐
│ 信件                                              [关闭]      │
├──────────────┬───────────────────────────────────────────────┤
│ 已送达列表    │ 信纸（art_ui_letter_paper，缺图用纸张色）       │
│ · L01 新      │  标题 / 作者 / 送达方式                        │
│ · L02 已读    │  正文（永久可读）                              │
│ · L04 已读    │  ── 你记下了 ──                                │
│              │  温润汤剂 / 火候 / 南坡清露草                   │
└──────────────┴───────────────────────────────────────────────┘
```

- 列表项显示：标题、作者、状态角标（新 / 已读）。
- 正文始终可读；M3 **没有任何火烤/蘸水/折叠/字谜/翻面按钮**。
- 「你记下了」区把 `unlocks` 翻译成可读条目：
  - 配方 → 名称（从 `recipes.json`）
  - 概念 → `constants.concepts` 标签
  - 地点 → `nodes.json` 的 `name`
  - 备注 → 原文
  - 旗标不显示（内部状态）。
- 缺 `art_ui_letter_paper` 时用 `UiTheme` 的纸张色 + 边框；不影响功能。
- 面板来源（`source`）由 `panel_requested("letters", {source})` 带入；只列该取信点的信。

### 7.2 `JournalPanel`（`src/engine/ui/journal_panel.gd`）

**入口**：`J` 键；或交互 `journal_desk`（M3 可选，工坊手记台已存在则接）。`Esc` 关闭。

**两页**：

| 页 | 内容 | 数据源 |
|---|---|---|
| 配方（`recipes`） | 已知配方列表：名称、投料、火候、时长、来源信 | `LetterUseCase.journal_view("recipes")` |
| 记录（`records`） | 记录条目（散记/表格）、已知采集点、线索 | `journal_view("records")` |

- 配方页只显示 `Knowledge.list("recipe")`；未读 L02/L04 时为空或「还没有记下任何配方」。
- 记录页按条目自己的 `format` 渲染：
  - `prose`：一段文字。
  - `table`：四栏；`压力` 列灰显 `—`。
- 已知采集点：`locations_view` 的列表（名称 + 场景 + 一句话方位 + 材料）。
- 线索：`notes_view` 的自由文本。
- 记录页顶部显示当前记录法：「记录法：散记 / 标准表（L04）」。
- 不提供编辑、排序、筛选；M3 只读。

### 7.3 小店柜台

- M3 **没有**信件修复区；`ShopPanel` 保持 M2 的商品列表与报价。
- 修复整体后置（§12）。

### 7.4 场景交互点（`SceneLayout` / `WorldView` / `InteractUseCase`）

| `target_id` | 场景 | 位置建议 | 行为 |
|---|---|---|---|
| `attic_box` | 工坊 | 床边/角落，约 80×70 | 打开信件面板（L01 来源）；无信时「空的」 |
| `mail_tray` | 工坊 | 底墙门旁，约 60×40 | 打开信件面板；无信时「门口没有信」 |
| `dev_clay_crucible` | 工坊 | 现有 | 未解锁 `flg_crucible_unlocked` → 提示「锅是冷的。先看看那只旧木箱。」；已解锁 → 开坩埚面板 |
| `shop_counter` | 小店 | 现有 | 开小店面板（M2 行为不变） |

- `attic_box` / `mail_tray` 的显示尺寸、碰撞箱、交互矩形由 `SceneLayout` 同源定义；M3 可先用占位色块，不阻塞。
- `InteractUseCase` 增加可选 `flags: Flags = null`；`dev_clay_crucible` 在 `flags != null && !flags.has("flg_crucible_unlocked")` 时返回提示，不开面板。`attic_box` / `mail_tray` 发 `panel_requested("letters", {source})`。
- 交互提示：`attic_box` → 「旧木箱」；`mail_tray` → 「信盘」。
- L01 读完后旧木箱不再产出新信；`mail_tray` 是唯一后续取信点。

### 7.5 事件总线新增键名（登记到 02 §4.3）

**`action_requested`**：

| action | payload | 说明 |
|---|---|---|
| `letter_open` | `{letter_id: String}` | 打开一封已送达的信（标记已读） |
| `journal_open` | `{page: String}` | `"recipes"` / `"records"` |

**`panel_requested`**：

| panel | params |
|---|---|
| `letters` | `{source: "attic_box"\|"mail_tray"\|"", letter_id?: String}`（空串 = 全部） |
| `journal` | `{page: "recipes"\|"records"}` |

**`cue_requested`**：

| cue | payload |
|---|---|
| `mail_arrived` | `{ids: [String]}` |

**`state_changed`**：

| scope | payload |
|---|---|
| `letters` | `{delivered: int, unread: int}` |
| `letter` | `{letter_id, status, delivered_day, read_day}` |
| `spirit` | `{p, s, t, total, tier}`（**隐藏值**：只给手记/调试，HUD 不显示数字） |
| `knowledge` | `{recipes: [String], locations: [String], concepts: [String], blueprints: [String]}` |
| `journal` | `{entries: int, notes: int, format: String}` |
| `flags` | `{changed: String, value: Variant}`（可选；首次卖出等） |

- 新增键名必须先登记在本节，再写代码；与 02 §4.3 的 M1/M2 表合并使用。
- M3 **没有** `letter_act` / `letter_repair` / `letter_burn`；这些后置（§12）。

### 7.6 HUD

- 新增「信」角标：`state_changed("letters")` 的 `unread` > 0 时显示数字；**不提供全局取信快捷键**——玩家到旧木箱/信盘交互取信，保持物理投递。`J` 只开手记。
- 不显示灵性数字；不显示任务目标；不显示「下一步」箭头。
- `state_changed("spirit")` 只用于调试面板（H 键）与手记记录，不接 HUD 常驻显示。
- 交互提示继续用 `hint_changed`；`attic_box` / `mail_tray` 的提示由 `WorldView` 给出。

---

## 8. 存档与确定性

### 8.1 存档字段（M3 内存；M4 落盘）

> M3 **不实现** `save()` / `load()`；以下字段用于 `snapshot()` / `restore()` 与 M4 存档对齐。字段名即契约。

```jsonc
{
  "letters": {
    "ltr_L01": {
      "status": "read",              // pending | delivered | read
      "delivered_day": 1,
      "read_day": 1,
      "awards": { "read": true }
    }
  },
  "journal": {
    "next_id": 2,
    "entries": [
      {
        "id": "jrn_0001",
        "day": 1,
        "minute_of_day": 240,
        "format": "prose",
        "inputs": { "mat_qinglucao": 3, "mat_taiyi": 1 },
        "tier_id": "t_low_flame",
        "duration_minutes": 60,
        "device_id": "dev_clay_crucible",
        "observation": "一炉温热的混合物。你隐约觉得它以生命为主。",
        "dominant": "el_shengming",
        "yield_ratio": 0.87,
        "spirit_total": 4,
        "columns": {},
        "text": "第 1 天，微火，清露草×3、苔衣×1。……"
      }
    ],
    "notes": [
      { "text": "南坡湿地：清露草（野生）", "source": "ltr_L03" }
    ]
  },
  "flags": {
    "flg_crucible_unlocked": true,
    "flg_first_sale": true,
    "flg_pressure_clue": true
  }
}
```

- `spirit` / `knowledge` 字段沿用 03 §3.2 的 `{p,s,t}` 与 `{recipes,locations,concepts,blueprints}`。
- `letters` 只存运行时状态，不存正文/解锁定义（正文在 `letters.json`）。
- `snapshot()` 可以只写非 `pending` 的信；`restore()` 时缺失的信一律视为 `pending`。
- 旧记录格式不改写；`format` 是条目字段。

### 8.2 随机纪律

- **M3 不消费 `letters` 流**：到达条件全是确定的。
- 若未来加「送达抖动/随机信」，只能消费 `letters` 流，并按 03 §2 的消费纪律。

### 8.3 `snapshot()` / `restore()` 的验收

- `LetterBook.snapshot()` 返回 §8.1 的 `letters` 对象；`restore()` 后 `delivered_ids` / 阅读状态 / 发奖幂等一致。
- `Journal.snapshot()` 返回 `journal` 对象；`restore()` 后条目顺序与 `next_id` 一致。
- `Flags.snapshot()` / `Spirituality.snapshot()` / `Knowledge.snapshot()` 各自往返。
- 测试：同一动作序列跑两遍，快照逐字段相等；换一个 `world_seed` **不应**改变信件结果（M3 信件无随机）。

---

## 9. 测试

### 9.1 新增测试文件

| 测试 | 覆盖 |
|---|---|
| `tests/test_letters_content.gd` | L01~L05 数量、ID、条件引用、DAG、body、unlocks 引用、spirituality.on_read、rare node、M3 拒绝 deep/puzzle |
| `tests/test_letter_lifecycle.gd` | L01 开局投递；L02→L03→L04（首次卖出）→L05；`after_letter` 只在 read 后满足；重复 open 不重复发奖/解锁；首次卖出旗标 |
| `tests/test_spirituality.gd` | 来源表、P 只增、S/T 下限、每日衰减、perception_tier 阈值、snapshot/restore |
| `tests/test_knowledge_flags.gd` | unlock/has/list 顺序、重复 no-op、非法 kind、Flags 读写/快照 |
| `tests/test_journal.gd` | L04 前 prose、L04 后 table；旧条目 format 不变；压力列为 null；locations/notes；snapshot/restore |
| `tests/test_letter_guidance.gd` | 模拟 30 分钟链：L01→L02→L03→采集→炼制→卖出→L04→L05；坩埚门禁 |
| `tests/test_letter_determinism.gd` | 固定动作序列，两次快照一致；`letters` 流状态不变 |
| `tests/test_perception_spirit.gd` | 同一 result 在 total 0/4/6 下的 describe 不同；阈值来自 constants |

### 9.2 现有测试的影响

- `test_content_load.gd`：新增 `letters.json` 与 `constants.concepts/perception` 的正例；坏数据负例（重复 `ltr_`、`after_letter` 指向不存在、body 为空、unlocks 引用不存在、出现 `deep`/`puzzle`）。
- `test_layer_boundaries.gd`：`src/domain/narrative/` 不得 import `engine`/`app`/其它领域；`src/app/letter_use_case.gd` 不得出现 Node/控件。
- `test_no_magic_numbers.gd`：`perception` 阈值全部来自 constants；`LetterState` 的结构性 0/1/-1 允许。
- `test_determinism.gd`：不需要改；M3 的确定性由新测试覆盖。
- `test_scene_layout.gd`：新增 `attic_box` / `mail_tray` 的尺寸、碰撞、交互矩形、不重叠检查（若这轮加进布局）。

### 9.3 静态检查

- `letters.json` 的 `after_letter` 图必须无环（Kahn 或 DFS）。
- 所有 `unlocks.recipes` 的 `source_letter` 必须等于该信 ID（与 `recipes.json` 交叉校验）；若配方没有 `source_letter` 则跳过。
- `letters.json` 不得出现 `deep` / `puzzle` / `shallow`。
- `spirituality.on_read` 只允许 `read_mystic_letter` 或 `null`。

---

## 10. 实现顺序（M3）

```
C5  letters.json + constants.concepts/perception + nodes 增补 + 校验
      ↓
K5  Spirituality 定稿 + K6 Knowledge 定稿 + Flags + Perception 阈值迁移
      ↓
D3  LetterState / LetterBook / Journal
      ↓
O4  LetterUseCase + O5-min DayUseCase + CraftUseCase/SellUseCase 钩子
      ↓
E7-lite LetterPanel + E3 JournalPanel + HUD 角标
      ↓
场景  attic_box / mail_tray + 坩埚门禁 + 事件接线
      ↓
测试（§9）+ 30 分钟人工验收（§0.2）
```

- 先做 D3 + O4 的无界面流程（可用测试驱动），再做面板；面板不得反向影响领域规则。
- 美术 `art_ui_letter_paper` / `art_ui_journal` 为 04 契约的 M3 `todo`；缺图时用 `UiTheme` 纸张色/边框，不阻塞。

---

## 11. 本契约新定的决策（待评审确认）

| # | 决策 | 理由 | 需谁拍板 |
|---|---|---|---|
| 1 | **M3 只做普通信件，不做解密** | 用户 2026-11-07 明确收窄；先验证「信驱动玩家」 | 已定 |
| 2 | **Demo 用压缩链到达**（读信/卖出驱动），日历日仅作全量备用 | 第 8 天 = 105 现实分钟，与 30 分钟验收冲突 | 策划 |
| 3 | **阁楼不建场景，旧木箱放工坊** | Demo 场景范围只有三个；阁楼是建筑内部，M4 再拆 | 策划/实现 |
| 4 | **L04 灵性 = 无**（机械线） | 游戏设计 §12.7「污染来自内容」优先于信件目录的「T +微量」 | 策划 |
| 5 | **感知阈值 Demo = 4 / 6** | M3 只有读信 T+2，30/60 不可达；4/6 在 30 分钟内可见 | 策划 |
| 6 | **L05 改成普通信，直接给出「压力」** | 不做解密；保留胡克信与概念线索 | 已定 |
| 7 | **知识不影响炼制物理** | 保持 K1/K2 的独立性；知识只决定「你能不能看懂/记下」 | 实现 |
| 8 | **旧日记条目保留创建时的格式** | L04 教的是「怎么记」，不是改写历史 | 策划 |
| 9 | **L05 商队只作文案，物理投信盘** | M3 不做周期事件；商队场景 M4 补 | 实现 |
| 10 | **`letters` 流 M3 不消费** | 到达全确定；避免无意义的随机消费 | 实现 |
| 11 | **M3 只加最小 O5（T 衰减 + 到达检查）** | 跨天必须有衰减，否则 T 只涨不落；完整 O5 在 M4 | 实现 |
| 12 | **L03 稀有采集点常驻，知识只负责标注** | 不做隐藏生成/可见性门禁；玩家提前发现也算发现 | 策划 |
| 13 | **火烤/蘸水/折叠/字谜/焦页/修复全部后置** | 见 §12；M3 先把信读到、记下、用上 | 已定 |
| 14 | **不提供全局取信快捷键** | 保持物理投递；玩家到木箱/信盘取信 | 实现 |

---

## 12. 后置清单（M3 不做；设计已存在，扩展时照此接）

> 这些不是删掉，是**推迟**。M3 的 `letters.json` 不出现相关字段；以后加回时按本节扩展，不推翻已有结构。

| 后置项 | 设计依据 | 扩展点 |
|---|---|---|
| 火烤（3 秒安全窗、20%/秒焦化、5 秒挽救、8 秒焦页） | 信件与事件 §1.4；数值表 §5.6 | `letters.json` 增加 `deep: {method:"fire", text}`；`LetterState` 增加 `deep_status` / `burn_ratio` / `heating` / `deep_ever_opened`；`LetterBook` 增加 `heat_tick` / `heat_release`；`LetterUseCase` 增加 `act`；事件增加 `letter_act` / `letter_burn` |
| 蘸水 | 信件与事件 §1.4；L03 | `deep.method="dip"`；`LetterBook.dip`；无风险 |
| 折叠（四栏碎片按序拼接） | 信件与事件 §1.4；L04 | `deep.method="fold"` + `fold.fragments/order`；`LetterBook.fold` |
| 字谜（词条栏、答错 5/10 次提示、翻面） | 信件与事件 §1.6；L05 | `letters.json` 增加 `puzzle`；`shallow.kind="puzzle"`；`Knowledge.list("concept")` 词条栏；`LetterBook.answer` / `flip`；`LetterUseCase.wordbank` |
| 焦页/修复（柜台、按 tier 收费、修复记录） | 信件与事件 §1.4；数值表 §5.6 | `LetterState` 的 burn/deep 字段；`LetterBook.repair`；`Wallet`；`Journal` 增加 `add_letter_event`；`ShopPanel` 修复区；`letter_repair` action |
| 灰烬残页 | 游戏设计 §11.5 | `items.json` 增加 `itm_ash_page`；库存扩展；M4 |
| L05 的字谜保底（没读 L04 → 没有「压力」词条） | 信件与事件 §2.2 | 与 `puzzle` 一起恢复；词条栏 = `Knowledge.list("concept")` + `puzzle.terms` |

**恢复时不得改动的 M3 结构**：`arrival` 条件、`unlocks`、`spirituality.on_read`、`Journal` 的记录格式、`Flags`、事件键名 `letter_open`/`mail_arrived`/`letters`/`letter`；只做**增量**字段与方法。

---

## 13. 与 00~04 的衔接

| 契约 | 本契约新增/改动 |
|---|---|
| 00 | 新增 ID 前缀 `cpt_`（概念）；载入校验追加 `letters.json`（§3.7） |
| 01 | `constants` 新增 `concepts` / `perception` 组；`letters.json` 字段以本文 §3 为准；`nodes.json` 补 `name` / `journal_hint` |
| 02 | §2.3 D3 由「M3 前补」改为指向本文；§3 O4 签名以本文 §6.1 为准；§4.3 事件键名并入本文 §7.5 |
| 03 | `letters` / `journal` / `flags` 存档字段以本文 §8.1 为准；`letters` 流 M3 不消费 |
| 04 | `art_ui_letter_paper` / `art_ui_journal` 为 M3 `todo`；缺图回退 `UiTheme`；M3 不新增场景美术 |
