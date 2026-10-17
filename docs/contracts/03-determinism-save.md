# 03 · 确定性与存档契约

> **状态：草案 v0.1**
> 依据：`04-技术/架构设计.md` §4「随机的分区」· `02-玩法/游戏设计.md` §存档 · `04-技术/Demo 制作计划.md` 验收标准
>
> 验收标准"**同一种子重跑，结果一致**"由本契约保证。它成立与否，取决于随机是否被严格分区。

---

## 1. 种子与流派生

```gdscript
class_name DeterministicRng

func init_world(seed_value: int) -> void
func stream(name: String) -> RandomNumberGenerator   # 返回该流的 RNG（持久引用）
func snapshot() -> Dictionary                        # {stream_name: rng.state}
func restore(data: Dictionary) -> void
```

- `world_seed: int`——新游戏时生成，写入存档，**永不变**。
- 派生：`stream_seed(name) = hash("codex:%d:%s" % [world_seed, name])`。
- **M1 固定种子**：`constants.demo.world_seed`（= 9173271）——用于复现与测试；M2 起新游戏随机生成。
- 流清单（M1~M3）：

| 流 | 消费点 |
|---|---|
| `craft` | 材料波动（总量与比例）、炼制相关随机 |
| `gather` | 采集空手率判定 |
| `device` | 设备温度波动（陶土坩埚 ±50°C） |
| `market` | 市场日报、需求刷新偏向 |
| `event` | 周期事件判定 |
| `letters` | 信件相关随机（送达抖动等，M3） |

---

## 2. 消费纪律

1. **只有影响持久状态的随机才进流**：产率、波动、空手率、事件掷骰、设备温度波动。
   真随机（真 `randf()`）**只许**用于战斗暴击、动画抖动、粒子偏移。
2. **流的消费顺序必须由游戏状态唯一确定**——"同样的操作序列 + 同种子 ⇒ 同结果"。
   - ✅ 允许：`craft` 流在"投料"和"取出"两个确定节点消费。
   - ❌ 禁止：打开面板看气泡、UI 刷新、预览等**交互式反复询问**消费任何流。
3. 每条流只在自己的业务模块消费；跨模块借用流 = 破坏性变更。
4. 禁止直接 `randomize()`；禁止把 `RandomNumberGenerator` 实例跨业务复用。

**校验**：`tests/test_determinism.gd` —— 固定种子执行一段 M1 脚本（投料→炼制→取出→若干天），**重放两遍逐字段比对**；再换种子跑一遍，确认结果**不同**（防"其实是写死的"）。

---

## 3. 存档契约（v1）

### 3.1 时机

| 时机 | 行为 |
|---|---|
| 睡觉 | **自动存档**（星露谷式）；3 个存档位 |
| 炼制中 / 加工中 | **禁止存档**（防读档刷产率）——`save()` 前置检查，拒绝并提示 |
| 白天手动 | M1 不做手动存档（与设计文档一致） |

### 3.2 字段清单（JSON，与 content 同格式族）

```jsonc
{
  "save_version": 1,
  "meta":      { "world_seed": 9173271, "saved_at": "...", "play_time_minutes": 0 },
  "calendar":  { "year": 1, "season": 0, "day": 1, "minute_of_day": 0 },   // minute_of_day 0~1200（6:00 起算）
  "player":    { "hp": 100, "sanity": 100, "scene": "workshop", "position": { "x": 0.0, "y": 0.0 } },
  "spirit":    { "p": 0, "s": 0, "t": 0 },
  "money":     { "gold": 0, "seals": 0 },
  "inventory": { "mat_qinglucao": 3, "mat_taiyi": 1 },                      // 材料只记份数（见 01 契约 §5）
  "products":  { },                                                          // M1 不存（产物在内存，见 02 §1.9）；M2 起 {itm_id: count}
  "knowledge": { "recipes": [], "locations": [], "concepts": [], "blueprints": [] },
  "letters":   { },                                                          // {ltr_id: {state, burn, repaired}}
  "crucible":  null,                                                         // 炼制中不允许存档 ⇒ 恒为 null
  "nodes":     { },                                                          // {node_id: {regrow_at_day}}（M2 起）
  "market":    { "reputation": "mid", "rolling_q": [], "day_stock": {} },    // M2 起
  "flags":     { },
  "rng":       { "craft": "0", "gather": "0", "device": "0", "market": "0", "event": "0", "letters": "0" }
}
```

| 规则 | 说明 |
|---|---|
| 键名即契约 | 新增持久状态必须同时更新本节 + 存档测试 |
| `rng` 存每条流的 `rng.state` | 恢复后连续消费与不存档时完全一致 |
| `rng` 的 state 以**十进制字符串**存储 | Godot JSON 解析数字为 float，64 位 state 会被截断 |
| 不存派生数据 | 覆盖率、价格、气泡级别等可以由状态重算的一律不存 |
| `save_version` | 不等则拒绝加载并提示；迁移策略 v1 暂不实现 |

### 3.3 待定与待补清单

**机制待裁决**

- **跨日炼制（T4）期间的存档**：设计文档写"炼制中不可存档"，而 T4 跨日又必须睡觉——两者冲突将在 M4（T4 进入视野）前裁决。Demo 不存在该情形。
- 手动存档 / 多档位 UI：M4+。

**接口待补（不阻塞 M1）**

| 项 | 需要它的时机 |
|---|---|
| 存档路径 / 槽位 / `save()` / `load()` API（建议 `user://saves/slot_<n>.json`）| M2 |
| `Economy.list_price` 的 `P₀` 出处（constants 或 items.json）| M2 |
| `Knowledge.kind` 的 `blueprint` 与存档字段对齐（存档已加 `blueprints: []`）| M3 |
| 事件 / 信件字段的机器可读化 | M3 |
| CI 配置 / `.editorconfig` / 仓库 AGENTS.md | 后置 |

---

## 4. 本契约新定的决策（待评审确认）

| # | 决策 | 理由 |
|---|---|---|
| 1 | 设备温度波动走 `device` 流（确定性） | 它改变产物 ⇒ 属"影响持久状态"，不许真随机 |
| 2 | 存档用 JSON | 与 `content/` 同格式族，人可读、可 diff、可手工造测试档 |
| 3 | `crucible` 字段恒 `null`（因炼制中禁存档） | 把"禁止"变成结构上不可能，而非运行时检查 |
| 4 | 换种子必须改变结果（测试显式断言） | 防止"确定性"被实现成"写死" |
| 5 | `rng` 的 state 存十进制字符串 | Godot JSON 解析数字为 float，64 位 state 会丢精度 |
