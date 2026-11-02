extends SceneTree
func _initialize():call_deferred("run")
func run():
	var g=load("res://game/memorial/main.tscn").instantiate();root.add_child(g);await create_timer(.3).timeout;g.save_store.path="user://v41_pose_fixture.json";g.begin();g.flags.intro_done=true;g.quartermaster.position=g.world.MEMORIAL;g.quartermaster.pose_name="seated";await create_timer(2).timeout
	var v=g.quartermaster.visual
	for name in ["pelvis","spine_01","Head","foot_l","foot_r","hand_l","hand_r"]:
		var i=v.skeleton.find_bone(name)
		if i>=0:print("POSE ",name," rel=",v.skeleton.to_global(v.skeleton.get_bone_global_pose(i).origin)-g.quartermaster.position)
	print("RIG ",v.rig.position," action=",v.playback.get_current_node())
	g.queue_free();await process_frame;quit()
