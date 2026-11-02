# 重制版素材与代码来源

V3.0 配音更新：50 条运行时中文男声 WAV 使用 Qwen3-TTS-12Hz-1.7B-CustomVoice（Apache-2.0）本地生成。逐句语境指令、声线、时长和文件哈希见 `assets/voices/manifest.json`；来源与授权见 `licenses/Chinese_Voices_Provenance.txt`、`licenses/Qwen3_TTS_Apache_2_0.txt`。这是合成配音，不是真人录音或克隆声线。以下记录保留原版素材来源。

记录日期：2026年10月21日。本文区分运行时资源、制作工具、未采用候选和仅为回归保留的旧资源。文件级 SHA-256 见 `ASSET_HASHES.json`；上游版本与原始下载记录见 `ASSET_SOURCES.json`。所有链接均指向原作者、维护者或官方分发地址。

## 运行时及制作资源

| 项目 | 作者与原始链接 | 下载版本及时间 | 许可 | 工程位置和修改 | 可随游戏分发 |
| --- | --- | --- | --- | --- | --- |
| Godot | Godot Engine contributors；https://godotengine.org/download/archive/4.6-stable/ | 4.6 stable，89cea1439；初版2026-10-14沿用 | MIT | 引擎与Windows导出模板；许可证见 `licenses/Godot_MIT.txt` | 是，保留MIT声明 |
| 第三人称控制器基础 | Kenney；https://github.com/KenneyNL/Starter-Kit-3D-Platformer | SHA 3fa8a04b1c01ab23db43123d4ce814a34c3fc7f0；2026-10-14 | 代码MIT，资产CC0 | `scripts/player.gd`、`scripts/view.gd`及派生 `game/player.gd`、`game/camera.gd`；保留速度平滑、重力、相机输入，加入剧情锁和攀索 | 是，代码保留MIT |
| 射线战斗参考与音效 | Kenney；https://github.com/KenneyNL/Starter-Kit-FPS | SHA 185fd2326d74a5cf858cffc616f87cf9696f9cc0；2026-10-14 | 代码MIT，资产CC0 | `game/combat.gd` 与 `assets/audio`中的引用音效；加入第三人称双射线、装填、抑制、距离和可关闭瞄准辅助 | 是 |
| MPFB自然人体与骨骼数据 | MakeHuman / MPFB contributors；https://github.com/makehumancommunity/mpfb2 | MPFB 2.0.18；SHA b1a2dc98776da9d1eea751b159d42cf61778fe2e；2026-10-21 | 工具代码GPLv3；核心图形资产CC0，生成输出CC0 | `assets/remaster/characters/*.glb`，`art_source/*.blend`；参数化年龄、身高、肌肉、脸型，53骨骼game_engine rig，重设T姿，蒙皮及形态键 | 生成网格、纹理与骨骼是；MPFB工具代码未嵌入游戏 |
| MakeHuman系统服装及附件 | Data Collection AB、Joel Palmius、Jonas Hauquier及MakeHuman贡献者；https://static.makehumancommunity.org/assets/assetpacks.html | 官方 `makehuman_system_assets_cc0.zip`；2026-10-21 | CC0，文件头明确重许可于2020年9月 | 使用 `male_casualsuit01`、`shoes02`、`high-poly`眼睛、`eyebrow001`、`short02`头发、young/middleage Asian male皮肤；改制灰蓝棉衣、裤子、鞋，修剪帽下头发；法务原始头记录见许可证目录 | 是 |
| 新制服细节与道具 | 本次项目制作；`tools/characters/build_characters.py` | 2026-10-21 | 本项目新增美术按CC0提供 | 独立网格的口袋、领片、门襟、纽扣、连续帽体与帽檐、红星、背包、毯卷、肩带、腰包；帽体按实际头围定位并100%绑定Head，头发在帽内收束；非给裸人体换颜色 | 是 |
| 人形动画 | Quaternius；https://quaternius.itch.io/universal-animation-library | 免费Standard版43段；2026-10-14沿用 | CC0 1.0 | `art_source/UAL1_Standard.glb` 为原始动作源；`tools/characters/retarget_clips.py`将全局静止姿态差转换到新骨架，20Hz烘焙；43段均封装在每个人物GLB中 | 是；未使用付费完整版动作 |
| 剧情解析与分支 | Nathan Hoad；https://github.com/nathanhoad/godot_dialogue_manager | 4.1.0；SHA 7a72dcf64cfec8673d398606f2991d4cf81f2d11；2026-10-21 | MIT | `addons/dialogue_manager`原插件；`game/remaster/dialogue.gd`、`hud.gd`自写展示层；运行时编译 `story/*.dialogue`，并非只放置未使用插件 | 是，保留MIT |
| 苔藓岩石模型 | Kless Gyzen / Poly Haven；https://polyhaven.com/a/rock_moss_set_01 | 官方1K glTF；2026-10-21 | CC0 | `assets/remaster/environment/rocks`；保留扫描模型与贴图，在场景中实例化、旋转和缩放 | 是 |
| 松树模型 | Rico Cilliers、Rob Tuytel / Poly Haven；https://polyhaven.com/a/pine_sapling_medium | 官方1K glTF；2026-10-21 | CC0 | `environment/pine_game.glb`；选择一棵原始树，由约266万三角面压缩到64999面；贴图封装，设置可见距离 | 是 |
| 岩石PBR贴图 | Dimitrios Savva、Rico Cilliers / Poly Haven；https://polyhaven.com/a/rock_boulder_dry | 1K diffuse / OpenGL normal / roughness；2026-10-21 | CC0 | `assets/remaster/pbr/stone_*`；用于桥台及地形岩层。该项是纹理，不称作扫描岩石模型 | 是 |
| 木板PBR贴图 | Rob Tuytel / Poly Haven；https://polyhaven.com/a/wood_planks_grey | 官方1K三贴图；2026-10-21 | CC0 | `pbr/wood_*`；通过木材shader调为旧木棕色，应用于桥板和物资道具 | 是 |
| 地表PBR贴图 | Rob Tuytel / Poly Haven；https://polyhaven.com/a/brown_mud_leaves_01 | 官方1K三贴图；2026-10-21 | CC0 | `pbr/ground_*`；与岩石三向贴图按坡度混合；地形网格为本作生成 | 是 |
| 中文字体 | Noto Project / Adobe / Google；https://github.com/google/fonts/tree/main/ofl/notosanssc | Noto Sans SC可变字体；2026-10-21下载 | SIL OFL 1.1 | `assets/remaster/fonts/NotoSansSC.ttf`，运行时指定字重；完整OFL文本随包 | 是，字体保留原名与OFL |
| 音乐与风声 | 本次项目原创合成；`tools/compose_score.py` | 2026-10-21 | CC0 | `assets/remaster/audio`；探索、战斗、攀索、结尾、现代篇五个40秒循环，以及12秒风声；未采样商业配乐，无真人或模仿演员配音 | 是 |
| 河流、地形、桥梁、建筑、旗帜、图标 | 本次项目制作，部分方法扩展初版 | 2026-10-21 | 新增美术CC0；新增整合代码沿工程MIT | `game/remaster/world.gd`、3个shader、`icon.svg`；13链结构、78米艺术化跨度；地形为连续网格，近景岩石和树来自上述真实资产 | 是 |

