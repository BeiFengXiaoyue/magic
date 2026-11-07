# 规范契约（Contracts）

> 设计文档回答"游戏怎么玩"；**契约回答"代码里字段叫什么、接口长什么样"**。
> 契约与设计文档冲突时：**以设计文档为准**，并回来修正契约。

## 清单

| # | 契约 | 覆盖 | 状态 | 主要依据 |
|---|---|---|---|---|
| 00 | [命名与工程规范](00-conventions.md) | ID 方案、单位、目录、依赖与确定性纪律、校验清单 | 草案 | 架构设计 §2/§3；数值表 §5.1 |
| 01 | [内容数据契约](01-content-data.md) | `elements / materials / recipes / constants` 的字段与载入校验 | 草案 | 数值表 §2、§5；反应与条件 §2/§4 |
| 02 | [内核与层间接口契约](02-core-api.md) | K1~K7 内核 API、四通道消息、D1 领域与 O1 用例签名 | 草案 | 架构设计 §4/§5；Demo 计划 §3/§5 |
| 03 | [确定性与存档契约](03-determinism-save.md) | 种子流派生、随机消费纪律、存档字段清单 | 草案 | 架构设计 §4；游戏设计 §存档 |
| 04 | [美术素材与提示词契约](04-art-assets.md) | 工作流对接、素材 ID、提示词格式与书写规则、素材清单 | 草案 | 美术风格（全篇）；本机 ComfyUI 工作流 |
| 05 | [信件与引导契约](05-letters-guidance.md) | 普通信件（无解密）：`letters.json`、D3 信件/手记、K5/K6、E7-lite/E3、O4 | 草案 v0.2 | 信件与事件 §1/§2；游戏设计 §8/§11.4/§12；数值表 §5.2/§5.9/§5.10 |

## 状态

- **草案**：可讨论，字段可能变。
- **评审**：已冻结讨论，等待一方（策划 / 实现）确认。
- **已定**：实现的硬依据。改动必须走一次提交 + 变更记录。

## 变更记录

| 日期 | 变更 |
|---|---|
| 2026-10-17 | 建立仓库；00~03 契约首版（草案）|
| 2026-10-17 | 新增 04 美术素材与提示词契约；`assets/` 目录骨架与 `_style.md`（风格前缀唯一出处）|
| 2026-10-17 | 按评审修订 00~04：Inventory / CraftSession / set_tier / 配方匹配 / yield 口径 / 气泡映射 / 事件 payload / 时间入口 / constants 三组 / 波动细则 / 存档种子与精度；标记 02 为 v0.2 |
| 2026-10-17 | M2 评审落实：ProductInstance / Wallet / CharacterState；items.json · nodes.json 契约；base_price 与乱投兜底；经济口径简化；场景/交互与 payload 扩展；02 升 v0.3 |
| 2026-10-17 | M2 实现回填：items/nodes 载入与校验、ProductInstance.itm_name、CraftSession.recipe_id、Economy 实例化、GatherUseCase reason/可用性、SellUseCase.quote、InteractUseCase、scene/nodes 事件；02 升 v0.4 |
| 2026-10-17 | 森林地图与野生资源：forest.json（底图引用 / scenery / spawn_zones / wild_spawners）、`wild` 流、WildSpawner、B 布点模式；固定节点改为 3 个；01/03 升 v0.2、02 升 v0.5 |
| 2026-10-18 | 美术提示词初稿：3 场景 + 4 资源点 + 5 房间/小店物件（draft）；登记 `art_prop_taiyi` / `art_prop_fengshisha` / `art_prop_shiyingsha` |
| 2026-11-03 | 04 升 v0.2：出图统一走**纯文生图**（`无参考生图.json`），`refs/` 与 `generate img.json` 降为备用；新增 §1.2 全局生成参数（steps 8 / cfg 1.0 / res_multistep·simple）、§1.3 五步流程、§5.4 负向与否定式实测；canvas 定为场景 1024×576、其余 768×768；状态机简化 `draft → generated`；`approved` 只保留给全局风格变更 |
| 2026-11-03 | 04 补实测（同日）：单张 768×768 **18 秒**（服务已热）；物件背景改**肯定句**（`isolated on a completely plain flat solid mid-grey background, empty background, nothing else in the frame`）后石头/地面消失 → 写入 `_style.md` prop 段，9 份物件文件同步；新增 `tools/artgen.py` 批产脚本 |
| 2026-11-03 | 04 增 **§5.5 硬规则（可机械校验）**：提示词可由外部 AI 撰写，验收闸门改为 `artgen.py lint`（逐字比对 `_style.md`，抓漂移；物件背景子句；正向否定式告警）。决策 2 保留拼好字符串，决策 6 由"前缀人工预验证"改为"lint 比对 + 抽 4 挑 1"；新增 [美术提示词撰写任务书](../art-prompt-brief.md) |
| 2026-11-07 | 新增 **05 信件与引导契约**（M3 首版）：`letters.json`、`LetterBook`/`Journal`、`Spirituality`/`Knowledge` 定稿、`Flags`、O4/O5-min、E7-lite/E3；集中裁决到达节奏、阁楼场景、L04 灵性等设计冲突 |
| 2026-11-07 | 05 收窄为 **普通信件（不做解密）** v0.2：删除火烤/蘸水/折叠/字谜/焦页/修复的 M3 实现，改为 §12 后置清单；L05 改为普通信直接给出「压力」；感知阈值 4/6 |
