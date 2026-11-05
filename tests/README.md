# tests —— headless 测试

原则：`core / domain / app` 三层不依赖 engine 运行时；engine 层的纯数据与纯函数也纳入 headless 检查。

当前清单：

| 测试 | 内容 | 契约 |
|---|---|---|
| `test_content_load.gd` | 内容载入与校验（含坏数据负例） | 00 §7.2 |
| `test_art_assets.gd` | `art_id` 路径推导与缺图回退 | 04 §2 |
| `test_reaction_solver.gd` | 温润汤剂 / 焚烈 / 乱投竞争 / tie-break | 02 §1.2 |
| `test_economy.gd` | 覆盖率、成本与定价 | 02 §2.2 |
| `test_craft_use_case.gd` | O1 炼制全流程 | 02 §3 |
| `test_gather_sell.gd` | O2 采集 → O3 卖出闭环 | 02 §3 |
| `test_wild_spawner.gd` | 野生刷新区域、确定性与跨天重刷 | 01 / 03 |
| `test_determinism.gd` | 同种子重放一致 + 换种子必变 | 03 §2 |
| `test_scene_layout.gd` | 贴图尺寸 / 碰撞箱 / 交互矩形一致 | 04 / 场景布局 |
| `test_player_facing.gd` | 左右朝向与上下复用规则 | — |
| `test_layer_boundaries.gd` | 依赖方向静态检查（路径 + class_name） | 00 §2.2 |
| `test_no_magic_numbers.gd` | 魔法数启发式扫描 | 00 §8 |

运行（需 Godot 4.7.2，且 `godot` 已在 PATH 中）：

```bash
godot --headless --path . --script res://tests/run_all.gd
```

Windows 用户若未配置 PATH，可以使用完整路径：

```powershell
& "C:\path\to\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/run_all.gd
```
