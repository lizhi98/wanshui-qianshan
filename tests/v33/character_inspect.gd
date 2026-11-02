extends SceneTree
func _initialize():call_deferred("run")
func run():
	var rig=load("res://assets/remaster/characters/linchuan.glb").instantiate();root.add_child(rig)
	await process_frame
	for mesh in rig.find_children("*","MeshInstance3D",true,false):print("CHAR ",mesh.name," aabb=",mesh.get_aabb()," mat=",mesh.get_active_material(0))
	var sk=rig.find_children("*","Skeleton3D",true,false)[0]
	for i in sk.get_bone_count():
		if "spine" in sk.get_bone_name(i) or "pelvis" in sk.get_bone_name(i):print("BONE ",sk.get_bone_name(i)," ",sk.get_bone_global_rest(i))
	rig.queue_free();await process_frame;quit()
