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
- Edited WAV SHA-256: `e87025b9067f26e19fd78f1e83f1b42bd3c7221b255f7391af567a173071be2d`

Editing: downmix to mono, resample to 48 kHz, extract 1.6 seconds starting at 0.5188958333 seconds (first shot only), high-pass 60 Hz, low-pass 12 kHz, compressor threshold 0.18 / ratio 2 / attack 1 ms / release 80 ms / makeup 1.4, normalize peak to -2 dBFS, 1 ms entrance fade and 50 ms exit fade, PCM signed 16-bit WAV. No pitch change, looping, or artificial reverb. The recording's natural tail is retained.

Chapter one uses this asset only for player shots at -4 dB. Background and NPC shots retain their previous assets and levels. Existing master volume still applies.
