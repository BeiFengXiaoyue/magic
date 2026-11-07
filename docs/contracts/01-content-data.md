# 01 · 内容数据契约

> **状态：草案 v0.3**（M2：items / nodes / forest / base_price；M3：concepts / perception / letters.json 指向 05）
> 依据：`02-玩法/数值表.md` §2/§5 · `02-玩法/反应与条件.md` §2/§4
>
> 内容层是**纯数据**。新增元素 = 加一条数据，不改代码。
> 本节定字段、类型、校验与示例；**数值本身以数值表为准**。

---

## 1. `content/elements.json`

### 1.1 字段

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `id` | string | ✅ | `el_` 前缀 |
| `name` | string | ✅ | 中文显示名 |
| `kind` | `"base"` \| `"compound"` | ✅ | 基础元素 / 化合物 |
| `tier` | int 1~4 | ✅ | 阶；K_ref 基准按它取 |
| `h` | number \| null | base 必填 | 焓贡献（仅基础元素有） |
| `composition` | `{元素id: 系数}` \| null | compound 必填 | 成分与配比（M1 二元全为 1；T2 主导二元为 2:1） |
| `delta_h` | number | ✅ | 总焓：base = `h`；compound = Σ(系数 × `h`)——载入校验 |
| `axis` | string \| null | ✅ | 对立轴 ID；非空 ⇒ `K_ref × 100` |
| `effects` | `{eff_id: 0~1}` | ✅ | 作用读数（数值表 §2.2.1） |
| `costs` | `{cost_id: 0~1}` | ✅ | 代价读数（数值表 §2.2.1） |
| `special_effects` | `[eff_id]` | ✅ | 无读数的轴专属作用：`eff_zhida` / `eff_suqi` / `eff_beili`（M1 不结算，留位） |

### 1.2 示例（两条，其余 19 条照数值表 §2.2.1 录入）

```json
{
  "id": "el_chiran",
  "name": "炽燃",
  "kind": "base",
  "tier": 1,
  "h": 120,
  "composition": null,
  "delta_h": 120,
  "axis": null,
  "effects": { "eff_jifa": 0.9, "eff_yiran": 0.5 },
  "costs": { "cost_zhuotong": 0.6 },
  "special_effects": []
}
```

```json
{
  "id": "el_zhengteng",
  "name": "蒸腾",
  "kind": "compound",
  "tier": 1,
  "h": null,
  "composition": { "el_chiran": 1, "el_liuzhuan": 1 },
  "delta_h": 80,
  "axis": "axis_chiran_liuzhuan",
  "effects": { "eff_jifa": 0.6, "eff_rongjie": 0.5 },
  "costs": { "cost_zhuotong": 0.4, "cost_chongdan": 0.3 },
  "special_effects": ["eff_zhida"]
}
```

---

## 2. `content/materials.json`

### 2.1 字段

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `id` | string | ✅ | `mat_` 前缀 |
| `name` | string | ✅ | |
| `element_total` | number | ✅ | 元素总量（产量规模） |
| `spectrum` | `{el_id: 比例}` | ✅ | 基准比例，和为 1 |
| `fluctuation` | number | ✅ | 波动幅度 σ（比例与总量共用；见 §5 波动裁定） |
| `price` | int | ✅ | 参考价（金币） |
| `habitat` | string | — | 来源地标签（M2 采集用） |

### 2.2 示例

```json
{ "id": "mat_qinglucao", "name": "清露草", "element_total": 3.0,
  "spectrum": { "el_liuzhuan": 0.70, "el_ningding": 0.30 },
  "fluctuation": 0.12, "price": 3, "habitat": "forest_wetland" }
```

```json
{ "id": "mat_taiyi", "name": "苔衣", "element_total": 3.0,
  "spectrum": { "el_ningding": 0.65, "el_liuzhuan": 0.35 },
  "fluctuation": 0.10, "price": 2, "habitat": "old_tree_root" }
```

### 2.3 波动生成细则（投料时执行）

