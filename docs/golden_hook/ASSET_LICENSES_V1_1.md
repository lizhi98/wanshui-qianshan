# V1.1 资产来源与许可记录

| 类别 | 实际使用与处理 | 许可记录/来源 |
|---|---|---|
| 人物基底与服装 | 延用 MPFB/MakeHuman 系统资产输出；阿青和老班长在原输出上改脸形、服装/配件与老化效果 | licenses/MakeHuman_System_Assets_CC0_Records.txt；MPFB 代码许可与输出资产许可分列，代码未作为运行时依赖 |
| 43 段角色动作 | Quaternius Universal Animation Library Standard，重定向到 53 骨骼 | licenses/Quaternius_Animations_CC0.txt；art_source/UAL1_Standard.glb |
| 低草/中草/灌木 | Poly Haven grass_bermuda_01 / grass_medium_01 / shrub_02，保留原始模型，减面为近中 LOD，重做运行时 alpha 材质 | [Poly Haven CC0](https://polyhaven.com/license)；V1_1_ASSET_PROVENANCE.json 记录作者、链接与哈希 |
| 岩石/搪瓷锅 | rock_moss_set_01 / pot_enamel_01；锅盖在烹饪中隐藏，开放汤面和木勺 | 同上，官方资产页面与派生记录随附 |
| 地面与天空 | brown_mud_02、aerial_grass_rock 与 kloofendal_overcast_puresky 2k HDRI | licenses/PolyHaven_V1_1_CC0.md；官方资产清单含作者 |
| 字体 | Noto Sans SC 中文字体 | licenses/NotoSansSC_OFL.txt |
| 本轮原创模型/着色 | 粮袋、布包、布顶、卷毯、芦苇、鱼、木勺、连续鱼钩、包布形态键及剧情道具控制 | Blender / GDScript 创作源随交付；没有从商业游戏提取模型 |
| 本轮配乐 | 原创 MIDI 编排，FluidSynth 2.6.1 / GeneralUser GS 2.0.3 采样乐器渲染；MIDI 与成品 WAV 随交付，采样库和合成器不进入游戏运行包 | [GeneralUser GS 官方仓库](https://github.com/mrbumpy409/GeneralUser-GS)；licenses/GeneralUser_GS_V1_1.txt 保留完整许可和作者说明，不自行简化为 CC0 |
| 本轮环境/事件音效 | 项目原创程序合成并离线播放，池塘/营火采用空间声源 | MUSIC_MANIFEST.md、BGM_EVENTS.csv |
| 第三关中文语音 | 五种 Microsoft Edge 神经声线，81 个本地 WAV；无真人克隆，无付费账户或 API 密钥 | NEURAL_VOICE_PROVENANCE.json；输出未声明 CC0，工具许可不代替供应商声音输出适用条件；公开发行用途仍待项目方核对记录 |
| 已有前两关声音/模型 | 从用户自己 V4.1.3 包恢复并沿用，原 14 类许可与生成来源记录一并保留 | assets/*/voices/manifest.json；licenses/Chinese_Voices_Provenance.txt 等记录；不能把这些旧声线标为本轮第三关制作 |
| 引擎和对话插件 | Godot 4.6、Dialogue Manager | licenses/Godot_MIT.txt、Dialogue_Manager_MIT.txt |

详细原始资产在 art_source/V1_1_vendor（编辑器忽略）及 art_source 的 Blender 文件中，运行时仅加载优化后资产。整个整合工程没有被擅自改为统一 CC0/MIT 项目，也没有替用户公开发布。文学来源和改编边界见 SOURCES.md。
