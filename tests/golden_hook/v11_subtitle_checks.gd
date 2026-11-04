extends SceneTree
var errors:=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok:errors+=1
func run():
	var g=load("res://game/golden_hook/main.tscn").instantiate();root.add_child(g);g.store.path="user://golden_hook_v11_subtitle_test.json";g.begin_chapter(true)
	g.hud.show_dialogue("小梁","一起走。");await process_frame;await process_frame;var short_size=g.hud.dialogue_panel.size
	g.hud.show_dialogue("老班长","你们还病着，一点鱼肉，能多添一点气力。前面的路，咱们还要一道想办法，一道往前走。");await process_frame;await process_frame
	check(g.hud.dialogue_panel.size.x>short_size.x and g.hud.dialogue_panel.size.y>short_size.y,"subtitle dimensions adapt to short and long lines")
	check(g.hud.dialogue_panel.get_global_rect().end.y<700,"subtitles stay above the lower cinematic bar")
	g.return_to_menu();g.queue_free();await process_frame;await process_frame;OS.delay_msec(80);DirAccess.remove_absolute(ProjectSettings.globalize_path("user://golden_hook_v11_subtitle_test.json"));quit(1 if errors else 0)