- 每份材料：先掷 `总量 = element_total × U(1−σ, 1+σ)`；再对每个谱项乘 `U(1−σ, 1+σ)`，然后**归一化到 1**。
- 随机数消费顺序：按 `materials.json` 的 `entries` 顺序逐份；同一份内按 `elements.json` 的 `entries` 顺序。
- **投料顺序不影响结果**（消费顺序与玩家操作顺序无关）。
- 随机流：`craft`（见 03 契约）。

---

## 3. `content/recipes.json`

### 3.1 字段

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `id` | string | ✅ | `rcp_` 前缀 |
| `name` | string | ✅ | |
| `inputs` | `{mat_id: 份数}` | ✅ | 投料 |
| `temperature_tier` | string | ✅ | 六档之一 |
| `duration_minutes` | int | ✅ | 游戏分钟（T1 = 60） |
| `base_price` | int | ✅ | 基准价 `P₀`（M2 定价用） |
| `target` | string \| null | — | 预期主产物；**仅供手记显示与测试断言，求解器不读它** |
| `source_letter` | string \| null | — | 来自哪封信（可空 = 自研） |

### 3.2 示例（Demo 两条）

```json
{ "id": "rcp_wenrun_tangji", "name": "温润汤剂",
  "inputs": { "mat_qinglucao": 3, "mat_taiyi": 1 },
  "temperature_tier": "t_low_flame", "duration_minutes": 60,
  "base_price": 12,
  "target": "el_shengming", "source_letter": "ltr_L02" }
```

```json
{ "id": "rcp_tuire_ding", "name": "退热酊",
  "inputs": { "mat_qinglucao": 2, "mat_shiyingsha": 1 },
  "temperature_tier": "t_mid_flame", "duration_minutes": 60,
  "base_price": 10,
  "target": null, "source_letter": "ltr_L04" }
```

---

## 3.5 `content/items.json`（M2）

> 文件结构同 00 §7.1：`{ "schema_version": 1, "entries": [...] }`。
> 物品 = 成品的大类，不是实例。**实例**（每一瓶药）见 02 契约 `ProductInstance`。

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `id` | string | ✅ | `itm_` 前缀 |
| `name` | string | ✅ | 显示名 |
| `category` | `"potion"` \| `"residue"` | ✅ | 类别 |
| `stackable` | bool | ✅ | 药剂不可堆叠（每瓶组成不同）；残渣可堆叠 |

```json
{ "id": "itm_potion", "name": "药剂", "category": "potion", "stackable": false }
{ "id": "itm_residue", "name": "无用残渣", "category": "residue", "stackable": true }
```

## 3.6 `content/nodes.json`（M2）

> 文件结构同 00 §7.1：`{ "schema_version": 1, "entries": [...] }`。

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `id` | string | ✅ | `node_` 前缀 |
| `material_id` | string | ✅ | 产出材料 |
| `tier` | int | ✅ | 采集阶（空手率 / 理智消耗 / 再生天数按它取） |
| `scene` | string | ✅ | 场景 ID（`scene_forest` 等） |
| `position` | `{x:int, y:int}` | ✅ | 场景内坐标（占位美术阶段按色块坐标） |
| `action` | `"gather"` \| `"chop_or_mine"` | ✅ | 决定耗时（10 / 30 游戏分钟） |
| `amount` | int | ✅ | 单次产出份数 |
| `name` | string | — | 手记显示名（M3）；缺省用材料名 |
| `journal_hint` | string | — | 手记里的一句话方位（M3） |

M2 固定 3 个点：`node_taiyi_01/02`（苔衣）、`node_shiyingsha_01`（石英砂）。
M3 追加 `node_qinglucao_rare_01`（稀有清露草，L03 写入手记；节点本身常驻，无可见性门禁）。
清露草与风蚀砂改为野生刷新，规则见 §3.7。
再生：`regrow_at_day = 采集日 + constants.gathering.regrow_days_by_tier[tier]`；M2 存内存（存档 M4 前补）。

```json
{ "id": "node_taiyi_01", "material_id": "mat_taiyi", "tier": 1,
  "scene": "scene_forest", "position": { "x": 980, "y": 360 },
  "action": "gather", "amount": 1 }
```

