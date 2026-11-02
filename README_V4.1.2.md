# 万水千山 V4.1.2
Windows 包解压后运行 `WanShuiQianShan_V4_1_2.exe`，选择第二关《丰碑·雪线之上》。亦可运行 `直接进入第二关.cmd`。运行不需要Python、语音模型或联网。

WASD移动，鼠标转向，Shift奔跑，空格跳跃，F观察，E取物/交付/检查/敬礼，Q信号，Esc暂停。敬礼只需按一次E；不评分。剧情镜头期间暂时锁定操作，普通探索可以自由转动镜头。

本版保留第一关《飞夺泸定桥》及旧雪山入口。新版存档独立为 `memorial_campaign_v412.json`；不会覆盖V4.1.1存档。Godot使用原“飞夺泸定桥”用户数据目录，以保留第一关进度。旧报告为历史记录，当前结果以V4.1.2报告和测试证据为准。

源工程入口为project.godot，Godot 4.6。先设置GODOT_PATH指向Godot4.6可执行文件，运行Run_Tests.cmd执行原回归、Run_Drama_Tests.cmd执行新版单项和高潮测试，Run_Memorial_Replay.cmd执行普通输入流程。Build_Windows.cmd导出Windows，需安装对应导出模板。制作工具不是运行依赖。

本版采用用户选定的B版自然剧情语气，声音仍是定向合成男声。A/B试听WAV和逐句导演表随源码保留。完整视频是发布程序的普通输入辅助回放，非人工手柄操作；未使用剧情完成变量或人物传送。
