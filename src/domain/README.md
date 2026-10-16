# domain —— 领域层

四个领域各自成子目录：`process/` `economy/` `narrative/` `character/`。

**互不 import（硬纪律）**——由 `tests/test_layer_boundaries.gd` 强制。
跨领域共享数据只走 core 的类型（`CraftResult`、旗标、灵性、知识）。

**禁止**：Node 类型、界面控件、其他领域的文件。

契约：`docs/contracts/02-core-api.md` §2