---

## 3.7 `content/forest.json`（M2）

> 单对象地图文件，无 `entries`。**道路/地形来自地图底图**；本文件只描述地图尺寸、底图引用、出生点/入口、定点景物、刷新区域与野生规则。

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `schema_version` | int | ✅ | 1 |
| `scene` | string | ✅ | `scene_forest` |
| `size` | `{x,y}` | ✅ | 世界尺寸（像素） |
| `walk_margin` | number | ✅ | 可行走边界内缩 |
| `background` | `{art_id, fallback_color}` | ✅ | `art_id` 指向 04 的 `art_scene_forest`；缺图时用 fallback |
| `spawn` | `{x,y}` | ✅ | 玩家出生点 |
| `door` | `{x,y}` | ✅ | 回工坊的门位置 |
| `scenery` | array | ✅ | 定点景物：树/岩石/灌木 |
| `spawn_zones` | array | ✅ | 可刷新的地形区域，按 `habitat` 标签匹配 |
| `wild_spawners` | array | ✅ | 野生资源刷新规则 |

**scenery 条目**：`id`、`kind` ∈ {tree, rock, bush}、`position{x,y}`、`variant`、`scale`、`collision_radius`（0 = 不阻挡）、`art_id`（可为空，留给以后素材）。

**spawn_zones 条目**：

```json
{ "id": "wet_clearing_west", "habitat": "forest_wetland",
  "shape": { "type": "rect", "x": 240, "y": 760, "w": 760, "h": 520 } }
```

或：

```json
{ "id": "ridge_east", "habitat": "mountain_ridge",
  "shape": { "type": "polygon", "points": [ {"x":2000,"y":600}, {"x":2900,"y":500}, {"x":3000,"y":1100}, {"x":2300,"y":1300} ] } }
```

**wild_spawners 条目**：`id`、`material_id`、`tier`、`action`、`amount`、`count`、`habitats`（必须能在 spawn_zones 中找到）、`min_distance`。

规则：

- **没有 `paths`**；代码不绘制道路/网格，地形与道路由 `art_scene_forest` 承载。
- 野生资源只在匹配 `habitat` 的 `spawn_zones` 里布点。
- 开局和跨天刷新；同一天重复进出森林不重掷；新的一天清空未采集的野生点并重刷。
- 运行时 ID：`node_wild_<rule>_<day>_<序号>`；不写入内容 ID 命名空间。
- 野生节点 M2 只存内存；持久化 M4 前补。
- 先填占位坐标/区域；地图图片生成后只改本文件与 `nodes.json`。

---

## 4. `content/constants.json`（机器可读的数值表 §5）

分组键值结构（无 `entries`）。**分组名是契约的一部分**；值以数值表为准。

