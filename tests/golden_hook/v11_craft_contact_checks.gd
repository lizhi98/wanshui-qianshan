extends SceneTree
var errors:=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok:errors+=1
func run():
	var g=load("res://game/golden_hook/main.tscn").instantiate();root.add_child(g);g.store.path="user://golden_hook_v11_craft_test.json";g.begin_chapter(true)
	g.story.step="heat";g.story.done.needle=true;g.story.done.place_parts=true;g.world.update_story(g.story);g._enter_craft()
	await create_timer(5).timeout
	check(g.elder.visual.contact_profile=="hook" and g.elder.visual.external_grip,"crafting uses the real needle eye as the elder's pinch target")
	var sk=g.elder.visual.skeleton;var index=sk.find_bone("index_03_r")
	var tip=sk.to_global(sk.get_bone_global_pose(index)*Vector3(0,.021,0))
	var eye=g.world.work_hook.to_global(Vector3(0,.058,0))
	print("CRAFT_PINCH_DISTANCE ",tip.distance_to(eye))
	check(tip.distance_to(eye)<.027,"the heated needle remains within the actual fingertips")
	var pot=g.world.pot
	var hot=g.world.work_hook.global_position
	check(Vector2(hot.x-pot.global_position.x,hot.z-pot.global_position.z).length()>.38,"the heated needle is beside the open fire rather than inside the pot wall")
	var lids=pot.find_children("*lid*","MeshInstance3D",true,false)
	check(not lids.is_empty() and not lids[0].is_visible_in_tree(),"the cooking pot is open so the soup and stirring ladle remain visible")
	g.return_to_menu();g.queue_free();await process_frame;await process_frame;OS.delay_msec(80);DirAccess.remove_absolute(ProjectSettings.globalize_path("user://golden_hook_v11_craft_test.json"));quit(1 if errors else 0)
