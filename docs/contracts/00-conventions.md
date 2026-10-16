# 00 · 命名与工程规范

> **状态：草案 v0.1**
> 依据：`04-技术/架构设计.md` §2/§3 · `02-玩法/数值表.md` §5.1 · `02-玩法/反应与条件.md` §2
>
> 本契约是所有其他契约与代码共用的底座：ID、单位、目录、命名、纪律。

---

## 1. 技术栈（已定）

| 项 | 决定 |
|---|---|
| 引擎 | Godot **4.7.2** stable |
| 语言 | **GDScript**，全量静态类型（`var x: float`、`func f() -> T`） |
| 数据 | **JSON**（`content/`），数据驱动；代码里不许出现写死的元素/材料/配方 |
| 版本控制 | git（本仓库） |

---

## 2. 目录布局与依赖纪律

### 2.1 布局

```
res://
├─ content/                内容层：纯 JSON，无代码
│  ├─ elements.json        21 种（6 基础 + 15 复合 T1）
│  ├─ materials.json       12 种（Demo 首批）
│  ├─ recipes.json         配方
│  └─ constants.json       全部常量（数值表 §5 的机器可读形态）
├─ src/
│  ├─ core/                共享内核
│  ├─ domain/              领域层：process / economy / narrative / character（子目录互不 import）
│  ├─ app/                 编排层：用例
│  └─ engine/              引擎层：Node、场景、面板、输入
├─ tests/                  headless 测试
└─ docs/contracts/         本目录
```

### 2.2 依赖方向（硬纪律）

依赖只许向下：`content → core → domain → app → engine`。永不上溯。

| 层 | 禁止出现 |
|---|---|
| core / domain / app | 任何 Godot `Node` 类型、`get_tree()`、`preload` 场景 |
| domain | `import` 其他领域的文件（**互不 import**；共享数据只走 core 类型） |
| app | 界面控件（按钮、面板节点）；用例须可在无界面环境跑 |

**唯一例外**：感知通道（`core/perception.gd`）——引擎层可以特许调用它取得"降级后的信息"（文字描述 / 精确读数 / 视觉标记）。除此之外引擎不许读内核数值。

**执行方式**：`tests/test_layer_boundaries.gd` 扫描 `src/` 源码做静态检查（禁词表 + import 图检查），CI 与本地测试均运行。违反即测试失败。

---

## 3. ID 方案

### 3.1 规则

- **拼音小写 + 类别前缀 + 下划线**，全仓库唯一，永不随显示名变化。
- 中文名只作 `name` 字段（显示用）；代码、数据引用一律用 ID。
- 不使用英文意译——90 种元素命名不唯一，拼音与中文名一一对应，最稳。

### 3.2 前缀表

| 前缀 | 用途 | 例 |
|---|---|---|
| `el_` | 元素（基础与化合物统一命名空间；T1~T4 同） | `el_chiran` |
| `mat_` | 材料 | `mat_qinglucao` |
| `eff_` | 作用（16 项） | `eff_xiufu` |
| `cost_` | 代价（6 项） | `cost_zhuotong` |
| `t_` | 温度档（6 档） | `t_mid_flame` |
| `axis_` | 对立轴（3 条） | `axis_chiran_liuzhuan` |
| `rcp_` | 配方 | `rcp_wenrun_tangji` |
| `ltr_` | 信件 | `ltr_L02` |
| `dem_` | 需求（症状） | `dem_fali` |
| `mob_` | 怪物 | `mob_yelang` |
| `itm_` | 物品（药、道具等，材料以外） | `itm_...` |
| `node_` | 采集点 | `node_...` |
| `flg_` | 状态旗标 | `flg_attic_open` |

> **冲突示例**：变易（元素）与 变异（作用）拼音相同——`el_bianyi` / `eff_bianyi`，前缀隔离，合法。

### 3.3 全 ID 表（M1~M3 用到的，实现时照抄）

**元素 · 六基础**

| ID | 名 | h |
|---|---|---|
| `el_chiran` | 炽燃 | +120 |
| `el_liuzhuan` | 流转 | −40 |
| `el_ningding` | 凝定 | −20 |
| `el_misan` | 弥散 | +60 |
| `el_zhixu` | 秩序 | −10 |
| `el_bianyi` | 变易 | 0 |

**元素 · T1 十五复合**（★ = 对立轴）

