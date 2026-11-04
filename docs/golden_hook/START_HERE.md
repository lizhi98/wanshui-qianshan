# 金色的鱼钩 V1.1 使用说明

本目录是第三关 V1.1 的当前说明。旧 V1.0 的测试结果和媒体保存在交付目录原位置；不能混作本轮验收。主报告为 `GOLDEN_HOOK_V1.1_REWORK_REPORT.md`。

三关共用一个 Windows 程序、一个 Godot 4.6 工程和统一章节菜单。第一关采用收到的 V4.1.3 包内 V3.3 系统，第二关采用该包内《丰碑》系统，第三关为本次 V1.1。第二关原始创作工程仍未找到，本工程的前两关基础由用户自己的发布包恢复，详见根目录 `RECOVERY_NOTICE.md`。

## 游玩

解压 Windows 包，运行 `WanShuiQianShan_GoldenHook_V1_1.exe`，在章节菜单选择第三关，再选择“走进草地”。不需要联网、Python、Blender 或 TTS 服务。WASD 移动，鼠标转镜头，E 交互，Esc 暂停；钓鱼时按界面提示蓄力抛竿、空格提竿、按住/松开鼠标左键收放线。第一次过早提竿或脱钩后可重试，不存在决定老班长生死的倒计时。

菜单中的“操作与辅助”提供音乐、音效和配音独立档位，以及画质设置。第三关存档 `golden_hook_chapter3.json` 与前两关进度分离；主程序继续使用 V4.1.3 的用户目录名“飞夺泸定桥”，避免无端丢失旧进度。迁移只在目标尚无存档且旧第三关存档有效时发生。请使用游戏菜单管理进度。

## 开发

用 Godot 4.6 打开根目录 `project.godot`，等待导入，再运行主场景。前两关的恢复资源与第三关 Blender 源文件均已收入；不用安装 Blender 即可导入现有 GLB。需要编辑模型时再安装 Blender 4.5 LTS。Python 工具推荐 Python 3.13；音频包络与原创配乐生成器使用 numpy。

设置 `GODOT_BIN` 为本机 Godot 4.6 可执行文件路径后，`Open_Editor.cmd` 可打开编辑器，`Run_Tests.cmd` 执行本轮检查，`Run_Playthrough.cmd` 执行第三关输入回放。也可直接运行：

```powershell
python tools/run_golden_checks.py --godot "C:/Tools/Godot_4.6.exe"
python tools/build_golden_windows.py --godot "C:/Tools/Godot_4.6.exe" --templates "C:/Tools/Godot_4.6_templates"
```

模板目录须包含 `windows_release_x86_64.exe` 与 `windows_debug_x86_64.exe`。未指定模板目录时使用 Godot 已安装的 4.6 导出模板。不要把 4.5/4.6 的引擎和模板混用。构建工具会暂时写入模板路径并在结束后恢复导出配置。

## 验收媒体

Windows 完整录像使用 `--golden-replay` 输入回放，主动观察场景后发出键鼠事件，不写入剧情完成标志、位置或奖励；这不是独立真人盲测。动作演示使用 `--v11-action-lab` 的明确摆位夹具。两类媒体分别标注，不互相替代。

五种声音是五个独立神经合成音色。试听组和实际游戏混音已提供；自然中文、表演情绪和音乐感染力的独立真人签核仍待完成，详见 `VOICE_CASTING_REPORT.md`。
