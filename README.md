# 万水千山

以长征为背景的三章 3D 叙事游戏，使用 Godot 4.7.2 开发。

| 章节 | 场景入口 |
| --- | --- |
| 第一章《飞夺泸定桥》 | `game/v2/main.tscn` |
| 第二章《丰碑 · 雪线之上》 | `game/memorial/main.tscn` |
| 第三章《金色的鱼钩》 | `game/golden_hook/main.tscn` |

## 运行

克隆完整仓库，用 Godot 导入根目录的 `project.godot`。首次打开时等待资源导入完成，按 **F5** 进入章节选择。Windows 导出使用项目自带的 `Windows Desktop` 预设和对应版本的 Godot 导出模板。

## 项目结构

- `game/chapters/` 包含选章界面和章节路由。各章复用 `game/remaster/`、`game/snow/` 等目录中的模块。
- `assets/` 存放运行时资源，`art_source/` 保留可编辑的美术与音频源文件。
- `tests/`、`qa/` 包含回归检查和输入回放。Windows 可设置 `GODOT_PATH` 后运行 `Run_Tests.cmd`、`Run_Drama_Tests.cmd`。
- 素材来源和各自的许可见 [licenses](licenses/) 和 [资源清单](ASSET_MANIFEST.md)。第三章的来源记录见 [第三章文档](docs/golden_hook/)，历史版本报告见 [docs/history](docs/history/)。
