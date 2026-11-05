# Player rifle sound

- Asset: `assets/audio/rifle_player_arisaka.wav`
- Collection: The Free Firearm Sound Library (Prepared SFX Library)
- Authors: Ben Jaszczak, Brian Nelson, Kevin Heras, Matthew Nanney
- Source: https://opengameart.org/content/the-free-firearm-sound-library
- Download: https://opengameart.org/sites/default/files/Prepared%20SFX%20Library.7z
- License: CC0 1.0, https://creativecommons.org/publicdomain/zero/1.0/
- Retrieved: 2026-11-05
- Original archive member: `Prepared SFX Library/Arisaka/E_25P.wav`
- Source metadata: Arisaka, rifle, bolt action, .30-06, gunshot, near distance, front of shooter, left/right stereo. Used as a game sound reference, not a claim that the character carries this exact weapon or caliber.
- Original WAV SHA-256: `0f0190fb6826fb167b4eb5f1d2df25372b0c220d64633446d9e4ab48c018630d`
- Edited WAV SHA-256: `50304448729a1471fc705c06ff0dc18fb04c7b16a0ff38e2569dbfba95e71bad`

Editing (revised after listening feedback): downmix to mono, resample to 48 kHz, extract 1.6 seconds starting at sample 24907 (first shot only), high-pass 65 Hz, low-pass 12 kHz, compressor threshold 0.035 / ratio 4 / attack 0.1 ms / release 65 ms / makeup 3, soft saturation `tanh(sample * 2)`. Add quiet reflections filtered to 180–3500 Hz at 105/185/290 ms with gains 0.18/0.10/0.05. Normalize combined peak to -1 dBFS, 1 ms entrance fade and 100 ms exit fade, total 2 seconds, PCM signed 16-bit WAV. No pitch change or looping. Natural decay plus short filtered reflections avoids a long repeated-shot echo.

Chapter one uses this asset only for player shots at -2 dB. Background and NPC shots retain their previous assets and levels. Existing master volume still applies. Compared with the first imported version, the first 200 ms RMS rises from approximately -23.1 to -17.6 dBFS, plus 2 dB at playback; this is a measurable increase rather than only a changed filename.
