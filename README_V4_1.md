# 万水千山 V4.1 · 丰碑·雪线之上

双击 Windows 包里的 `WanShuiQianShan_V4_1.exe`，选择第二关。第一关《飞夺泸定桥》保持独立可玩。V4.0 雪山仍可用 `--legacy-snow` 启动，用于回归与版本对照。

WASD 移动、鼠标转镜头、Shift 奔跑、空格跳跃。F 开关观察，E 取物、交接、查看和敬礼，Q 向后方队伍发信号，Esc 暂停。靠近人物后可看到较小的姓名提示。声音与画质菜单可分别调整音乐、环境音。

山脚先观察剩余衣物，再抱起包裹送到需要的战士身旁。已经领到棉衣的人会把包裹让给更需要的同志。上山后留意队伍停顿、风势和岩旁标记。后半段的观察有明确顺序：先查看人物，再辨认衣物和随身记录。敬礼使用一次完整动作，没有速度评分。敬礼后的返队路线已收短，避免再次重复长距离赶路。

新版使用独立存档 `user://memorial_campaign_v41.json`，不会读取或覆盖桥关和 V4.0 的任务状态。正常 Windows 用户数据位置是 `%APPDATA%\Godot\app_userdata\飞夺泸定桥`；保留旧应用名是为了兼容已有桥关存档。所有回放和测试另用独立文件。

源码入口 `project.godot` → `game/chapters/main.tscn`；新版雪山独立入口 `game/memorial/main.tscn`。使用 Godot 4.6 导入。修改新版地形后，通过 `--bake-memorial --smoke-memorial` 重新生成缓存。设置 `GODOT_PATH` 后，可运行 `Run_Memorial_Tests.cmd`、`Run_Memorial_Replay.cmd`。原 `Run_Tests.cmd` 保留桥关及 V4.0 的单项回归，完整旧雪山输入回放参数为 `--snow-replay`。

完整源码包含新增场景、脚本、鞋底贴花、38条男声、六段音乐及原授权文件。具体改动、实测与局限见四份 V4.1 报告。配音为合成男声，不是真人演员录音。

文学主题取自李本深《丰碑》。人物、对白和具体地点为文学化改编，不代表夹金山已考证事故。正式公开提交或发行前，请确认相关改编权利与许可。

可用 `Record_Memorial.cmd` 从源码重新生成720p/30fps的六幕输入回放AVI。Windows发布程序使用相同参数 `--resolution 1280x720 --fixed-fps 30 --write-movie 输出.avi -- --memorial-replay --showcase`。录像为离线MovieMaker输出，操作通过普通输入执行；文件较大，正式交付另转为带章节索引的MP4。
