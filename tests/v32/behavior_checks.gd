extends SceneTree
var errors:=0
func _initialize(): call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok: errors+=1
func run():
	Engine.time_scale=4
	var game=load("res://game/v2/main.tscn").instantiate(); root.add_child(game)
	await create_timer(.3).timeout
	game.save_store.path="user://v32_motion_fixture.json"
	game._apply_snapshot({"version":3,"ledger":{"current":"traversal","done":{"march":true,"recon":true,"escort":true,"repair":true}},"modules":{"repair":{"repaired":[true,true]}},"position":[1.43,.05,-54.35],"elapsed":0,"retries":0,"choice":0})
	game.assault.cover_time=999
	var runner=game.assault.pool[0]; var row=game.assault.rows[0]
	runner.show(); runner.position=Vector3(-1.2,0,-30); runner.rotation.y=PI/2
	row.life="run"; row.index=4; row.fire_clock=0; game.assault.clock=9.4
	var before_yaw=runner.rotation.y; game.assault._advance(0,1.0/60)
	check(absf(angle_difference(before_yaw,runner.rotation.y))<.15,"a firing opportunity cannot snap a running soldier around")
	await create_timer(32).timeout
	var previous=[]; var modes=[]; var switches=0; var max_yaw=0.0
	for actor in game.assault.pool: previous.append(actor.rotation.y); modes.append(actor.visual.mode)
	for frame in 600:
		await physics_frame
		for i in game.assault.pool.size():
			var actor=game.assault.pool[i]
			if game.assault.rows[i].life!="run": continue
			max_yaw=maxf(max_yaw,absf(angle_difference(previous[i],actor.rotation.y)))
			if modes[i]!=actor.visual.mode: switches+=1
			previous[i]=actor.rotation.y; modes[i]=actor.visual.mode
	print("MOTION max_yaw_step=",max_yaw," state_switches=",switches)
	check(max_yaw<.35,"queued troops do not snap their body around to fire")
	check(switches<70,"blocked troops do not alternate running and crouching every few frames")
	game.ledger.current="relay"; game.ledger.done.traversal=true; game.player.position=Vector3(0,.05,-74)
	await create_timer(.5).timeout
	var close_enemy=0
	for i in game.battlefield.soldiers.size():
		if game.battlefield.roles[i].side==1 and not game.battlefield.soldiers[i].dead and game.battlefield.soldiers[i].visible and game.battlefield.soldiers[i].position.distance_to(game.player.position)<25: close_enemy+=1
	check(close_enemy==0,"captured far bridgehead no longer retains background enemies beside allies")
	check(game.enemies.all(func(actor):return actor.dead),"captured main defenders stay defeated")
	game.save_checkpoint(); var saved=game.save_store.read()
	check(not saved.is_empty() and saved.assault.enemy_health.all(func(health):return health==0) and saved.assault.bridgehead_cleared,"checkpoint accepts defeated defenders and the captured bridgehead")
	check(game.continue_story(),"updated assault checkpoint can be resumed")
	await create_timer(.5).timeout
	check(game.enemies.all(func(actor):return actor.dead),"defeated defenders do not revive when the checkpoint is resumed")
	var old=saved.duplicate(true); old.assault={"passed":0,"fallen":0,"wounded":0}
	check(game.save_store.valid(old),"V3.1 assault checkpoint remains readable")
	var invalid=saved.duplicate(true); invalid.assault.enemy_health=[0,"bad"]
	check(not game.save_store.valid(invalid),"invalid enemy health cannot replace a checkpoint")
	game.battlefield.stop(); game.assault.stop()
	for node in game.find_children("*","AudioStreamPlayer",true,false): node.stop(); node.stream=null
	game.main_menu(); game.audio.clear_voice(); game.queue_free(); await process_frame; await create_timer(.2).timeout
	quit(1 if errors else 0)