| ID | 名 | 构成 | ΔH |
|---|---|---|---|
| `el_zhengteng`★ | 蒸腾 | `el_chiran`+`el_liuzhuan` | +80 |
| `el_duanlian` | 煅炼 | `el_chiran`+`el_ningding` | +100 |
| `el_fenlie` | 焚烈 | `el_chiran`+`el_misan` | +180 |
| `el_hengchang` | 恒常 | `el_chiran`+`el_zhixu` | +110 |
| `el_benglie` | 迸裂 | `el_chiran`+`el_bianyi` | +120 |
| `el_shengming` | 生命 | `el_liuzhuan`+`el_ningding` | −60 |
| `el_mimeng` | 迷蒙 | `el_liuzhuan`+`el_misan` | +20 |
| `el_chengqing` | 澄清 | `el_liuzhuan`+`el_zhixu` | −50 |
| `el_fuhuai` | 腐坏 | `el_liuzhuan`+`el_bianyi` | −40 |
| `el_xuanfu`★ | 悬浮 | `el_ningding`+`el_misan` | +40 |
| `el_gouzhu` | 构筑 | `el_ningding`+`el_zhixu` | −30 |
| `el_jibian` | 畸变 | `el_ningding`+`el_bianyi` | −20 |
| `el_zhixi` | 止息 | `el_misan`+`el_zhixu` | +50 |
| `el_youdang` | 游荡 | `el_misan`+`el_bianyi` | +60 |
| `el_beilun`★ | 悖论 | `el_zhixu`+`el_bianyi` | −10 |

**材料 · 首批 12**

| ID | 名 | ID | 名 |
|---|---|---|---|
| `mat_qinglucao` | 清露草 | `mat_shouzhi` | 兽脂 |
| `mat_taiyi` | 苔衣 | `mat_yingmu` | 硬木 |
| `mat_rongyanxie` | 熔岩屑 | `mat_luwei` | 芦苇 |
| `mat_fengshisha` | 风蚀砂 | `mat_yanjing` | 盐晶 |
| `mat_shiyingsha` | 石英砂 | `mat_tongkuangshi` | 铜矿石 |
| `mat_jibianjun` | 畸变菌 | `mat_tiekuangshi` | 铁矿石 |

**作用 16**：`eff_xiufu` 修复 · `eff_jifa` 激发 · `eff_bianyi` 变异 · `eff_zengzhi` 增殖 · `eff_rongjie` 溶解 · `eff_runze` 润泽 · `eff_gujie` 固结 · `eff_kuosan` 扩散 · `eff_shentou` 渗透 · `eff_yiran` 易燃 · `eff_fangfu` 防腐 · `eff_dingxu` 定序 · `eff_zhonghe` 中和 · `eff_zhida` 直达★ · `eff_suqi` 速起★ · `eff_beili` 悖理★

**代价 6**：`cost_zhuotong` 灼痛 · `cost_chongdan` 冲淡 · `cost_chizhi` 迟滞 · `cost_yishi` 逸失 · `cost_yizhi` 抑制 · `cost_buding` 不定

**温度档 6**：`t_ice_bath` 冰浴 · `t_cold_soak` 冷浸 · `t_low_flame` 微火 · `t_mid_flame` 中火 · `t_high_flame` 大火 · `t_raging_flame` 猛火

**轴 3**：`axis_chiran_liuzhuan` · `axis_ningding_misan` · `axis_zhixu_bianyi`

---

## 4. 单位与时间约定

| 量 | 单位 | 说明 |
|---|---|---|
| 温度 | `°C`（float） | 容器工作区 0~800 |
| 时长 | **游戏分钟**（int） | 存储一律用分钟；60 = 1 游戏小时；显示层再换算 |
| 现实↔游戏 | **45 现实秒 = 1 游戏小时**（= 0.75 秒 / 游戏分钟） | |
| 物质量 | **元素单位**（float） | 材料总量 2~6 / 份 |
| 占比 / 读数 | 0~1（float） | |
| 日历 | `year:int(≥1)` · `season:int(0~3)` · `day:int(1~28)` · `hour:float(6.0~26.0)` | 26.0 = 次日 02:00 |
| 金额 | 金币（int） / 炼金印记（int） | 悬空存储，不占背包格 |

---

## 5. 命名约定

| 对象 | 规则 | 例 |
|---|---|---|
| 文件 | `snake_case.gd` | `reaction_solver.gd` |
| 类 | `PascalCase` + `class_name` | `class_name ReactionSolver` |
| 函数 / 变量 | `snake_case` | `solve()`、`element_pool` |
| 常量 | `UPPER_SNAKE` | `TIER_K_REF` |
| JSON 字段 | `snake_case` | `element_total` |
| Godot 信号 | 过去式 | `craft_finished`、`hour_passed` |