## 仅用于制作或评估

Blender 4.5.9 LTS，build 8bf95cbd38d1，来自 https://download.blender.org/release/Blender4.5/ ，2026-10-21下载。Blender按GPL许可作为外部制作工具运行；游戏包不捆绑该工具。Blender生成的本项目模型不因此成为GPL代码。

Phantom Camera 0.11.0.3，Marcus Skov，https://github.com/ramokz/phantom-camera ，MIT，2026-10-21下载并检查。最终选择扩展现有相机与自写 `shot_director.gd`，减少对旧控制器的替换；没有在功能列表中宣称使用Phantom Camera运行时。

Blender Studio / community Human Base Meshes v1.4.1，CC0，官方 https://www.blender.org/download/demo-files/ 与 https://download.blender.org/demo/asset-bundles/human-base-meshes/ 。2026-10-21实际下载并在Blender检查：所选真实头部基础网格无Armature、无动作，不是现成可游戏人物。静态导入对比放在候选评估材料中，不进入正式关卡。Rex成品rig也作了在线筛选；官方说明限制Blender 3.3—3.6，下载页面本次访问返回402，因此没有伪称已经成功导入或播放。

## 初版资源的保留边界

Quaternius Universal Base Characters Standard中的Superhero网格只保留在源工程旧关卡及旧测试引用中，许可CC0。重制默认场景的所有人物均实例化新的MPFB GLB；Windows导出排除了 `assets/characters/*`。旧角色来源及原始压缩包hash仍保存在 `SOURCE_MANIFEST.json`，不将它们冒充本次新人物。

## 许可文件及事实边界

`licenses/LICENSE.ASSETS.md`为MPFB图形资产的CC0全文；`licenses/LICENSE.md`说明MPFB工具代码与资产分离；`licenses/MPFB_GPL3_CODE_INFORMATION.md`附GPLv3原文作为工具许可信息。MakeHuman各MHCLO原始CC0头、MIT及OFL均在同目录。

史料不是美术素材。游戏对白为原创虚构，历史档案参考中国军网与泸定桥景区官方介绍，没有复制整篇史料；参考链接与艺术化改编说明列在作品报告中。没有使用《原神》模型、音乐、商标素材或商业游戏提取资源。
