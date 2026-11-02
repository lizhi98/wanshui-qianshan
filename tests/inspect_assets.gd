extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	var scene = load("res://assets/characters/Soldier.gltf").instantiate()
	root.add_child(scene)
	var skeleton = scene.find_children("*","Skeleton3D",true,false)[0]
	var animation = scene.find_children("*","AnimationPlayer",true,false)[0]
	print("ANIMATIONS: ", animation.get_animation_list())
	print("SKELETON TRANSFORM ",skeleton.global_transform)
	for name in ["Head","pelvis","upperarm_l","lowerarm_l","hand_l","upperarm_r","lowerarm_r","hand_r","thigh_l","calf_l"]:
		var index = skeleton.find_bone(name)
		print(name," REST ",skeleton.get_bone_global_rest(index)," POSE ",skeleton.get_bone_global_pose(index))
	print("TRACK0: ",animation.get_animation(animation.get_animation_list()[1]).track_get_path(0))
	scene.queue_free()
	await process_frame
	quit()
