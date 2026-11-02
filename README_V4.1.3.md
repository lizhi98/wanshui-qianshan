# 万水千山 V4.1.3

Windows解压后运行 `WanShuiQianShan_V4_1_3.exe`。标题可选择泸定桥或第二关《丰碑·雪线之上》。WASD移动，鼠标转向，Shift奔跑，空格跳跃；第二关F观察、E交互、Q发信号。Tab查看操作，Esc暂停。普通玩家无需启动任何测试夹具。

第二关使用独立 `memorial_campaign_v413.json`，首次可迁移原V4.1.2有效存档，保留旧文件。泸定桥存档及旧雪山功能保留。本版专修人物动作、接地、避让和坐姿，没有扩写剧情或新增音乐。

Godot 4.6源工程入口 `project.godot`。设置 `GODOT_PATH` 后运行 `Run_Tests.cmd`（原回归）、`Run_Drama_Tests.cmd`（丰碑剧情）或 `Run_Animation_Tests.cmd`（动态夹具，分析需Python与numpy）。渲染夹具：`godot --path . -- --animation-lab --lab-case=A`，B/C/D同理；脚底调试另加 `--debug-contact`。完整输入回放 `--memorial-replay --showcase`。

源包不包含可重新导入的`.godot`缓存。资源许可保留在`licenses`、`ASSET_MANIFEST.md`和原`V4.1.2_ASSET_LICENSES.md`；本次没有导入新的第三方人物、动作、声音或音乐。新增代码和雪粉材质沿项目MIT/原创资源规则。

阅读`V4.1.3_CHARACTER_ANIMATION_BUGFIX.md`和`V4.1.3_TEST_REPORT.md`了解修复、证据与限制。完整通关及A/B/C视频另附；坐姿前后四机位对照在交付目录。不要把A—D的摆放夹具当成完整游玩。
