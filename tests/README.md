# tests —— headless 测试

原则：`core / domain / app` 三层**删掉 engine 后必须全部通过**。

计划清单：

| 测试 | 内容 | 契约 |
|---|---|---|
| `test_content_load.gd` | 内容载入与校验 | 00 §7.2 |
| `test_reaction_solver.gd` | 温润汤剂 / 焚烈 / 乱投竞争 / tie-break | 02 §1.2 |
| `test_coverage_pricing.gd` | 覆盖率 0.58 / 退热酊 0.62 / 杂配酊 < 0.5 | 02 §2.2 |
| `test_determinism.gd` | 同种子重放一致 + 换种子必变 | 03 §2 |
| `test_layer_boundaries.gd` | 依赖方向静态检查 | 00 §2.2 |
| `test_no_magic_numbers.gd` | 魔法数启发式扫描 | 00 §8 |

运行（本机 Godot 4.7.2）：

```bash
"C:\Users\BeiFengXiaoYue\Desktop\IDE\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/run_all.gd
```
