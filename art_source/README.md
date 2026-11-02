# 美术源文件与构建

`linchuan.blend`、`amu.blend`、`zhou.blend` 已打包纹理，使用Blender 4.5.9 LTS打开；`pine_game.blend` 是减面后的松树。各人物文件保留服装、帽体、配件、身体、形态键与53骨骼；GLB中的43段动画由单独重定向步骤生成。`UAL1_Standard.glb` 为原始CC0免费Standard动作源。

重新生成角色：下载清单中的MPFB 2.0.18源码及官方MakeHuman CC0系统资产包；建立任意缓存目录，内含 `mpfb2/src`、`mh_system/clothes`、`mh_system/skins` 等解压内容。在环境变量 `LUDING_ART_CACHE` 中填写缓存绝对路径。使用Blender执行：

```
blender --background --factory-startup --python tools/characters/build_characters.py
blender --background --factory-startup --python tools/characters/retarget_clips.py
blender --background --factory-startup --python tests/character_cap_checks.py
```

脚本也会在工程上级寻找本次工作目录中的 `work/mpfb2`。输出覆盖三个 `.blend` 和GLB，定制前先另存源文件。Godot打开工程后会重新导入GLB。构建帽体时统一使用身体坐标，前后位置以实际头骨为基准，帽檐与帽体为一张连续的有厚度网格，所有顶点100%跟随Head。帽下头发在帽内收束，帽带按额头净空检查。

运行时的三人动作、说话者/听者身体语言、语义手势、眨眼和目光追踪位于 `game/remaster/character_visual.gd`，对白的 `gesture=` 标签位于 `story/`。修改动作后运行 `tests/dialogue_motion_checks.gd`，并用图形脚本 `tests/cap_visual_review.gd` 目视检查；数值检查不能代替美术审查。

工具和素材的精确来源、版本与许可请查看工程根目录的ASSET_MANIFEST，不需要从第三方账号或付费站点获取本项目依赖。MPFB上游代码不包含在游戏运行时。
