# V2.0 测试报告

记录日期：2026-10-27。Godot 4.6 stable / GDScript / Windows x64 / NVIDIA RTX 4060 Laptop / Vulkan Forward+。兼容模式启动另测 OpenGL。源工程从重制版 f0c0611 独立复制，旧版 EXE、ZIP 和目录未覆盖。

## 执行结果

|类别|脚本 / 日志|通过断言|
|---|---|---:|
|原系统|test_contract|32|
|原系统|combat_checks|5|
|原系统|checkpoint_edges|10|
|原系统|pose_checks|2|
|原系统|interaction_pose|2|
|原系统|remaster_contract|14|
|原系统|remaster_progression|21|
|原系统|remaster_pose|4|
|原系统|story_checks|0|
|原系统|dialogue_motion_checks|8|
|原系统|camera_framing_checks|4|
|V2|core|15|
|V2|campaign|14|
|V2|recon|18|
|V2|escort|22|
|V2|repair|44|
|V2|traversal|19|
|V2|relay|12|
|V2|modern|13|
|恢复|v2_recovery_write|41|
|恢复|v2_recovery_read_process|33|

合计 **333 项断言**，上述最终日志无 FAIL、ERROR 或 SCRIPT ERROR。另有十份剧情文件实际经 Dialogue Manager 编译遍历，现分支0及可选场景共27行306字。源码中全部编写分支共28行319字，统计表另附。这些是确定范围的测试，不构成“没有任何BUG”的结论。

源代码测试命令（工作目录为源工程）：

```powershell
& '..\Godot_4.6\Godot_v4.6-stable_win64_console.exe' --headless --path . --script tests/v2/core_checks.gd
# 替换脚本名依次运行campaign/recon/escort/repair/traversal/relay/modern/recovery。
& '..\Godot_4.6\Godot_v4.6-stable_win64_console.exe' --headless --path . --script tests/v2/recovery_checks.gd -- --read-checkpoints
& '..\Godot_4.6\Godot_v4.6-stable_win64_console.exe' --headless --path . --script tests/story_checks.gd
& '..\Godot_4.6\Godot_v4.6-stable_win64_console.exe' --headless --path . --export-release 'Windows Desktop'
```

`Run_Tests.cmd` 包含十一项原机制脚本、九项 V2 脚本及跨进程读取。原机制回归仍实例化原场景，V2脚本实例化新场景或带真实世界/碰撞的模块 fixture，两类分开记录。

## 覆盖范围

顺序目标拒绝过期、重复和未来完成。侦察检查实际角度、距离、遮挡、持续时间及路牌距离。接应检查两条实物净空、压制消退、Q信号、提前击倒敌人仍可推进、补给和复位。修桥检查朽板可换、裂板额外工序、张力与检查前置、唯一木板所有权、两处网格/碰撞同步、第二处二维定位及阿木跨窄板。

攀索检查不同时步长、错误方向失衡、两段真实通行、实际中点碰撞、对齐和绳索确认前置、已固定松板恢复、退出清除姿态。接力检查射线观察、实际队友移动、错位不能抬障、抬起后的通道碰撞和等待两人真正通过。现代篇检查错误判断/错误层位可重试、重复防护、历史对照前置、相机移动后高亮仍锚定桥梁及恢复。

存档检查版本3写入/读取、旧版本安全回退、损坏JSON和字段拒绝、原文件不被无效写入替换。八个章节先写入文件，关闭进程，再由第二进程读取；保留已修桥面、敌人生命/死亡、路线、铁索中点、接力观察与现代组装。搬运中暂停、退标题、继续会恢复到安全备料点，保留已修板并复用单个木板节点。测试用 fixture 安排阶段，用来验证恢复，不能冒充真实通关。

## 发布程序全流程

在最终 `Windows/LudingBridge_Remaster_V2.exe` 中执行：

```powershell
.\LudingBridge_Remaster_V2.exe --headless --fixed-fps 60 --log-file <绝对日志路径> -- --verify-replay
.\LudingBridge_Remaster_V2.exe --headless --fixed-fps 60 --log-file <绝对日志路径> -- --verify-replay --route-b
.\LudingBridge_Remaster_V2.exe --resolution 1920x1080 --log-file <绝对日志路径> -- --verify-replay --route-b
.\LudingBridge_Remaster_V2.exe --resolution 1280x720 --fixed-fps 30 --write-movie <绝对AVI路径> --log-file <绝对日志路径> -- --verify-replay --showcase
```

两条路线均从标题开始，经真实 Input、跳跃、视线识别、路牌、射线战斗、Q信号、两处实际搬运/铺板、两段铁索、中点修复、接力及结构组装到结算。回放不设置任务完成、不直接修改敌人生命、不传送玩家。瞄准镜头和数字篇按钮有脚本辅助；数字篇调用的为可见按钮所绑定的同一公开操作。每个等候都有失败超时，原始日志包含位置和关键条件。

720p影片为同一完整流程加展示停留，约3分钟，包含标题及结算，可兼作完整实际运行录像与参赛玩法展示。没有剪接商业游戏画面。MovieMaker固定30FPS是采集格式，不能当作普通运行性能。

1080p普通渲染另有完整日志与报告。性能采样来自这台机器，还会受本机同时运行录制/编码等工作影响，不能外推到低配电脑。截图在 `Media/index.html` 中按回放/摆位来源分开。

## 实际失败及修复记录

完整过程曾发现：开场出生在地形高度截断处、B补给抢先吞掉清障、B路线穿过掩体、长板转身空间不足、阿木斜穿窄板、渲染步长很小时被3厘米板缝挡住、章节完成后空模块tick、发布版脚本remap检查错误、现代高亮随相机移动、检查键同时触发物理跳跃。均有修改与对应回归/最终流程重跑。细节见CHANGELOG。

早期失败日志保留在开发目录work，不把失败尝试列为通过结果。一轮30FPS影片回放检查按钮时比HUD更新早一帧，仍记录失败，未发布那次视频；后续回放等待实际可点击状态才发出按钮输入，超时仍失败，并重新完整录制。曾有权限审核服务额度错误导致命令未运行，该次不记测试通过；后续已实际补跑。

## 验证边界与剩余风险

没有独立真人全程首通，也没有低配设备或长时间随机操作验收。AI曾从普通窗口点击开始并查看标题、开场与HUD，不能称为真人盲测。快速Esc工具输入的图形反馈未作为独立通过证据；引擎原生快速按键与暂停/恢复测试实际通过。

**20—30分钟首玩目标尚未验证，也不应宣称达成。** 熟练自动回放约2分半，首次探索、理解操作与重试会增加时间，但没有可辩护的20—30分钟估计。行军段仍短，后续应增加有区别的事件和开展真人测时，不能靠长对白、降速或等待补时长。

近景手指、服装和搬运转身仍有打磨空间。没有真人配音或口型系统。现代篇为虚拟教学，非实际无人机测绘；史实与艺术化边界在README和原资产/来源文档中明确。比赛名次无法保证，比赛报名未执行。
