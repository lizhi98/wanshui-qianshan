extends SceneTree
func _initialize():
	var store=load("res://game/memorial/save_store.gd").new()
	var d=JSON.parse_string(FileAccess.get_file_as_string("user://v41_story_fixture.json"))
	print("SAVE_DIAG valid=",store.valid(d)," version=",d.version," in=",d.version in [41,412]," eq=",d.version==412," director=",store.valid_director(d.director))
	quit()