```json
{
  "schema_version": 1,

  "device": {
    "default_id": "dev_clay_crucible",
    "dev_clay_crucible": {
      "name": "陶土坩埚",
      "temp_jitter_c": 50.0,
      "has_readout": false
    }
  },

  "reaction": {
    "t_ref_c": 200.0,
    "alpha": 0.01,
    "k_ref_by_tier": { "1": 100.0, "2": 1.0, "3": 0.01, "4": 0.0001 },
    "axis_multiplier": 100.0,
    "temperature_range_c": [0, 800],
    "temperature_tiers": [
      { "id": "t_ice_bath",     "name": "冰浴", "range_c": [0, 20],    "nominal_c": 10 },
      { "id": "t_cold_soak",    "name": "冷浸", "range_c": [20, 60],   "nominal_c": 40 },
      { "id": "t_low_flame",    "name": "微火", "range_c": [60, 120],  "nominal_c": 90 },
      { "id": "t_mid_flame",    "name": "中火", "range_c": [120, 250], "nominal_c": 200 },
      { "id": "t_high_flame",   "name": "大火", "range_c": [250, 450], "nominal_c": 350 },
      { "id": "t_raging_flame", "name": "猛火", "range_c": [450, 800], "nominal_c": 625 }
    ],
    "tie_break": "elements_json_order"
  },

  "time": {
    "real_seconds_per_game_hour": 45.0,
    "day_start_hour": 6, "day_end_hour": 26,
    "season_days": 28, "seasons_per_year": 4,
    "craft_minutes_by_tier": { "1": 60, "2": 150, "3": 300, "4": 480 }
  },

  "spirituality": {
    "daily_t_decay": 2,
    "sources": {
      "daily_routine":       { "layer": "T", "amount": 1 },
      "read_mystic_letter":  { "layer": "T", "amount": 2 },
      "read_mystic_deep":    { "layer": "S", "amount": 1 },
      "blind_craft_success": { "layer": "T", "amount": 1 },
      "witness_phantom":     { "layer": "T", "amount": 5 },
      "read_forbidden":      { "layer": "S", "amount": 5 },
      "forbidden_act":       { "layer": "S", "amount": 8 },
      "core_fold_use":       { "layer": "P", "amount": 3 }
    }
  },

  "survival": {
    "sleep_restore": { "hp": 40, "sanity": 30 },
    "sanity_zero_material_loss": 0.20,
    "hp_zero_gold_loss": 0.30,
    "overtime_item_loss": 0.10,
    "hp_start": 100, "sanity_start": 100
  },

  "gathering": {
    "base_miss_rate_by_tier": { "1": 0.20, "2": 0.35, "3": 0.50 },
    "tool_modifier": { "chai_knife": 1.0, "iron_pick": 0.8, "steel_tool": 0.6 },
    "weather_term": 0.0,
    "default_tool": "chai_knife",
    "sanity_cost_by_tier": { "1": 2, "2": 5 },
    "minutes": { "gather": 10, "chop_or_mine": 30 },
    "regrow_days_by_tier": { "1": 3, "2": 7, "3": 14 }
  },

  "pricing": {
    "elasticity": 0.6,
    "mixture_base_price": 8,
    "rolling_window_days": 7,
    "q_th_base": 10,
    "p_floor_mult": 1.1,
    "p_cap_mult": 1.3,
    "reputation_mult": { "high": 1.3, "mid": 1.0, "low": 0.8 },
    "season_mult": { "0": 1.3, "1": 1.4, "2": 1.3, "3": 1.5 }
  },

  "matching": {
    "premium_threshold": 0.8, "normal_threshold": 0.5,
    "premium_mult_range": [1.2, 1.3]
  },

  "letter_interaction": {
    "burn_safe_seconds": 3.0,
    "burn_rate_per_second": 0.20,
    "salvage_window_seconds": 5.0,
    "repair_cost_by_tier": { "1": 200, "2": 600, "3": 1500 },
    "puzzle_hint_wrong_count": 5,
    "puzzle_fallback_wrong_count": 10
  },

  "vocabulary": {
    "effects": {
      "eff_xiufu": "修复", "eff_jifa": "激发", "eff_bianyi": "变异", "eff_zengzhi": "增殖",
      "eff_rongjie": "溶解", "eff_runze": "润泽", "eff_gujie": "固结", "eff_kuosan": "扩散",
      "eff_shentou": "渗透", "eff_yiran": "易燃", "eff_fangfu": "防腐", "eff_dingxu": "定序",
      "eff_zhonghe": "中和"
    },
    "costs": {
      "cost_zhuotong": "灼痛", "cost_chongdan": "冲淡", "cost_chizhi": "迟滞",
      "cost_yishi": "逸失", "cost_yizhi": "抑制", "cost_buding": "不定"
    },
    "special_effects": { "eff_zhida": "直达", "eff_suqi": "速起", "eff_beili": "悖理" },
    "axes": {
      "axis_chiran_liuzhuan": ["el_chiran", "el_liuzhuan"],
      "axis_ningding_misan": ["el_ningding", "el_misan"],
      "axis_zhixu_bianyi": ["el_zhixu", "el_bianyi"]
    }
  },

  "demo": {
    "world_seed": 9173271,
    "starting_inventory": {
      "mat_qinglucao": 5, "mat_taiyi": 5, "mat_rongyanxie": 5, "mat_fengshisha": 5,
      "mat_shiyingsha": 5, "mat_jibianjun": 5, "mat_shouzhi": 5, "mat_yingmu": 5,
      "mat_luwei": 5, "mat_yanjing": 5, "mat_tongkuangshi": 5, "mat_tiekuangshi": 5
    }
  },

  "demand": {
    "spring_early": {
      "id": "dem_fali", "name": "乏力",
      "needs": { "eff_xiufu": 0.5, "eff_zhonghe": 0.3 },
      "days": [1, 7], "season": 0
    }
  }
}
```

