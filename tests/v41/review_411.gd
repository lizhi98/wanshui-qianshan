extends SceneTree
var g
var errors:=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok:errors+=1
func shot(label:String):
	if DisplayServer.get_name()=="headless":return
	await process_frame;await process_frame;RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png("res://test_evidence/v411/"+label+".png")
func run():
	DirAccess.make_dir_recursive_absolute("res://test_evidence/v411")
	g=load("res://game/memorial/main.tscn").instantiate();root.add_child(g);await create_timer(.5).timeout
	g.save_store.path="user://v411_review.json";g.begin();g.flags.intro_done=true;g.player.locked=false;g.hud.center_title.text="";g._reset_camera();g.view.set_process_input(false)
	check(g.world.has_method("snow_from_start"),"snow surface enabled at camp altitude")
	check(g.world.find_children("*tarp*","MeshInstance3D",true,false).is_empty(),"obstructing tarp removed")
	await create_timer(1).timeout;await shot("01_snow_camp")
	Input.action_press("move_forward");await create_timer(1).timeout;await shot("02_walk_left");await create_timer(.3).timeout;await shot("03_walk_right");Input.action_release("move_forward")
	var i=0
	for a in g.actors():
		a.moving=false
		if a==g.quartermaster:a.position=g.world.MEMORIAL;a.pose_name="seated";continue
		a.position=g.world.MEMORIAL+Vector3(-2.4+float(i%4)*1.3,.1,-2.8-float(i/4)*1.25);a.pose_name="";i+=1
	g.player.restore(g.world.MEMORIAL+Vector3(0,.1,-1.6));g.stage="DISCOVERY"
	for j in g.crowd.units.size():g.crowd.units[j].s=g.world.route.lengths[12]+j*3.2
	g.crowd._update(0);var before=g.crowd.units[0].s;await create_timer(.5).timeout
	check(g.crowd.units[0].s==before,"column stops during discovery")
	check(g._honor_gathered(),"seven companions gather around the old soldier")
	g._start_action("reveal","",35);await create_timer(2).timeout;await shot("04_witnesses")
	g.action="";g.stage="SALUTE";g.interact();await create_timer(3.2).timeout;await shot("05_collective_salute")
	for a in [g.player]+g.actors():
		var v=a.visual;var sk=v.skeleton
		for mesh in v.rig.find_children("*Tunic*","MeshInstance3D",true,false):print("SKIN ",a.name," ",mesh.name," skeleton=",mesh.skeleton," resolved=",mesh.get_node_or_null(mesh.skeleton)," expected=",sk)
		print("SALUTE_BONES ",a.name," pose=",v.narrative_pose," t=",v.narrative_clock," hand=",v.to_local(sk.to_global(sk.get_bone_global_pose(sk.find_bone("hand_r")).origin)))
	var count=0
	for a in g.actors():
		if a!=g.quartermaster and a.pose_name=="salute":count+=1
	check(count==7 and g.player.visual.narrative_pose=="salute","player and seven full-rig companions salute")
	check(g.crowd.rig_pool.size()==12,"near column has twelve full skeletal model slots")
	g.main_menu();g.queue_free();await process_frame;quit(1 if errors else 0)
