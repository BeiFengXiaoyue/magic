# 02 · 内核与层间接口契约

> **状态：草案 v0.1**
> 依据：`04-技术/架构设计.md` §4/§5 · `04-技术/Demo 制作计划.md` §3/§5 · `02-玩法/反应与条件.md` §4
>
> 本契约给出**可直接照着写代码的签名**。`核心命题：core / domain / app 三层删掉 engine 后仍能独立运行`。

---

## 1. 内核（`src/core/`）

### 1.1 ContentDatabase —— 内容载入

```gdscript
class_name ContentDatabase

func load_all(path: String = "res://content") -> void      # 失败即 fail-fast，列出全部违规项
func element(id: String) -> Dictionary                     # 含 21 条的任意一条
func material(id: String) -> Dictionary
func recipe(id: String) -> Dictionary
func constant(path: String) -> Variant                     # 点分路径："pricing.elasticity"
func element_order(id: String) -> int                      # elements.json entries 的下标（tie-break 用）
```

### 1.2 ReactionSolver —— K1 查询接口（全作最核心的契约）

> `"组合生成"只是它的 Demo 实现`；全量再加"比例 / 相位 / 变换"三类，**接口不变**。

```gdscript
class_name ReactionSolver

# pool:        {el_id: 元素单位}（正数；未反应原料也是元素）
# conditions:  轴字典 —— Demo 只读 "temperature_c"；
#              全量预留 "pressure_atm" / "ambient" / "spirit_phi" / "catalyst" / "duration_minutes"
#              求解器只读自己认识的轴；未知轴忽略（DEBUG 下警告）—— K7 可插拔
func solve(pool: Dictionary, conditions: Dictionary) -> CraftResult
```

**CraftResult（内核类型，所有下游的锚点）**

```gdscript
class_name CraftResult

var composition: Dictionary   # {el_id: 占比 0~1}，含未反应元素；Σ = 1
var yield_ratio: float        # 产率 = 主产物实际生成量 ÷ 理论最大量（炼制效率）
var dominant: String          # 占比最大的化合物 id；全为游离元素时 = ""
var reaction_log: Array       # [{compound, k, order, consumed: {el_id: 量}}]，order 从 1 起 = 结合顺序
var reading: Dictionary       # {"effects": {eff_id: 读数}, "costs": {cost_id: 读数}}
```

**行为契约**（Demo 计划 §5，逐条落到算法）：

| 情形 | 行为 |
|---|---|
| 单反应 | 解平衡方程 `K = x / ((A₀−a·x)^a · (B₀−b·x)^b)`，取物理根（0 ≤ x ≤ min(A₀/a, B₀/b)） |
| 多反应竞争 | 按 `K` 从大到小**依次结合**（贪心）；每次取该反应满平衡量；元素耗尽即停 |
| K 完全相等 | 按 `elements.json` 的 `entries` 顺序（`ContentDatabase.element_order`） |
| 无可成对 | 全部游离，`composition` = 原料本身 |
| 温度取值 | `conditions.temperature_c`（档位 → 标称温度 + 设备波动，见 §1.5） |
| K 公式 | `K(T) = K_ref(阶) · exp(α · ΔH · τ)`，`τ = (T − T_ref)/100`；轴复合再 `× 100` |
| 产率口径 | `yield_ratio = x / 理论最大量`，理论最大量 = `min(A₀/a, B₀/b)`（**仅主产物**） |
| 读数口径 | `effects[k] = Σ 组分.effects[k] × 占比`；占比按**元素单位**计（二元化合物占 2 单位） |

### 1.3 Projection —— K2 双重语义投影

```gdscript
class_name Projection
static func for_pharmacist(result: CraftResult) -> Dictionary   # 作用 / 代价读数 —— M1 用
static func for_artificer(result: CraftResult) -> Dictionary    # 性质（术师）—— M1 返回 {}，接口留位
```

### 1.4 GameClock —— K3 时间与调度

```gdscript
class_name GameClock

signal hour_passed(hour: float)
signal day_passed(day: int, season: int, year: int)

var minute_of_day: int    # 0 ~ 1200（自 6:00 起算；1200 = 次日 02:00）

func advance(game_minutes: int) -> void            # 室内也流逝（已定）
func real_seconds_for(game_minutes: int) -> float  # = game_minutes × (45/60)
```

