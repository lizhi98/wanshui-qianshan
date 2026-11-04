extends SceneTree
var errors:=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok:errors+=1
func run():
	var g=load("res://game/golden_hook/main.tscn").instantiate();root.add_child(g);g.store.path="user://golden_hook_v11_mix_test.json";g.begin_chapter(true)
	check(g.audio.get("music_volume")!=null and g.audio.get("effects_volume")!=null and g.audio.get("voice_volume")!=null,"music, effects and dialogue have separate gains")
	check(g.audio.get("spatial_ambience") is Array and g.audio.get("spatial_ambience").size()>=4,"ponds and camp use positioned ambience players")
	for id in ["shortage","hope","warm","urgent","memory"]:
		var audio=load("res://assets/golden_hook/audio/"+id+".wav")
		check(audio.get_length()>75,"composed narrative cue exceeds the old 48-second loop: "+id)
	g.audio.set_mood("silence");await create_timer(4).timeout
	check(not g.audio.music.playing,"the secret and farewell can fade completely to silence")
	g.queue_free();await process_frame;await process_frame;OS.delay_msec(80);DirAccess.remove_absolute(ProjectSettings.globalize_path("user://golden_hook_v11_mix_test.json"));quit(1 if errors else 0)
