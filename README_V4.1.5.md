# 万水千山 V4.1.5

Windows程序包含第一关《飞夺泸定桥》和第二关《丰碑·雪线之上》。解压Windows包后，双击对应关卡的CMD；也可打开EXE从菜单选择。玩游戏无需安装Godot。

源码入口project.godot，使用Godot 4.6。菜单game/chapters/main.tscn、第一关game/v2/main.tscn、第二关game/memorial/main.tscn。共用模块位于game/remaster和game/snow，不能只复制单个关卡目录。原项目应用名与存档文件名保持兼容。

本次修复说话人物/镜头归属、主角遮挡剧情镜头、雪地落脚声及两处队友通行阻塞。当前说明以本文件和V4.1.5_FIX_REPORT.md为准；保留的旧版本报告仅供追溯。许可证在licenses中。

设置GODOT_PATH后运行Run_Tests.cmd、Run_Drama_Tests.cmd。新增测试tests/v415_checks.gd、v415_formation.gd、v415_camera_clearance.gd、v415_foot_sync.gd使用Godot --headless --path . --script调用。全流程验证使用EXE -- --memorial-replay --showcase，正常游玩无需这些测试参数。
