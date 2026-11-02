# 泸定桥 V2.1 修复版

Windows：运行交付目录 Windows/LudingBridge_V2_1.exe。PCK 和音频均内嵌，无需另装 Godot、Python 或 TTS，也无需联网。

保留原六章及数字重建尾声。WASD 移动，鼠标转动视角；修桥仍保留选材、定位、绑绳、检查步骤。检查完后，跟随金色标记走到木板朝桥的一端，按 E 呼叫阿木；等双方到位共同抬起后用 WASD 搬运。到缺口前按 E 放下，再固定与检查。修桥任一操作阶段可按 R 取消并释放控制；战斗阶段 R 仍是装填。Esc 暂停，菜单可从检查点重试。

源码使用 Godot 4.6 stable 标准 GDScript 版，Jolt Physics / Forward+。用 Godot 导入 project.godot，首次会重新导入美术资源。编辑器无需 .NET。源码中的 C# 插件示例仅保留参考，已从标准版导出排除。

脚本：设置环境变量 GODOT_PATH 为 Godot 4.6 可执行文件完整路径，再运行 Open_Editor.cmd、Run_Tests.cmd、Run_Playthrough.cmd 或 Build_Windows.cmd。重新打包需要安装 Godot 4.6 Windows 导出模板；发布物已提供，无需自行构建即可游玩。Run_Playthrough.cmd --route-b 可回放 B 路线。

配音：assets/voices/ 中有 32 条实际 WAV 与 manifest.json。tools/Generate_Chinese_Voices.ps1 可在装有 Microsoft Kangkang 语音的 Windows 上离线再生成；发布游戏不依赖该语音引擎。角色沿用原工程称谓“周班长”、林川和阿木。

测试详情、边界和原始日志见 FIX_REPORT_V2_1.md 与 test_evidence/v21/。
