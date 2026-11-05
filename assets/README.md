# assets —— 美术素材

提示词与产出图的唯一位置。规范见 `docs/contracts/04-art-assets.md`。

```
prompts/    提示词（源数据）——<category>/<art_id>.md，frontmatter + 正向 / 负向 / 备注
prompts/_style.md   全局风格前缀与通用负向（唯一出处）
refs/       参考图（**暂停使用**；恢复图生图时才启用），<art_id>.png
raw/        AI 原始输出，<category>/<art_id>__s<seed>.png —— 不导入、不进游戏、**本地保留不入库**
textures/   游戏成品（抠底/缩放后），<category>/<art_id>.png —— 唯一被 Godot 导入的素材目录
```

- 素材 ID：`art_<category>_<slug>`；ID 即文件名即引用键。
- `prompts/` 与 `refs/` 已放 `.gdignore`，Godot 不导入。
- `raw/` 已加入 `.gitignore`：候选图体积大（95 张约 41MB），只在本地留档；需要复现时按提示词与 seed 重跑。
- 当前流程是**纯文生图**（`无参考生图.json`），不产出参考图；五步生产流程见契约 §1.3。
