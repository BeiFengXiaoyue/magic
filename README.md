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
| 引擎 | **Godot 4.7.2** |
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
├─ tests/       headless 测试（core/domain/app 不依赖引擎运行时；engine 层的纯数据与纯函数也纳入）
└─ docs/
   └─ contracts/   ★ 规范契约（当前阶段的工作重心）
```

依赖只许向下：`content → core → domain → app → engine`；
唯一例外是**感知通道**（引擎可特许读内核的 `Perception` 输出）。

## 当前进度

| 里程碑 | 内容 | 状态 |
|---|---|---|
| M1 能炼一炉 | 投料 → 选火候 → 气泡演化 → 取出产物 | ✅ 完成 |
| M2 闭环 | 采集 → 炼制 → 卖出；需求不匹配则卖不掉 | ✅ 完成 |
| M3 信件与引导 | L01~L05 普通信件、手记；解密后置 | 🟡 契约草案（05） |
| M4 完整节奏 | 时间、生存、战斗、存档 | ⬜ 未开始 |
| M5 可玩性测试 | 找人试玩，验证三个设计假设 | ⬜ 未开始 |

- 自动化检查：**618 项 headless 检查**（含分层依赖、魔法数、内容 schema、场景布局等静态约束）
- 契约：00~05 共 6 份，见 [docs/contracts/README.md](docs/contracts/README.md)；M3 首版草案为 [05 信件与引导](docs/contracts/05-letters-guidance.md)
- 详细进度与验证记录：[docs/工作进展.md](docs/工作进展.md)
- 已知未实现：存档与读档（契约 03 已定义）、UI 层自动化测试

## 本地运行

```bash
# 需 Godot 4.7.2，且 godot 可执行文件已在 PATH 中
# 打开编辑器
godot --path .

# 校验工程（无窗口）
godot --headless --path . --quit
```

Windows 用户若未配置 PATH，可以使用完整路径：

```powershell
& "C:\path\to\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --quit
```

## 工作纪律（摘要）

- 领域层**互不 import**；跨领域共享只走内核类型。
- 一切影响持久状态的随机（产率、波动、空手率、事件）走**确定性随机**；真随机只许用于战斗暴击、动画抖动。
- 同一世界种子重跑，结果必须一致（验收项）。
- **禁止魔法数**：策划可调的数值只许来自 `content/constants.json`；引擎表现参数必须写成具名常量。
- 细则见 `docs/contracts/00-conventions.md`。

## License

MIT © 2026 BeiFengXiaoyue
