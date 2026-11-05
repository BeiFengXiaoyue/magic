# tools —— 出图工具

`artgen.py`：按 [04 契约](../docs/contracts/04-art-assets.md) 把 `assets/prompts/` 里的提示词批量变成图片。

## 前提

- ComfyUI 工作流 `无参考生图.json` 在本机（路径见脚本顶部 `PORTABLE`）；
- 用 ComfyUI 自带的 Python 跑（它带 urllib，别的环境也行）：

```powershell
$py = "C:\Users\BeiFengXiaoYue\Desktop\ComfyUI_windows_portable\python_embeded\python.exe"
```

## 常用命令

```powershell
# 交活前必跑：检查提示词是否符合契约与 _style.md（0 错误才算过）
& $py tools\artgen.py lint

# 看有哪些素材、哪些还没出图
& $py tools\artgen.py list

# 干跑：解析工作流 + 打印一条完整 payload（不占显存，随时可跑）
& $py tools\artgen.py plan --only art_prop_crucible_clay --write-plan plan.json

# 真正开工：全部缺图的素材 × 4 张（脚本自己拉起 ComfyUI）
& $py tools\artgen.py run --launch

# 只跑一个、只抽 1 张、限时 10 分钟
& $py tools\artgen.py run --only art_prop_crucible_clay --count 1 --timeout 600

# 挑定一张：复制到 textures/ 并回填 seed、status
& $py tools\artgen.py pick art_prop_crucible_clay 1376459228465061869

# 逐帧素材（有「## 帧」小节）：固定 seed 跑全部帧，再拼 sheet
& $py tools\artgen.py run --only art_char_hero_walk --force --seed 20261104
& $py tools\artgen.py sheet art_char_hero_walk

# 参考生图（i2i）：拿一张定稿当参考重绘，--strength 是重绘强度
& $py tools\artgen.py run --only art_prop_crucible_clay --workflow i2i `
    --ref assets\raw\prop\art_prop_crucible_clay__s2264258430219746954.png --strength 0.45
```

> i2i 只是“重绘同一张”，**改不了姿势**——实测 0.45 和 0.75 都保持原构图。逐帧动作要用 t2i + 固定 seed。

## 抠底（物件 / 角色后处理）

纯文生图不出 alpha；`pick` / `sheet` 出来的成品仍是灰底。用 `cutout.py` 把灰底与投影去掉并写成 RGBA：

```powershell
# 只试一个，输出到预览目录
& $py tools\cutout.py --only art_prop_qinglucao --out-dir tools\_preview\cut

# 全部 prop 成品，覆盖 assets/textures/prop/
& $py tools\cutout.py

# 角色表：只去背景，保留 192px 格位（不要裁边居中）
& $py tools\cutout.py --category char --no-trim
```

- 背景色从四边采样，从边界洪泛；黑色描边不会被吃掉。
- 物件默认裁到主体并居中；角色表必须用 `--no-trim`，否则切帧位置会乱。
- 原图仍在 `assets/raw/`，可随时重抠。
- 场景图不需要抠底；只有 `prop` 需要。

## 行为说明

| 事 | 怎么做 |
|---|---|
| 提示词来源 | `assets/prompts/<category>/<art_id>.md` 的「正向 / 负向」代码块 |
| 规格校验 | `lint` 逐字比对当前 `_style.md`：前缀/类别段是否漂移、物件是否带背景子句、正向有无否定式、canvas 是否 8 的倍数 |
| 参数 | 脚本顶部常量：8 步 / cfg 1.0 / res_multistep·simple / denoise 1.0（= 契约 §1.2）|
| 尺寸 | frontmatter 的 `canvas`，必须是 8 的倍数 |
| 原图落在哪 | `assets/raw/<category>/<art_id>__s<seed>.png` |
| 成品落在哪 | `pick` 复制到 `assets/textures/<category>/<art_id>.png`（缩放/抠底仍需后处理）|
| 跳过规则 | 该 `art_id` 已有 `__s*.png` 就跳过；`--force` 覆盖 |
| 断点 | 每张成功即写 `tools/.artgen_state.json`，中断后重跑会接着做没做的 |
| 内存看门狗 | 每次提交前查 `/system_stats`，RAM < 1.2GB 或显存 < 0.3GB 就等 30 秒 |
| 失败隔离 | 单张超时/报错只记失败，不中断整批；结尾汇总 |

## 这台机器的现实

8GB 内存要装 11.5GB 模型，必然走页面文件，但**实测能扛住**：单张 768×768 **18 秒**（服务已热；冷启动另加 1~2 分钟加载）。

- 12 个素材 × 4 张 = 48 张 ≈ **15 分钟**；
- 25 个素材 × 4 张 = 100 张 ≈ **30 分钟**。

跑之前关掉浏览器/Steam 等常驻程序，能明显降低失败率。**不要加 `--lowvram`**——那会把更多权重压进系统内存，而这台机器的瓶颈正是内存。

## 不做的事

- 不并行、不 `batch_size > 1`（内存峰值会炸）；
- 不自动挑图（挑图是人的判断）；
- 不做缩放/抠底（那是后处理脚本的事，那时 ComfyUI 已关，不吃这份内存）。
