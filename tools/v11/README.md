# V1.1 创作工具

交付的 GLB/WAV 可直接导入，不要求重新生成。模型创作源在 art_source；Poly Haven 原始模型在 art_source/V1_1_vendor，.gdignore 防止编辑器重复导入。许可、作者和哈希在 docs/golden_hook/V1_1_ASSET_PROVENANCE.json。

Blender 4.5 LTS：运行 `blender --background --python tools/v11/build_v11_camp.py`、build_v11_reeds.py、build_v11_fish.py 或 build_v11_ladle.py 可分别重建原创道具。build_v11_art.py 会重建阿青、优化外部资产和布包；age_elder_v11.py 重建老班长。重建人物后必须再以 Python 执行 `attach_qing_animation.py qing` 或 `attach_qing_animation.py elder`，把同名骨骼动画接回模型。若刻意重做源人物，需要先移走 art_source 对应 *_v11_base.glb 缓存，以免重接旧基底。保留工作副本后再执行覆盖式美术生成。

配乐：`python tools/v11/compose_v11_score.py --fluidsynth PATH_TO_FLUIDSYNTH --soundfont PATH_TO_GENERALUSER_GS.sf2`。六份 MIDI 已独立提供，无需工具即可在 DAW 中编辑。

语音：直接替换稳定 ID 的 WAV，再运行 `python tools/golden_hook/build_voice_envelopes.py`，重新导入/构建并审听。当前不附自动联网批量 TTS 命令，避免在重建工程时产生未预期的数据传输或服务依赖；所有正式 WAV 和生成参数已随源码交付。
