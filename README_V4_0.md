# 万水千山 V4.0

在 V3.3 完整工程上新增第二关《雪线之上：翻越夹金山》。第一关《飞夺泸定桥》保留独立入口及玩法。项目使用 Godot 4.6，Windows x86_64。

## 启动

Windows 包双击 `WanShuiQianShan_V4_0.exe`，在章节菜单选择第一关或第二关。也可使用包内 `开始雪山.cmd`、`开始泸定桥.cmd`。第三关仅预留接口，没有制作第三关内容。

源码使用 Godot 4.6 导入 `project.godot`。默认入口 `game/chapters/main.tscn`；独立入口分别为 `game/v2/main.tscn`、`game/snow/main.tscn`。设置 `GODOT_PATH` 后，`Run_Snow.cmd` 可直接运行雪山。

WASD 移动，鼠标转视角，Shift 奔跑，空格跳跃，F 开关观察，Q 发信号，Esc 暂停。雪山没有搬板和攀桥索任务。观察脚印、落石及布条，亲自走到正确道路后再通知队伍。风口要借岩避风；最后的裂隙先在安全位置等风缓，再靠近起跳。

## 存档与测试

雪山存档 `user://snow_campaign_v4.json` 独立于桥关。保留旧应用数据目录名称以兼容第一关既有存档。Windows 默认数据位置为 `%APPDATA%\Godot\app_userdata\飞夺泸定桥`。回放及单项测试使用独立文件，不覆盖正常游玩存档。

`Run_Tests.cmd` 运行桥关回归及雪山单项测试；`Run_Snow_Tests.cmd` 仅运行雪山测试；`Run_Snow_Replay.cmd` 运行从头到尾的输入驱动通关。回放使用普通移动、跳跃、观察和信号输入，并辅助转动镜头；不瞬移玩家、不直接设置任务成功。单项几何/存档测试包含明确标注的测试夹具，不能当成完整通关。

`Build_Windows.cmd` 需要安装 Godot 4.6 Windows 导出模板。地形缓存随源码分发；修改高度生成函数后，用 `--bake-snow` 运行 `tests/snow/load_probe.gd` 重新生成四个地形资源。

具体实现、实测结果与局限见 `SNOW_MOUNTAIN_REPORT.md`。新增素材记录见 `SNOW_ASSET_SOURCES.md`，原素材许可记录继续保留。
