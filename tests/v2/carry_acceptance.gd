extends SceneTree
var game
var errors:=0
var loops:=0
var max_hand_error:=0.0
var max_rig_error:=0.0
var ticks:=0
func _initialize(): call_deferred("run")
func check(value:bool,label:String):
	print(("PASS " if value else "FAIL ")+label)
	if not value: errors+=1
func wait(seconds:float): await create_timer(seconds).timeout
func press(action:String,seconds:=.09):
	await process_frame
	Input.action_press(action); await wait(seconds); Input.action_release(action); await process_frame
func release_move():
	for action in ["move_left","move_right","move_forward","move_back"]: Input.action_release(action)
func until(test:Callable,seconds:float)->bool:
	var timer=0.0
	while not test.call() and timer<seconds and not game.failed:
		await wait(.05); timer+=.05
	return test.call()
func go(point:Vector3,timeout:=25.0)->bool:
	var timer=0.0
	while Vector2(game.player.position.x-point.x,game.player.position.z-point.z).length()>.14 and timer<timeout and not game.failed:
		release_move()
		var diff=(point-game.player.position).rotated(Vector3.UP,-game.view.rotation.y); diff.y=0
		if absf(diff.x)>.07: Input.action_press("move_right" if diff.x>0 else "move_left",minf(1,absf(diff.x)*2))
		if absf(diff.z)>.07: Input.action_press("move_back" if diff.z>0 else "move_forward",minf(1,absf(diff.z)*2))
		if game.repair.step=="carry":
			max_rig_error=maxf(max_rig_error,game.amu.position.distance_to(game.repair._helper_goal()))
			max_hand_error=maxf(max_hand_error,maxf(game.player.visual.hand_error,game.amu.visual.hand_error))
		await wait(.04); timer+=.04; ticks+=1
	release_move(); await wait(.2)
	var ok=Vector2(game.player.position.x-point.x,game.player.position.z-point.z).length()<.4 and not game.failed
	if not ok: print("MOVE FAILED at ",game.player.position," target ",point," step ",game.repair.step," blocked ",game.repair.board_blocked," helper ",game.amu.position," locked ",game.player.locked," unlock ",game.repair.unlock_delay," velocity ",game.player.velocity," movement ",game.player.movement_velocity," view ",game.view.rotation," frames ",Engine.get_physics_frames())
	return ok
func fixture(site:=0,prepared:=true):
	game.simple_repair=false
	var state={"version":3,"ledger":{"current":"repair","done":{"march":true,"recon":true,"escort":true}},"modules":{"repair":{"site":site,"step":"pickup" if prepared else "select","material":"good" if prepared else "","repaired":[site>0,false]}},"position":[2.3,.1,7.85] if site==0 else [-1.02,.1,-22.1],"elapsed":0,"retries":0,"choice":0}
	game._apply_snapshot(state)
	game.amu.position=Vector3(-2,0,10) if site==0 else Vector3(0,0,-19)
	game.view.camera_rotation=Vector3(-16,0,0)
	await wait(.2)
func prepare():
	var mod=game.repair
	check(await go(mod.material_position("good")),"walk to stock")
	await press("interact"); check(mod.step=="position","select actual board")
	await press("move_right",.65); await press("interact")
	await press("interact",1.6); check(mod.step=="check","prepare and tie board")
	await press("jump"); await wait(.25)
func pickup()->bool:
	var mod=game.repair
	var p=mod.pickup_position()
	if not await go(Vector3(p.x+1.0,0,game.player.position.z)): return false
	if not await go(Vector3(p.x+1.0,0,p.z)): return false
	if not await go(p): return false
	await press("interact")
	check(mod.step=="join" and not game.player.carrying and not game.player.locked,"request keeps board down and WASD free")
	var ok=await until(func(): return mod.step=="carry",20)
	check(ok and game.player.carrying and not game.player.locked,"helper arrives before synchronized lift")
	return ok
func place()->bool:
	var mod=game.repair; var site=mod.site
	if site==0 and game.player.position.z>0:
		if not await go(Vector3(0,0,3.2)): return false
	if not await go(game.world.get_v2_gap(site).approach): return false
	await press("interact")
	check(mod.step=="lowering","both lower at destination")
	await press("interact"); check(mod.step=="lowering","repeat E cannot skip lowering")
	if not await until(func(): return mod.step=="align",5): return false
	await press("interact"); await press("interact",1.6)
	check(mod.step=="place_check","placement still requires fixing and inspection")
	await press("jump"); await wait(.2)
	return game.world.v2_repair_is_enabled(site) and not game.player.locked and not game.player.carrying
func run():
	Engine.time_scale=3; Engine.max_fps=180; Engine.physics_ticks_per_second=120
	game=load("res://game/v2/main.tscn").instantiate(); root.add_child(game)
	game.save_store.path="user://carry_acceptance_only.json"
	await wait(.5)
	for action in InputMap.get_actions(): InputMap.action_erase_events(action)
	game.view.set_process_input(false)
	await fixture(0,false)
	await prepare()
	check(await pickup(),"first natural pickup")
	if errors: finish(); return
	game.repair.interact(); check(game.repair.step=="carry","placement outside target rejected")
	game.toggle_pause(); var before=game.player.position; await press("move_forward",.3)
	check(game.player.position.is_equal_approx(before),"pause freezes carry")
	game.toggle_pause(); check(not game.player.locked,"resume restores carry control")
	check(await place(),"full stock-to-placement input route")
	loops+=1
	var count=20
	if "--quick" in OS.get_cmdline_user_args(): count=2
	for i in range(1,count):
		await fixture(i%2,true)
		if not await pickup(): errors+=1; break
		if not await place(): check(false,"carry loop %d placement"%i); break
		loops+=1; print("COMPLETE CARRY ",loops,"/",count)
	check(loops==count,"20 complete carries (quick mode uses 2)")
	# Actual A* detour around an injected crate.
	await fixture()
	var obstacle=game.world.box(Vector3(1.5,1.0,1.0),Vector3(.5,.5,8.0),game.world.wood)
	await physics_frame
	check(await pickup(),"NPC detours around injected crate")
	await press("reload"); await wait(.6)
	check(game.repair.step=="pickup" and not game.player.locked and not game.player.carrying,"R releases rig and restores one board")
	# Unreachable target has a bounded timeout and no player control dependency.
	await fixture()
	var goal=game.repair._pickup_helper_goal()
	var blocker=game.world.box(Vector3(1.5,2.0,1.5),goal+Vector3(0,1,0),game.world.wood)
	await physics_frame
	check(await go(game.repair.pickup_position()),"walk to request point for unreachable helper")
	await press("interact"); await wait(.4)
	check(not game.player.locked and not game.player.carrying,"unreachable helper never locks player")
	await wait(19)
	check(game.repair.step=="pickup" and not game.player.locked,"unreachable route times out to safe retry")
	check(max_hand_error<.22,"carrying hand targets remain reachable")
	check(max_rig_error<.18,"rig grip separation remains bounded")
	print("METRICS loops=",loops," hand_error=",max_hand_error," rig_error=",max_rig_error," input_ticks=",ticks)
	finish()
func finish():
	release_move(); game.repair.stop(); game.audio.clear_voice()
	for node in game.find_children("*","AudioStreamPlayer",true,false): node.stop(); node.stream=null
	game.queue_free(); await process_frame; await wait(.2)
	print("CARRY ACCEPTANCE FAILURES ",errors); quit(1 if errors else 0)

