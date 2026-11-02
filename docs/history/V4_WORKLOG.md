# V4.0 雪线之上开发记录

用户请求：F:/codex/attachments/c6525890-b2ca-411f-9935-cfca81b5be8a/已粘贴的文本.txt（已完整读取）。目标：现有 V3.3 工程新增 6–8 分钟独立雪山关，保护泸定桥，实际测试与 Windows/视频交付。

## 保护与路径
- 原 V3.3 canonical: ../LongMarch_LudingBridge_V2（不再修改）。
- 已验证并备份完整 Source.zip: ../../backups/V3_3_before_snow/，BACKUP.json 含 SHA256 与 CRC。
- 当前开发目录：本目录 LongMarch_V4，从完整 V3.3 源码恢复，未重建 Kenney 框架。
- Godot: C:/Users/14438/Documents/Codex/2026-10-21/https-chatgpt-com-s-cx-6ad8c6459ff881919300f8afe56ad166/work/tools/Godot_4.6/Godot_v4.6-stable_win64_console.exe
- Windows template 同 tools/windows_release_x86_64.exe；FFmpeg E:/bin/ffmpeg.exe。
- 公共工具/模型仍在任务根 work/expressive_env、work/tools/Qwen3-TTS-1.7B-CustomVoice、work/music。

## 实施结构
- game/snow/main.tscn 独立入口；campaign/world/player/npc/weather/observation/hud/save_store/audio。
- 新章节选择入口 game/chapters/main.tscn；保留 game/v2/main.tscn，桥章节完成后可接雪山，预留第三关。
- 复用 game/player.gd 的控制、game/camera.gd 的球形避障、remaster/character_visual、v33 材质与植被几何、remaster/audio 的串行对白。
- 独立任务 INTRO → ROUTE_FINDING → BLIZZARD → SLOPE_COLLAPSE → REUNION → SUMMIT → COMPLETE；独立 snow_campaign_v4.json。
- 压缩山路约 600–700 米，实际相对高度约 120 米，艺术化地形；下部灌木，半山裸岩/碎雪，顶部风雪垭口。
- 真实风周期、岩后避风、区域触发滑塌动态与实体堵路、侧路探索、F 注视线索与 Q 引队、物理跳跃与 NPC 自动跨短裂隙、逐步集合与拉远结局。

## 必需验证/交付（待完成）
- [ ] 独立可玩地形与实体碰撞/高差
- [ ] 五阶段实际交互与完整剧情
- [ ] 真实风/避风、滑塌一次性、路线与信号、NPC 集合
- [ ] 检查点失败复位/重进程恢复与统计
- [ ] 新男声/原创配乐/风雪音效/授权清单
- [ ] 图形查看、修正遮挡/碰撞/动作问题
- [ ] 原 V3.3 测试与输入驱动完整通关
- [ ] 雪山完整输入回放（不设置位置/完成状态）6–8 分钟
- [ ] V4.0 Windows 程序、完整源码、录像/截图、压缩包与哈希核验
- [ ] SNOW_MOUNTAIN_REPORT.md 实际实现/验证/局限

## 历史参考（不把虚构事故当史实）
- 共产党员网 https://xuexi.12371.cn/2016/12/16/ARTI1481871917232610.shtml
- 国防部 https://www.mod.gov.cn/gfbw/gfjy_index/16495355.html （搜索摘要含红军小道、五道拐、陡坡；打开超时）
- 中国军网 https://www.81.mil.cn/wh_208594/16466170.html （搜索摘要含 1935/6/12、6月厚积雪与 4114m 垭口；打开超时）

## 2026-10-30 实测进度
已实现全部五阶段、22条男声、3段音乐、连续碰撞山体、真实风力和侧路滑塌。桥回归548 PASS，桥源码完整输入81 PASS；雪山机制39 PASS、重进程恢复4 PASS、两处玩家跳跃与四NPC攀登通过；雪山源码完整输入63 PASS到COMPLETE。原V3.3与备份887文件一致。Windows已导出且两个入口smoke通过，最终EXE完整雪山视频正在录制；封包/视频验证待完成。当前二进制身份见任务根work/v4_recording_identity.json。

最终封包完成：雪山 EXE 回放 63 PASS、0 FAIL，完整视频 386.93 秒；程序哈希与包内一致，媒体解码与压缩包完整性均验证。
