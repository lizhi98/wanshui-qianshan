# 雪山新增资源与来源

记录日期：2026-10-30。雪山山体、路线、雪线着色、粒子贴图、脚印、布条、路线图及任务脚本为本次制作；代码沿项目 MIT，美术按 CC0 提供。未提取或使用《最后的生还者》或其他商业游戏的模型、纹理、音乐。

| 资源 | 使用方式与许可 |
| --- | --- |
| 连续山体与步道 | `game/snow/world.gd` 及 `route.gd` 生成，四个 `.res` 缓存位于 `assets/snow/terrain`；原创网格，CC0 |
| 雪线、踩实山道、风雪 | `terrain.gdshader`、`weather.gd`、`snow_cloud.png`；程序化原创，CC0 |
| 岩石、树木、地表 PBR | 复用 V3.3 Poly Haven CC0 资源；原作者、原链接与原始记录见 `ASSET_MANIFEST.md`、`ASSET_SOURCES.json`，没有新增下载 |
| 人物与动作 | 复用既有 MakeHuman/MPFB 53 骨骼人物、制服细节和动画；不宣称重新制作人物。原始 CC0/MIT/OFL 记录见 `licenses` 与既有清单 |
| 22 条雪山男声对白 | 本机 Qwen3-TTS-1.7B-CustomVoice 生成，角色使用三种男声及逐句情绪指令。是合成配音，不是真人录音。模型 Apache-2.0，逐句文本、指令、时长、SHA256 位于 `assets/snow/voices/manifest.json`，生成工具 `tools/Generate_Snow_Voices.py`；模型来源 https://huggingface.co/Qwen/Qwen3-TTS-12Hz-1.7B-CustomVoice |
| 三段原创配乐 | `snow_walk.wav`、`snow_crisis.wav`、`snow_summit.wav`，由 `tools/compose_snow_score.py` 原创编曲、合成；GeneralUser GS 音色库按其随附许可用于音乐作品，原许可见 `licenses/GeneralUser_GS_License.txt`；未复制电影配乐 |
| 雪地脚步、滑塌声 | `assets/snow/audio`，本次程序合成，CC0；沿用原风声，按高度和风势混音 |
| 中文字体与引擎 | 继续使用 Noto Sans SC（OFL）及 Godot（MIT），许可随包保留 |

历史参考与模型素材分别记录。地图使用压缩距离和相对高度，不是测绘模型；人物、布条和滑塌桥段为艺术化虚构。新增资源文件哈希随交付清单提供。
