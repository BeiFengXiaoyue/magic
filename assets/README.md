# assets —— 美术素材

提示词与产出图的唯一位置。规范见 `docs/contracts/04-art-assets.md`。

```
prompts/    提示词（源数据）——一个素材一个 .md，格式：frontmatter + 正向 / 负向 / 备注
prompts/_style.md   全局风格前缀与通用负向（唯一出处）
refs/       参考图（风格迁移用）
generated/  产出图，<category>/<art_id>.png —— 会被 Godot 导入
```

- 素材 ID：`art_<category>_<slug>`；ID 即文件名即引用键。
- `prompts/` 与 `refs/` 已放 `.gdignore`，Godot 不导入。
- 生产四步（载入工作流 → 粘贴提示词 → 出图 → 回填 seed）见契约 §1.2。
