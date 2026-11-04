extends SceneTree
var errors:=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok:errors+=1
func run():
	var g=load("res://game/golden_hook/main.tscn").instantiate();root.add_child(g);g.store.path="user://golden_hook_v11_stir_test.json";g.begin_chapter(true)
	g.story.step="simmer";g._simmer();await create_timer(3).timeout
	check(g.elder.visual.contact_profile=="ladle" and is_instance_valid(g.elder.visual.contact_prop),"the elder stirs with an actual wooden ladle in his hand")
	var hand=g.elder.visual.skeleton.find_bone("hand_r");var sk=g.elder.visual.skeleton
	var start=sk.to_global(sk.get_bone_global_pose(hand).origin);await create_timer(.35).timeout
	check(start.distance_to(sk.to_global(sk.get_bone_global_pose(hand).origin))>.025,"the stirring hand follows a real circular utensil movement")
	g.return_to_menu();await create_timer(.1).timeout;g.queue_free();await process_frame;await process_frame;OS.delay_msec(80);DirAccess.remove_absolute(ProjectSettings.globalize_path("user://golden_hook_v11_stir_test.json"));quit(1 if errors else 0)
