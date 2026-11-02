extends SceneTree
var errors := 0
func _initialize(): call_deferred("run")
func check(ok: bool,message: String):
	print(("PASS: " if ok else "FAIL: ")+message)
	if not ok: errors+=1
func run():
	var actor=Node3D.new()
	actor.name="Player"
	root.add_child(actor)
	var visual=load("res://game/remaster/character_visual.gd").new()
	actor.add_child(visual)
	visual.mode="place"
	visual.hand_targets=[Vector3(-.25,.85,.45),Vector3(.25,.85,.45)]
	await create_timer(.75).timeout
	var skeleton=visual.skeleton
	for i in 2:
		var bone=skeleton.find_bone("hand_r" if i==0 else "hand_l")
		var hand=skeleton.to_global(skeleton.get_bone_global_pose(bone).origin)
		check(hand.distance_to(visual.hand_targets[i])<.12,"new rig hand contacts the work surface: "+str(hand))
	var head=skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("Head")).origin)
	check(head.y>.95 and head.y<1.55,"working pose keeps head upright above the work: "+str(head))
	var upper=skeleton.get_bone_global_pose(skeleton.find_bone("upperarm_r")).origin
	var wrist=skeleton.get_bone_global_pose(skeleton.find_bone("hand_r")).origin
	check(wrist.y<upper.y,"working arm points down toward timber")
	actor.queue_free()
	await process_frame
	await create_timer(.15).timeout
	quit(1 if errors else 0)
