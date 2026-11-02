extends SceneTree
var game
var errors:=0
func _initialize(): call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok: errors+=1
func fixture():
	game._apply_snapshot({"version":3,"ledger":{"current":"repair","done":{"march":true,"recon":true,"escort":true}},"modules":{"repair":{"site":0,"step":"select","repaired":[false,false]}},"position":[0,.1,-3],"elapsed":0,"retries":0,"choice":0})
	# Isolate the original rear-wave casualty and player-cover mechanics.
	# V3.3's forward squad is exercised separately in coordination_checks.gd.
	game.vanguard.stop()
func run():
	Engine.time_scale=4; Engine.max_fps=120; Engine.physics_ticks_per_second=120
	game=load("res://game/v2/main.tscn").instantiate(); root.add_child(game)
	game.save_store.path="user://v3_assault_tests.json"
	await create_timer(.5).timeout
	fixture(); game.set_process(false)
	var saw_fall=false; var fell_outside=true
	for sample in 270:
		await create_timer(.1).timeout
		for i in game.assault.rows.size():
			if game.assault.rows[i].life=="fall":
				saw_fall=true
				if absf(game.assault.pool[i].position.x)<2: fell_outside=false
	check(game.assault.fallen>0 and game.assault.volleys>0,"unsuppressed enemy fire produces an actual non-graphic casualty")
	check(saw_fall and fell_outside,"casualty reaches the outer bridge edge before falling, rather than sinking through the deck")
	check(game.audio.recent.has(("林川:同志！……掩护，别让后面的人再倒下！").md5_text()),"first casualty queues its grief performance even after the wound warning")
	var all_stopped=true
	for i in game.assault.rows.size():
		if game.assault.rows[i].life=="run" and game.assault.pool[i].position.z< -8: all_stopped=false
	check(all_stopped,"reinforcements do not walk through an unrepaired gap")
	fixture(); game.set_process(false); game.view.set_physics_process(false)
	Input.action_press("aim"); await create_timer(.25).timeout
	var enemy=game.enemies[0]
	game.view.camera.look_at(enemy.position+Vector3(0,1.3,0))
	check(game.combat.fire_player(),"player can fire from repair chapter while hands are free")
	await create_timer(.15).timeout
	check(game.combat.hit_count>0 and game.assault.cover_time>8,"a real enemy ray hit establishes protection for crossing allies")
	Input.action_release("aim")
	await create_timer(12).timeout
	check(game.assault.fallen==0,"successful covering fire prevents the compared early casualties")
	game.assault.cover_time=999
	game.world.set_v2_repair(0,true); game.world.set_v2_repair(1,true)
	game.traversal.fixed=true; game.relay.clear=true
	game.player.position=Vector3(-1.2,0,-20)
	await create_timer(44).timeout
	check(game.assault.passed>0,"allies continuously cross the repaired bridge and reach the far bank")
	check(game.assault.pool.size()==8,"reinforcements reuse a bounded pool")
	var before=game.assault.pool[0].position
	game.paused=true; await create_timer(.5).timeout
	check(game.assault.pool[0].position.is_equal_approx(before),"pause freezes reinforcement movement and falling")
	game.paused=false
	var saved=game.assault.snapshot(); game.save_checkpoint()
	check(game.save_store.read().get("assault",{}).get("passed",-1)==saved.passed,"crossing progress persists with the checkpoint")
	game.repair.stop()
	game.repair.start({"site":0,"step":"pickup","material":"good"})
	game.player.position=game.repair.pickup_position(); game.amu.position=game.repair._pickup_helper_goal()
	game.repair.interact(); await create_timer(1.8).timeout
	check(game.player.carrying,"fixture completes the real cooperative lift")
	game.repair.suspend_carry(); await create_timer(.6).timeout
	check(game.repair.step=="parked" and not game.player.carrying and game.combat.can_use_weapon(),"right-click suspension releases board and enables covering fire")
	game.repair.interact(); await create_timer(1.8).timeout
	check(game.player.carrying and game.repair.step=="carry","E resumes the same parked timber without returning it to stock")
	game.repair.suspend_carry(); game.save_checkpoint()
	check(game.continue_story() and game.repair.step=="pickup" and not game.player.locked,"checkpoint during parked covering fire restores safe preparation")
	check(game.player.position.distance_to(game.repair.safe_position())<.2,"restored parked carry places the player with the reset board")
	var invalid=game.last_checkpoint.duplicate(true); invalid.assault={"passed":-1}
	check(not game.save_store.valid(invalid),"negative assault counters are rejected without replacing the checkpoint")
	game.repair.stop(); game.audio.clear_voice()
	for node in game.find_children("*","AudioStreamPlayer",true,false): node.stop(); node.stream=null
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	print("V3 ASSAULT FAILURES ",errors); quit(1 if errors else 0)
