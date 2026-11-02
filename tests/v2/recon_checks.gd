extends SceneTree
var errors:=0
var game
func _initialize(): call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS: " if ok else "FAIL: ")+label)
	if not ok: errors+=1
func observe(module):
	await process_frame
	Input.action_press("observe"); module.tick(.016); Input.action_release("observe")
func run():
	check(FileAccess.file_exists("res://game/v2/recon.gd"),"recon module exists")
	if errors: quit(1); return
	if not InputMap.has_action("observe"): InputMap.add_action("observe")
	game=load("res://game/remaster/main.tscn").instantiate(); root.add_child(game); current_scene=game
	await create_timer(.7).timeout
	game.save_store.path="user://v2_recon_test.json"; game.begin(true); game.set_process(false)
	game.player.restore(Vector3(0,.1,16)); game.view.set_physics_process(false)
	var module=load("res://game/v2/recon.gd").new(); game.add_child(module); module.setup(game); module.start()
	await physics_frame
	await observe(module)
	check(module.observing,"F enters freely aimed observation camera")
	module.observation_camera.look_at(Vector3(50,30,25))
	module.tick(2.0)
	check(module.snapshot().found.is_empty(),"F toward empty terrain does not discover targets")
	game.paused=true; module.observation_camera.look_at(module.target_point("cover")); module.tick(2)
	check(module.snapshot().found.is_empty(),"paused observation cannot accrue discovery progress")
	game.paused=false
	var point=module.target_point("cover")
	var blocker=StaticBody3D.new(); var shape=CollisionShape3D.new(); shape.shape=BoxShape3D.new(); shape.shape.size=Vector3(4,3,.7)
	blocker.add_child(shape); game.add_child(blocker); blocker.global_position=module.observation_camera.global_position.lerp(point,.5)
	await physics_frame
	module.observation_camera.look_at(point); module.tick(2.0)
	check(not "cover" in module.snapshot().found,"solid cover interrupts observation line of sight")
	blocker.queue_free(); await physics_frame; await physics_frame
	for key in ["firepoint","gap","cover"]:
		module.observation_camera.look_at(module.target_point(key))
		module.tick(.45)
		check(not key in module.snapshot().found,"target requires a sustained observation: "+key)
		module.tick(.8)
		check(key in module.snapshot().found,"real target can be identified: "+key)
	var found=module.snapshot().found.size()
	module.tick(2)
	check(module.snapshot().found.size()==found,"repeated observation cannot inflate progress")
	game.player.position=Vector3(0,0,20); module.interact()
	check(module.snapshot().route.is_empty(),"route selection requires approaching a real sign")
	await observe(module)
	check(not module.observing and game.view.camera.current,"F restores original third-person camera")
	var results:Array=[]; module.completed.connect(func(result): results.append(result))
	game.player.position=Vector3(3.7,0,11.3); module.interact()
	check(results.size()==1 and results[0].route=="B","E at actual B sign commits the side route")
	module.interact(); check(results.size()==1,"route completion emits once")
	var state=module.snapshot(); module.stop(); module.start(state)
	check(module.snapshot().found.size()==3 and module.snapshot().route=="B","observation and route survive restore")
	check(JSON.parse_string(JSON.stringify(state)) is Dictionary,"recon snapshot contains serializable state")
	module.stop(); game.queue_free(); await process_frame; await create_timer(.15).timeout
	quit(1 if errors else 0)
