# 泸定桥 V2.2 · 男声配音与清晰指引

运行 Windows/LudingBridge_V2_2.exe。音频、人物、场景和教程均已内嵌，无需联网或安装语音引擎。原故事与搬运修复保留。

## 看哪里、怎么走

右上角黑底金边卡片会给出本阶段的目标、简短教程和当前按键。金色光柱/光圈标出任务目标，地面金色点引导到下一个安全路标。画面里与屏幕边缘的标记都有目标名称和距离；底部方向卡会指出前方、身后或左右，转身不会丢掉目标。

选材、定位、绑绳、检查、绕到取板端、呼叫队友、共同搬运、放下、固定，以及观察/战斗/攀索/绳轮/结构重建各阶段均有独立说明。WASD 移动、鼠标视角、E 交互，按右上提示使用 F、Q 或空格。修桥操作中 R 可取消恢复；战斗中 R 仍是装填。

## 新版配音

47 条中文男性神经配音，24 kHz PCM WAV。周班长使用较低沉的 zm_009，林川使用 zm_012，阿木使用较年轻的 zm_016。这是三个独立男声音色，不再使用旧 Windows SAPI 的变调方案。配音仍是神经合成，不是真人演员录音。

采用 Apache-2.0 的 Kokoro-82M-v1.1-zh，经 sherpa-onnx 离线生成。许可证和来源见 licenses/Chinese_Voices_Provenance.txt 与 Kokoro_Apache_2_0.txt。重新生成使用 tools/Generate_Neural_Voices.py --model-dir 模型文件夹；需要 Python、sherpa-onnx 和 soundfile。游戏只播放随包 WAV，不依赖这些工具。

模型下载：https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/kokoro-int8-multi-lang-v1_1.tar.bz2
官方模型：https://huggingface.co/hexgrad/Kokoro-82M-v1.1-zh

## 工程与测试

Godot 4.6 stable 标准版。导入 project.godot 继续编辑；应用内部名称保留 V2.0 以兼容原存档目录，窗口与菜单标识 V2.2。运行测试和构建前设置 GODOT_PATH 指向 Godot 4.6 可执行程序，Windows 导出需要对应版本的导出模板。

完整通关视频由最终发行 EXE 的实际渲染和游戏音频录制，自动输入回放操作；不是拼接截图。采用 A 路线，从标题、新故事、各任务一直到尾声结算。录制时保留阅读教程的停顿。测试记录见 test_evidence/v22/，本次变更见 UPDATE_REPORT_V2_2.md；V2.1 和更早文件仅供历史对照。
