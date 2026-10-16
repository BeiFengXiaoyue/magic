# app —— 编排层

放：用例（`CraftUseCase` 等）、事件总线 `Events`（autoload）。
职责：把领域能力串成玩家的一个动作；横向组合只在这里发生。

**禁止**：玩法规则本身、界面控件——用例必须可在无界面环境运行。

契约：`docs/contracts/02-core-api.md` §3 / §4
