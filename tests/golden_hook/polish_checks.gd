extends SceneTree
var errors:=0
func _initialize(): call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok: errors+=1
func fingertip(visual,side:String,finger:String)->Vector3:
	var sk=visual.skeleton; var index=sk.find_bone(finger+"_03_"+side)
	var pose=sk.get_bone_global_pose(index)
	return sk.to_global(pose.origin+pose.basis.y*.021)
func run():
	var g=load("res://game/golden_hook/main.tscn").instantiate(); root.add_child(g)
	g.store.path="user://golden_hook_polish_test.json"; g.begin_chapter(true)
	g.player.locked=true; g.player.visual.posture="kneel"; g.player.visual.hold("hook")
	await create_timer(.8).timeout
	var v=g.player.visual
	var eye=v.held_node.to_global(Vector3(0,.058,0))
	for finger in ["thumb","index"]:
		var distance=fingertip(v,"r",finger).distance_to(eye)
		print("CONTACT ",finger," ",distance)
		check(distance<.021,"the "+finger+" pad pinches the actual hook eye within 21mm")
	v.hold("bowl"); await create_timer(.8).timeout
	for side in ["r","l"]:
		var point=v.held_node.to_local(fingertip(v,side,"middle"))
		check(absf(Vector2(point.x,point.z).length()-.105)<.035 and point.y>.0 and point.y<.13,"bowl fingertips contact its exterior: "+side)
	var last=[]
	for i in v.skeleton.get_bone_count(): last.append(v.skeleton.get_bone_global_pose(i))
	await create_timer(.2).timeout
	var max_change=0.0
	for i in v.skeleton.get_bone_count():
		var pose=v.skeleton.get_bone_global_pose(i)
		check(pose.is_finite(),"finite held-pose bone "+str(i))
		max_change=maxf(max_change,pose.origin.distance_to(last[i].origin))
	check(max_change<.09,"a sustained prop hold has no large skeleton snap")
	v.hold(""); v.posture="collapsed"; v.conversation_role=1; v.mode="talk"
	await create_timer(.3).timeout
	var shut=true
	for m in v.face_meshes: shut=shut and m.get_blend_shape_value(0)>.98
	check(shut,"collapsed actors keep both lids closed despite a stale speaking role")
	g.return_to_menu(); g.queue_free(); await process_frame; await process_frame; OS.delay_msec(50)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://golden_hook_polish_test.json"))
	quit(1 if errors else 0)