跨天结算（灵性代谢、超载扣理智、2:00 昏倒判定）**不在时钟内**，由用例 O5 调各领域完成。

### 1.5 DeterministicRng —— K4

签名与纪律见 [03-determinism-save.md](03-determinism-save.md)。内核内唯一允许的随机来源。

### 1.6 Spirituality —— K5（唯一写入点）

```gdscript
class_name Spirituality

var p: int   # 永久：只增不减
var s: int   # 粘性
var t: int   # 临时

func total() -> int                                  # = p + s + t
func apply_source(source_id: String) -> void         # 读 constants.spirituality.sources 的层与量
func add(layer: String, amount: int, source: String) -> void   # layer: "P"|"S"|"T"
func on_day_passed() -> void                         # T -= daily_t_decay，下限 0
```

> **纪律**：任何领域、任何层，一律经 `apply_source` / `add` 写入；禁止直接改 `p/s/t`。

### 1.7 Knowledge —— K6

```gdscript
class_name Knowledge
func unlock(kind: String, id: String) -> void   # kind: "recipe" | "location" | "concept" | "blueprint"
func has(kind: String, id: String) -> bool
func list(kind: String) -> Array[String]
```

### 1.8 Perception —— ④ 感知通道（唯一特许跨层读）

```gdscript
class_name Perception

# 三种输出形式（架构 §4）
func describe(result: CraftResult, ctx: Dictionary) -> String        # 文字描述（手记/日志）
func readings(result: CraftResult, ctx: Dictionary) -> Dictionary    # 精确读数（设备决定；陶土坩埚 → {}）
func visual(state: Dictionary, ctx: Dictionary) -> Dictionary        # 视觉表现
```

| 方法 | M1 行为 | 输入（ctx 必备键） |
|---|---|---|
| `describe` | 按灵性档位返回不同丰富度的观测文字（低 / 中 / 高 三档，样例见 Demo 计划 §6） | `spirit_total: int` |
| `readings` | 无设备 → `{}`；有设备按精度返回 `{"temperature_c": …, "precision_c": …}` | `device_id: String` |
| `visual` | `{"bubble_level": 0~5, "steam_level": 0~5}`——由 `temperature_c` 落在哪个档区间决定；**气泡/蒸气是唯一的温度反馈** | `temperature_c: float` |

**作用域纪律**：只处理"设计上要求降级或隐藏的信息"（成分、温度读数、作用读数、灵性档位、市场日报）。NPC 位置、库存数量、怪物血量等客观可见物**不走感知**，引擎直接读。

---

## 2. 领域层（`src/domain/`）—— 互不 import，共享只走 core

### 2.1 D1 过程（`domain/process/`）——「一切生产活动的抽象」

```gdscript
class_name ProcessEngine          # 抽象：消耗 → 判定 → 产出
```

**实例一 · 炼制（M1）**

```gdscript
class_name CraftProcess

func start(inputs: Dictionary, conditions: Dictionary) -> CraftSession
    # inputs: {mat_id: 份数}；conditions: {"temperature_tier": "t_low_flame"}
    # 内部：材料 → 元素池（波动经 craft 流）→ ReactionSolver.solve
func tick(session: CraftSession, game_minutes: int) -> void
    # 推进平衡进度（0~1）；广播 session.progress（供引擎画进度条/气泡）
func take_out(session: CraftSession) -> CraftResult
```

**实例二 · 采集（M2）**

```gdscript
class_name GatherProcess
func attempt(node: Dictionary, tool_id: String, rng: DeterministicRng) -> Dictionary
    # 空手率 = 基础率(tier) × 工具修正 × (1 + 天气项)；randf() < 空手率 → 空手
    # 成功 / 空手：理智消耗相同（不减免）；产出 → 库存
```

> 其余六种（种植 / 熔炼 / 加工 / 装配 / 量产 / 仪式）**留位**：它们与炼制、采集同属本抽象，接口不许写死"炼制"。

### 2.2 D2 经济（`domain/economy/`）

