extends SceneTree
var errors:=0
var game
func _initialize(): call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS: " if ok else "FAIL: ")+label)
	if not ok: errors+=1
func signal_move(module):
	await process_frame
	Input.action_press("signal"); module.tick(.016); Input.action_release("signal")
func wait_for_leg(module,number:int):
	var elapsed=0.0
	while module.leg<number and elapsed<8:
		await create_timer(.05).timeout; module.tick(.05); elapsed+=.05
func path_clear(module)->bool:
	var start=module.START_A if module.route=="A" else module.START_B
	for path in module.paths:
		for point in path:
			for side in [-.30,0,.30]:
				var offset=Vector3(side,.55,0)
				var query=PhysicsRayQueryParameters3D.create(start+offset,point+offset,1)
				if not game.get_world_3d().direct_space_state.intersect_ray(query).is_empty(): return false
			start=point
	return true
func run():
	check(FileAccess.file_exists("res://game/v2/escort.gd"),"escort module exists")
	if errors: quit(1); return
	if not InputMap.has_action("signal"): InputMap.add_action("signal")
	game=load("res://game/remaster/main.tscn").instantiate(); root.add_child(game); current_scene=game
	await create_timer(.7).timeout
	game.save_store.path="user://v2_escort_test.json"; game.begin(true); game.set_process(false)
	game.phase=game.Phase.COMBAT; game.player.restore(Vector3(0,.1,10))
	for enemy in game.enemies: enemy.cooldown=999
	game.zhou.cooldown=999; game.amu.position=Vector3(.9,0,11.8)
	var reconnaissance=load("res://game/v2/recon.gd").new(); game.add_child(reconnaissance); reconnaissance.setup(game)
	var module=load("res://game/v2/escort.gd").new(); game.add_child(module); module.setup(game); module.start({"route":"A"})
	await physics_frame
	check(path_clear(module),"short-route NPC waypoints clear the actual scene collision")
	var results:Array=[]; module.completed.connect(func(result): results.append(result))
	await signal_move(module)
	check(not game.amu.moving,"unsafe Q cannot start an uncovered advance")
	game.enemies[0].damage(34); module.tick(.05)
	check(module.window_remaining>0,"effective defender damage opens the first safe window")
	await process_frame
	var origin=game.amu.position
	Input.action_press("signal"); module.tick(.016); Input.action_release("signal")
	check(game.amu.moving and game.amu.position.distance_to(origin)<.01,"Q starts a path instead of teleporting the ally")
	game.paused=true; var pause_origin=game.amu.position; var pause_window=module.window_remaining
	await create_timer(.2).timeout; module.tick(.2)
	check(game.amu.position.distance_to(pause_origin)<.001 and is_equal_approx(module.window_remaining,pause_window),"pause preserves NPC location and pressure-window time")
	game.paused=false
	var first_path=game.amu.route.duplicate()
	await create_timer(.6).timeout; module.tick(.6)
	check(game.amu.position.distance_to(origin)>.4,"ally visibly travels while covering continues")
	module.tick(10)
	var held=game.amu.position
	await create_timer(.2).timeout
	check(module.waiting_for_cover and held.distance_to(game.amu.position)<.01,"expired pressure pauses exposed movement safely")
	game.enemies[0].damage(100); module.tick(.05)
	await wait_for_leg(module,1)
	check(module.leg==1,"first real route reaches a safe cover checkpoint")
	await signal_move(module); check(not game.amu.moving,"second advance needs its own threat window")
	game.enemies[1].damage(100); module.tick(.05); await signal_move(module)
	await wait_for_leg(module,2)
	check(module.leg==2 and results.size()==1,"two covered advances complete the escort once")
	module.tick(2); check(results.size()==1,"completed escort cannot emit duplicate success")
	module.stop(); game.amu.position=Vector3(3.7,0,11.8); game.amu.moving=false
	module.start({"route":"B","enemy_health":[0,0]})
	await process_frame
	await signal_move(module)
	check(not game.amu.moving,"side-route crate must be cleared before advancing")
	game.player.position=module.blocker_position; module.interact()
	check(module.blocker_cleared,"nearby E removes the real side-route blocker")
	await physics_frame
	check(path_clear(module),"side-route NPC waypoints clear all physical covers")
	await signal_move(module)
	check(game.amu.moving and game.amu.route!=first_path,"early defeated threats still permit the distinct B path")
	game.combat.ammo=0; game.combat.reserve=0; game.player.position=module.supply_position; module.interact()
	check(game.combat.ammo==5 and game.combat.reserve>=25,"real supply crate prevents an empty-ammo soft lock")
	game.combat.ammo=0; game.combat.reserve=0; module.interact()
	check(game.combat.ammo==5 and game.combat.reserve>=25,"supply can be used again after more ammunition is spent")
	var state=module.snapshot(); module.stop(); module.start(state)
	check(module.route=="B" and module.blocker_cleared and module.leg==0,"checkpoint restores branch and partial escort state")
	check(not game.amu.moving and game.amu.position.distance_to(module.START_B)<.01,"mid-transfer checkpoint returns to the last actual safe cover")
	check(path_clear(module),"side route avoids both reconnaissance and escort cover geometry")
	check(JSON.parse_string(JSON.stringify(state)) is Dictionary,"escort snapshot contains serializable state")
	module.stop(); game.queue_free(); await process_frame; await create_timer(.15).timeout
	quit(1 if errors else 0)
