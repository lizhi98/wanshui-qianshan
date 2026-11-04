extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var a=load("res://assets/remaster/characters/zhou.glb").instantiate(); root.add_child(a)
	var ap=a.find_children("*","AnimationPlayer",true,false)[0]
	print("CLIPS ",ap.get_animation_list())
	var sk=a.find_children("*","Skeleton3D",true,false)[0]
	for id in ["root","pelvis","thigh_r","calf_r","foot_r","spine_01","hand_r"]:
		var n=sk.find_bone(id)
		if n>=0: print(id," REST ",sk.get_bone_global_rest(n))
	a.queue_free(); await process_frame; quit()
