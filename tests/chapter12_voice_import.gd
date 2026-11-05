extends SceneTree

var failures: Array[String] = []

func _initialize():
	call_deferred("run")

func check(ok: bool, message: String):
	if not ok:
		failures.append(message)
		push_error(message)

func run():
	var count := 0
	for folder in ["assets/voices", "assets/snow/voices", "assets/memorial/voices", "assets/memorial/climax_voices"]:
		var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://" + folder + "/manifest.json"))
		for key in manifest:
			var row = manifest[key]
			# Exports store imported WAV resources rather than the original source bytes.
			if not "--packed" in OS.get_cmdline_user_args():
				check(FileAccess.get_sha256(row.file) == row.sha256, "Recording hash: " + key)
			var stream = load(row.file)
			check(stream is AudioStreamWAV and absf(stream.get_length() - float(row.duration_seconds)) < .02, "Recording duration: " + key)
			count += 1
	for scene in ["res://game/v2/main.tscn", "res://game/memorial/main.tscn"]:
		var mission = load(scene).instantiate()
		root.add_child(mission)
		await process_frame
		mission.set_process(false)
		mission.audio.set_process(false)
		var audio = mission.audio
		for key in audio.voice_manifest:
			var row = audio.voice_manifest[key]
			if row.get("display_text", row.text) == row.text:
				continue
			audio.clear_voice()
			audio.enqueue_voice(row.who, row.text)
			audio._next_voice()
			check(audio.last_voice.key == key, "Original event key: " + key)
			check(audio.last_voice.text == row.display_text, "Revised subtitle: " + key)
			check(mission.hud.bark_label.text.contains(row.display_text), "Visible subtitle: " + key)
			check(audio.voice.playing and audio.voice.stream.resource_path == row.file, "Playback file: " + key)
			check(audio.voice.pitch_scale == 1.0, "Natural playback speed: " + key)
		if scene.contains("memorial"):
			var climax = JSON.parse_string(FileAccess.get_file_as_string("res://assets/memorial/climax_voices/manifest.json"))
			for key in climax:
				if climax[key].variant == "B":
					check(audio.voice_manifest[key].file == climax[key].file, "Climax B override: " + key)
		audio.clear_voice()
		mission.queue_free()
		await process_frame
		await create_timer(.4).timeout
	print("CHAPTER12_VOICE_IMPORT ", "PASS" if failures.is_empty() else "FAIL", " recordings=", count, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
