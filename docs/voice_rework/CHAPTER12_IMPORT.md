# 前两章配音迁移记录

2026-11-05，从相邻目录 `WanShuiQianShan_Voice_Rework_Source` 迁入新配音。

修改前 Git 回滚标记：`backup/before-chapter12-voice-import-7f4725c`。
音频与清单独立提交：`9dae203`。

| 清单目录 | 条数 | 用途 |
| --- | ---: | --- |
| assets/voices | 53 | 第一章基础配音 |
| assets/snow/voices | 22 | 第二章继承的雪山配音及旧入口 |
| assets/memorial/voices | 38 | 丰碑剧情配音 |
| assets/memorial/climax_voices | 20 | 高潮 A/B 录音，实际剧情仍覆盖加载 B 版 |

迁入前逐条确认两份工程的键集合、角色、原始文本、资源路径一致；高潮变体一致。133 条 WAV 均与旧版不同，均通过源清单 SHA-256 和 WAV 头检查。只替换清单引用的 WAV 和四份清单，保留本工程资源导入配置。

共享播放器增加 `display_text` 支持：使用原始对白计算事件键，再以清单里的新措辞显示字幕。三句差异见 `WORDING_CHANGES.json`。保留现有剧情、菜单、角色动画、队列策略与演出等待逻辑，不整文件覆盖队友脚本。第三章资源未修改。

验证：`tests/chapter12_voice_import.gd` 检查全部 133 条源文件校验值、导入资源时长，以及前两章真实场景中的新字幕、原事件键、播放路径、正常音高和高潮 B 版覆盖。源码与 Windows 导出包均通过。导出包测试以 `--packed` 跳过原始 WAV 字节校验（导出包保存的是转换后的资源），其余检查相同。

此验证不代表人工逐条试听或全剧情通关验收。
