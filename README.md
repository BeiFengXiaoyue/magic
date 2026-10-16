# Alchemist Codex · 《炼金术士手记》代码本体

本仓库是《炼金术士手记》的**代码实现本体**。

- **设计文档**（不属本仓库，行为的唯一依据）：`../《炼金术士手记》/`
  - 架构依据：`04-技术/架构设计.md`、`04-技术/架构图.drawio`
  - 制作依据：`04-技术/Demo 制作计划.md`
  - 数值唯一出处：`02-玩法/数值表.md`
- **本仓库只放**：代码、内容数据（JSON）、测试、契约文档。

## 技术栈（已定）

| 项 | 决定 |
|---|---|
| 引擎 | **Godot 4.7.2**（`C:\Users\BeiFengXiaoYue\Desktop\IDE\Godot_v4.7.2-stable_win64.exe`）|
| 语言 | **GDScript**（静态类型；契约签名即 GDScript 签名）|
| 数据 | **JSON**，全部走 `content/`，数据驱动 |

## 目录布局（五层 + 内容 + 测试）

```
res://
├─ content/     内容层：纯 JSON 数据，无代码
├─ src/
│  ├─ core/     共享内核（元素与反应 / 投影 / 时间 / 随机 / 灵性 / 知识 / 感知）
│  ├─ domain/   领域层（过程 / 经济 / 叙事 / 角色）——互不 import
│  ├─ app/      编排层（用例：串起领域）
│  └─ engine/   引擎层（场景 / 面板 / 输入 / 音频）——唯一可含 Node 类型
├─ tests/       headless 测试（内核/领域/编排删掉引擎层仍可运行）
└─ docs/
   └─ contracts/   ★ 规范契约（当前阶段的工作重心）
```

依赖只许向下：`content → core → domain → app → engine`；
唯一例外是**感知通道**（引擎可特许读内核的 `Perception` 输出）。

## 当前阶段

**规范契约设计**（M1「能炼一炉」开工前）。契约清单见 [docs/contracts/README.md](docs/contracts/README.md)。

契约状态：`草案` → `评审` → `已定`。**已定的契约是实现的硬依据**——实现者不必再问字段与签名。

## 本地运行

```bash
# 打开编辑器
"C:\Users\BeiFengXiaoYue\Desktop\IDE\Godot_v4.7.2-stable_win64.exe" --path .
# 校验工程（无窗口）
"C:\Users\BeiFengXiaoYue\Desktop\IDE\Godot_v4.7.2-stable_win64.exe" --headless --path . --quit
```

## 工作纪律（摘要）

- 领域层**互不 import**；跨领域共享只走内核类型。
- 一切影响持久状态的随机（产率、波动、空手率、事件）走**确定性随机**；真随机只许用于战斗暴击、动画抖动。
- 同一世界种子重跑，结果必须一致（验收项）。
- **禁止魔法数**：策划可调的数值只许来自 `content/constants.json`；引擎表现参数必须写成具名常量。
- 细则见 `docs/contracts/00-conventions.md`。
