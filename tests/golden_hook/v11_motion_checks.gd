extends SceneTree
var errors:=0
func _initialize(): call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok: errors+=1
func run():
	var g=load("res://game/golden_hook/main.tscn").instantiate(); root.add_child(g);g.store.path="user://golden_hook_v11_motion_test.json";g.begin_chapter(true)
	await create_timer(.5).timeout
	check(g.player.visual.get("ground_contact")!=null,"chapter uses the V4.1.3 foot contact solver")
	g.player.locked=true;g.elder.moving=false;g.elder.visual.posture="collapsed"
	await create_timer(3).timeout
	var sk=g.elder.visual.skeleton
	var chest=sk.to_global(sk.get_bone_global_pose(sk.find_bone("spine_03")).origin)
	for side in ["l","r"]:
		var hand=sk.to_global(sk.get_bone_global_pose(sk.find_bone("hand_"+side)).origin)
		check(hand.distance_to(chest)<.48,"resting elder keeps the "+side+" arm folded beside the body")
	var head=sk.to_global(sk.get_bone_global_pose(sk.find_bone("Head")).origin)
	check(head.y-g.world.height_at(head)>.10 and head.y-g.world.height_at(head)<.39,"the resting head has low, grounded support")
	for bone in ["pelvis","Head","hand_r","hand_l","calf_r","calf_l","foot_r","foot_l"]:
		print("BONE ",bone," ",sk.to_global(sk.get_bone_global_pose(sk.find_bone(bone)).origin))
	g.story.elder_fate="sacrificed";g.elder.visual.speaking=false
	await create_timer(.5).timeout
	var before=sk.get_bone_global_pose(sk.find_bone("Head"))
	await create_timer(.4).timeout
	check(before.is_equal_approx(sk.get_bone_global_pose(sk.find_bone("Head"))),"the deceased elder has no breathing or idle head motion")
	g.queue_free();await process_frame;await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://golden_hook_v11_motion_test.json"));quit(1 if errors else 0)