```gdscript
class_name Economy

static func coverage(reading: Dictionary, demand: Dictionary) -> float
    # 覆盖率 = Σ min(成品作用_i, 需求作用_i) ÷ Σ 需求作用_i，只统计需求列出的项（数值表 §5.8）
static func list_price(result: CraftResult, demand: Dictionary, ctx: Dictionary) -> int
    # P = clamp(P₀ × 季节系数 × 覆盖率 × (1 − 𝕜_弹性 × max(0, Q/Q_th − 1)), P_floor, P₀×1.3)
```

### 2.3 D3 叙事 / D4 角色

M2 / M3 前补契约。骨架约束：D3 管信件到达、交互、手记写入、指引落地；D4 管 HP / 理智与结算。两者都只经内核类型通信。

---

## 3. 编排层（`src/app/`）—— 用例

### O1 · 炼一炉（M1）

```gdscript
class_name CraftUseCase

func begin(inputs: Dictionary, tier_id: String) -> String     # 返回 session_id；库存不足 → 返回 ""
func tick(game_minutes: int) -> void                          # 推进时钟 + 会话
func take_out() -> CraftResult                                # 产出写入库存
```

**副作用清单（契约）**：扣材料 ✅ ｜ 扣时间（经 GameClock）✅ ｜ 产出入库存 ✅ ｜ **扣理智 ✗（M1 不做，M2 起经 D4 接入）**。

### O2 ~ O5（M2 / M3 / M4 逐步补）

| 用例 | 串起 | 里程碑 |
|---|---|---|
| O2 采一次集 | D1 采集 → D2 入库存 → D4 扣理智 | M2 |
| O3 卖一瓶药 | D1 取出 → D2 定价上架 | M2 |
| O4 读一封信 | D3 到达 → D3 解读 → K5 涨灵性 | M3 |
| O5 过一天 | K3 推进 → D4 结算 → 检查周期事件 | M4 |

---

## 4. 引擎层（`src/engine/`）—— 边界与消息

**职责**：场景、面板栈、角色表现、输入、音频、战斗的空间与时间判定（谁碰到谁、挥击判定、走位、动画）。
**禁止**：算数值（伤害 / 理智 / 产率 / 价格）、直接改内核状态、直接读内核数值（`Perception` 除外）。

### 4.1 事件总线（app 层单例）

```gdscript
# src/app/events.gd —— autoload 名 "Events"
signal action_requested(action: String, payload: Dictionary)   # ② 引擎 → 编排
signal panel_requested(panel: String, params: Dictionary)      # ③ 编排 → 引擎
signal cue_requested(cue: String, params: Dictionary)          # ③ 编排 → 引擎
signal state_changed(scope: String, payload: Dictionary)       # ③ 状态广播（HUD 刷新用）
```

### 4.2 payload 键名契约（M1 首批）

| 信号 | 取值 | payload 键 |
|---|---|---|
| `action_requested` | `"crucible_add"` | `{mat_id: String, count: int}` |
| | `"crucible_remove"` | `{mat_id: String, count: int}` |
| | `"crucible_set_tier"` | `{tier_id: String}` |
| | `"crucible_start"` | `{}` |
| | `"crucible_take_out"` | `{}` |
| `panel_requested` | `"crucible"` / `"journal"` | `{page: "recipes"\|"records"}`（journal 用） |
| `cue_requested` | `"bubbles"` | `{bubble_level: 0~5, steam_level: 0~5}` |
| `state_changed` | `"inventory"` / `"crucible"` / `"money"` | 对应快照字典 |

> 键名即契约：新增 action 必须先在这里登记。

---

## 5. 本契约新定的决策（待评审确认）

| # | 决策 | 理由 |
|---|---|---|
| 1 | `CraftResult` 定为正式内核类型（五字段） | 求解器、经济、手记、测试共用一个锚点，避免各处自造字典 |
| 2 | 温度由编排传入 `temperature_c`；**设备波动亦走确定性随机**（`device` 流） | 波动影响持久产物 ⇒ 按分区纪律必须确定性 |
| 3 | 读数与覆盖率的"占比"按**元素单位**计 | 复现数值表 §5.8 算例（温润汤剂 0.58）的唯一口径 |
| 4 | `visual()` 由 `temperature_c` 决定 0~5 级气泡/蒸气 | "气泡是唯一的温度反馈来源"（已定决策）的机器可读形态 |
| 5 | 事件总线 `Events` 放 app 层；payload 键名登记制 | 引擎与编排解耦；键名漂移 = 破坏性变更 |