> `season_mult` 的键用 `season:int` 的字符串形式（JSON 键必为字符串）。
> 配方未注明时长时，按配方所属阶从 `time.craft_minutes_by_tier` 兜底。

### 4.1 M3 新增常量组

以下两组并入 `constants.json`（完整字段与语义见 05 §3.4/§3.5）：

```json
"perception": {
  "spirit_tiers": { "mid": 4, "high": 6 }
},
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

- `perception.spirit_tiers` 只决定 `Perception.describe` 的描述丰富度；Demo 初值，正式阈值待补数值表 §1.1。
- `concepts` 是手记词条（以及后续字谜词条）的标签唯一出处；不存数值。
- `letter_interaction` 组在 M3 **不消费**（火烤/焦页/修复后置），保留给后续里程碑。

---

## 5. 本契约新定的决策（待评审确认）

| # | 决策 | 理由 |
|---|---|---|
| 1 | **材料库存只记份数；波动在"投料时"由 `craft` 流生成** | 每份成分独立随机 ⇒ 库存不必存每份成分；大数定律在投料时刻体现；存档极简（见 03 契约） |
| 2 | `special_effects` 单独存放（不塞进 `effects`） | 直达/速起/悖理**无读数**，混入会污染覆盖率求和 |
| 3 | `recipes.target` 仅供显示与断言 | 防止实现者拿它当"产物"绕过求解器（违背架构 K1） |
| 4 | `constants.json` 带 `demand` 组（虽是叙事/经济内容） | M2 的固定需求必须在数据里，否则"卖不掉"验收无输入 |
| 5 | 材料波动同时作用于**总量与比例**（每份独立、均匀分布 U(1−σ, 1+σ)） | 复现数值表 §2.4 两个校验区间（10.5~13.5 与 6.5~8.2）的唯一口径 |
| 6 | 词表与轴映射的机器可读出处 = `constants.vocabulary`（16 作用 / 6 代价 / 3 轴） | 校验与 M3 手记共用；词表不能只活在正文表格里 |
| 7 | M1 产物只存内存 `Inventory.products`，不进存档 | items.json 属 M2；见 02 契约 §1.9 |
| 8 | `constants.demo` 承载开局演示数据（世界种子、初始库存） | M1 无采集与商店；M2 起由采集替代，此组可删 |
| 9 | 配方带 `base_price`（P₀）；乱投产物兜底 `pricing.mixture_base_price` | 乱投没有配方，P₀ 必须有兜底 |
| 10 | 森林地图/布点放 `forest.json`；道路/地形由地图底图承载，野生资源按 habitat 区域每日刷新（`wild` 流） | 以后按地图特点调整资源点只改 JSON，不改代码 |
| 11 | `items.json` 只定义物品大类；每瓶药的实例见 02 `ProductInstance` | 药剂不可堆叠，实例携带自身组成 |

---

## 6. 后续文件（M2+，契约待补）

| 文件 | 内容 | 需要它的里程碑 |
|---|---|---|
| `letters.json` | 信件（字段以 [05 契约](05-letters-guidance.md) §3 为准） | M3 |
| `demands.json` | 若需求泛化，从 `constants.demand` 独立 | M2 收尾 |
| `monsters.json` + 涂层 | 野狼/毒蛇、五行涂层（数值表 §5.5/§5.11） | M4 |
| `items.json` 扩展 | 灰烬残页、道具等（大类契约已转正为 §3.5）| M4 |