---

## 6. 确定性纪律（架构 §4「随机的分区」）

| 类别 | 提供者 | 允许用途 |
|---|---|---|
| **确定性随机** | 内核 `DeterministicRng` | 炼制产率、材料波动、采集空手率、事件掷骰——**一切影响持久状态者** |
| 真随机 | 引擎层（`randf()` 等） | 战斗暴击、动画抖动——一切**不影响持久状态**者 |

- 验收标准"同一种子重跑，结果一致"由本纪律保证。
- 随机流的派生与消费细则见 [03-determinism-save.md](03-determinism-save.md)。

---

## 7. JSON 组织与载入校验

### 7.1 文件结构

```json
{
  "schema_version": 1,
  "entries": [ { "id": "el_chiran", "…": "…" } ]
}
```

`constants.json` 例外：无 `entries`，为分组键值结构（见 01 契约）。

### 7.2 载入校验清单（`ContentDatabase` 启动时强制执行）

1. `schema_version` 与本仓库契约一致；
2. 全库 ID 唯一；
3. 引用完整性：`composition` / `spectrum` / `inputs` / `axis` 中出现的 ID 必须存在；
4. `effects` 键 ∈ 16 作用词表，`costs` 键 ∈ 6 代价词表；
5. `spectrum` 比例之和 = 1 ± 1e-6；
6. `kind="compound"` ⇒ `composition` 非空；`kind="base"` ⇒ `h` 非空；
7. `delta_h` = Σ(系数 × 成分 `h`)，误差 ≤ 1e-6；
8. `axis` 非空 ⇒ 成分恰为轴的两端；
9. 数值域：读数 ∈ [0,1]、`fluctuation` ∈ (0,0.5]、`price` ≥ 0、`element_total` ∈ [0.5,10]；
10. `recipes.temperature_tier` ∈ 温度档表。

任何一条失败 → 启动即报错并列出全部违规项（不静默跳过）。

---

## 8. 数值纪律：禁止魔法数（硬规则）

**数值只有两个合法出处**：

| 出处 | 放什么 | 引用方式 |
|---|---|---|
| `content/constants.json` | 一切**策划可调**的数值：阈值、倍率、时长、消耗、概率、价格、伤害、恢复量、灵性增减…… | `ContentDatabase.constant("pricing.elasticity")` |
| 具名常量（代码内 `const`） | 算法性 / 结构性常数（索引、中性值、数组长度）；**引擎层的表现参数**（动画时长、缓动强度）写成 `const UPPER_SNAKE` | 直接引用常量名 |

**禁止**：

1. 在 `src/core`、`src/domain`、`src/app` 出现任何"策划可调数值"的字面量——**包括它的副本**（"和 JSON 里一样就行了"也不行：改数据时会漂移）。
2. 在 JSON 数据之外再造一份"影子默认值"（如 `var rate := 0.2  # 默认空手率`）——缺省值也属于数据，写进 `constants.json`。
3. 在 `src/engine` 中散落裸数字——表现参数必须先声明为具名常量再引用。

**允许**：`0`、`1`、`-1`、`2` 等用于索引与数学恒等的结构性字面量。
评审尺度：**读代码的人能否一眼断定"这个数字与策划无关"**——不能，就必须抽出去。

**检查方式**：`tests/test_no_magic_numbers.gd` 启发式扫描 `src/core`、`src/domain`、`src/app` 的数字字面量（白名单 0 / 1 / -1 / 2），报警即测试失败；确有必要的豁免须在同行注明 `# no-magic-ok: 理由`。

---

## 9. 本契约新定的决策（待评审确认）

| # | 决策 | 理由 |
|---|---|---|
| 1 | **ID 用拼音**（非英文意译） | 90 种元素可唯一对应；与中文文档一一映射 |
| 2 | **时长存储用游戏分钟**（int） | 采集 10 分钟等精细粒度；小时是显示单位 |
| 3 | **六档标称温度**：10 / 40 / 90 / **200** / 350 / 625 °C | 除中火外取区间中点；**中火取 200** 与 `T_ref` 对齐（设计文档：T_ref 位于中火）|
| 4 | 领域互不 import 由**边界测试强制**（而非口头纪律） | 架构 §3 规则二在 GDScript 无编译期保障 |
