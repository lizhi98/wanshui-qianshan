extends SceneTree
var errors:=0
func _initialize(): call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok: errors+=1
func run():
	var game=load("res://game/v2/main.tscn").instantiate(); root.add_child(game)
	await create_timer(.3).timeout
	game.player.set_physics_process(false)
	var visual=game.player.visual
	visual.set_process(false); visual.mode="climb"; visual.armed=false
	game.player.position=Vector3(1.43,.04,-55); game.player.rotation.y=PI/2
	var first:Vector3; var max_delta=0.0; var planted_frames=0
	var prev=Vector3.INF
	for i in 120:
		game.player.position.z-=.4/60.0; visual.speed=1.4; visual._process(1.0/60)
		visual.skeleton.force_update_all_bone_transforms()
		var wrist=visual.skeleton.get_bone_global_pose(visual.skeleton.find_bone("hand_r")).origin
		if i==0: first=wrist
		max_delta=maxf(max_delta,wrist.distance_to(first))
		var world=visual.skeleton.to_global(wrist)
		if i%20==0: print("GRIP ",i," world=",world," target=",visual.climb_grips.get("r")," error=",visual.hand_error," delta=",world.distance_to(prev))
		if prev!=Vector3.INF and world.distance_to(prev)<.0025: planted_frames+=1
		prev=world
	check(max_delta>.15,"hand position changes relative to the travelling torso")
	print("PLANTED ",planted_frames," HAND_ERROR ",visual.hand_error); check(planted_frames>25,"gripping hand remains planted in world space between reaches")
	check(visual.get("climb_grips") is Dictionary,"two independent chain contacts are available for inspection")
	visual.speed=0; var before=visual.skeleton.get_bone_global_pose(visual.skeleton.find_bone("foot_r")).origin
	for i in 60: visual._process(1.0/60)
	var after=visual.skeleton.get_bone_global_pose(visual.skeleton.find_bone("foot_r")).origin
	check(after.distance_to(before)<.03,"stopping movement stops the stepping cycle")
	for node in game.find_children("*","AudioStreamPlayer",true,false): node.stop(); node.stream=null
	game.queue_free(); await process_frame; quit(1 if errors else 0)
