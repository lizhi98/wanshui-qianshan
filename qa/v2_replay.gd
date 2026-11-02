# Deterministic input replay: never assigns task state, player position,
# enemy health, repair flags or completion. Camera aim and UI clicks are aided.
extends Node
var game
var failures:=0
var route_b:=false
var folder:=""
var timings:Dictionary={}
var fps:Array[float]=[]
var finishing:=false
var showcase:=false
var chain_photos:=0
func wait(seconds:float): await get_tree().create_timer(seconds).timeout
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok: failures+=1
func press(action:String,seconds:=.10):
	await get_tree().process_frame
	Input.action_press(action); await wait(seconds); Input.action_release(action)
	await get_tree().process_frame
	if showcase: await wait(.75)
func release_move():
	for action in ["move_left","move_right","move_forward","move_back","sprint"]: Input.action_release(action)
func shot(label:String):
	if DisplayServer.get_name()=="headless": return
	await get_tree().process_frame
	await get_tree().process_frame
	RenderingServer.force_draw(false)
	check(get_tree().root.get_texture().get_image().save_png(folder.path_join(label+".png"))==OK,"viewport "+label)
	if showcase: await wait(3.0)
func go(point:Vector2,timeout:=35.0):
	var clock=0.0
	game.view.camera_rotation=Vector3(-12,0,0)
	await wait(.35)
	while clock<timeout and not game.failed:
		var difference=point-Vector2(game.player.position.x,game.player.position.z)
		if difference.length()<.18: break
		release_move()
		var local=Vector3(difference.x,0,difference.y).rotated(Vector3.UP,-game.view.rotation.y)
		if absf(local.x)>.10: Input.action_press("move_right" if local.x>0 else "move_left",minf(1,absf(local.x)*2))
		if absf(local.z)>.10: Input.action_press("move_back" if local.z>0 else "move_forward",minf(1,absf(local.z)*2))
		await wait(.04); clock+=.04
	release_move(); await wait(.20)
	check(Vector2(game.player.position.x,game.player.position.z).distance_to(point)<.48 and not game.failed,"walk "+str(point))
	print("AT ",game.player.position," chapter ",game.ledger.current," repair ",game.repair.step)
	if game.repair.active: print("CARRY helper ",game.amu.position," locked ",game.player.locked," blocked ",game.repair.board_blocked," ",game.repair.feedback)
func until(test:Callable,timeout:float,label:String):
	var clock=0.0
	while not test.call() and clock<timeout and not game.failed:
		await wait(.08); clock+=.08
	check(test.call() and not game.failed,label)
func aim(point:Vector3,camera:Camera3D):
	# The free look controls remain authoritative during normal play. In replay
	# only camera orientation is assisted; ray occlusion/range/dwell still apply.
	var delta=point-game.view.global_position
	game.view.camera_rotation=Vector3(rad_to_deg(atan2(delta.y,Vector2(delta.x,delta.z).length())),rad_to_deg(atan2(-delta.x,-delta.z)),0)
	camera.look_at(point)
func observe(key:String):
	var clock=0.0
	while not key in game.recon.found and clock<10:
		aim(game.recon.target_point(key),game.recon.observation_camera)
		await wait(.04); clock+=.04
	check(key in game.recon.found,"identify real target "+key)
func shoot(enemy):
	Input.action_press("aim"); await wait(.5)
	var clock=0.0
	while not enemy.dead and clock<35 and not game.failed:
		aim(enemy.position+Vector3(0,1.32,0),game.view.camera)
		if game.combat.ammo==0 and not game.combat.reloading: await press("reload")
		Input.action_press("shoot"); await wait(.035); clock+=.035
	Input.action_release("shoot"); Input.action_release("aim")
	check(enemy.dead,"real rifle rays subdue defender")
	print("RIFLE shots ",game.combat.shots," hits ",game.combat.hit_count," ammo ",game.combat.ammo," health ",game.player.health)
func adjust(module,field:String,positive:String,negative:String,tolerance:=.055,timeout:=4.0):
	var clock=0.0
	while absf(float(module.get(field)))>tolerance and clock<timeout:
		var value=float(module.get(field))
		Input.action_press(positive if value<0 else negative)
		await wait(.04)
		Input.action_release(positive); Input.action_release(negative); clock+=.04
	check(absf(float(module.get(field)))<=tolerance,"control alignment "+field)
func fix_rope(module,expected:String):
	Input.action_press("interact")
	await until(func(): return module.step==expected,4,"held E reaches "+expected)
	Input.action_release("interact"); await wait(.12)
func artillery_view(side:int):
	var view=game.view; var camera=view.camera
	var previous=camera.global_transform
	view.set_physics_process(false)
	var gun=game.battlefield.guns[side*2]
	camera.global_position=gun.root.global_position+Vector3(-4,2.7,4 if side==0 else -4)
	camera.look_at(gun.muzzle.global_position)
	var count=game.battlefield.shots_near if side==0 else game.battlefield.shots_far
	var timer=0.0
	while timer<7:
		var now=game.battlefield.shots_near if side==0 else game.battlefield.shots_far
		if now>count: break
		await wait(.05); timer+=.05
	await wait(.08); await shot("04b_friendly_artillery" if side==0 else "04c_enemy_artillery")
	camera.global_transform=previous; view.set_physics_process(true)
 
func watch_crossing():
	var clock=0.0
	while clock<10:
		for i in game.assault.rows.size():
			var row=game.assault.rows[i]
			if row.life in ["hit","fall"]:
				aim(game.assault.pool[i].position+Vector3.UP,game.view.camera)
				if row.life=="fall" and float(row.t)>.65: return
		await wait(.05); clock+=.05
func repair_site(index:int):
	var mod=game.repair
	var kind="cracked" if route_b and index==1 else "good"
	if index==0:
		await go(Vector2(2.1,6.8)); await go(Vector2(2.1,7.85)); await go(Vector2(mod.material_position("good").x,7.85))
	else:
		await go(Vector2(0,-7.2)); await go(Vector2(0,-11.9)); await go(Vector2(0,-20.5))
		await go(Vector2(mod.material_position(kind).x,mod.material_position(kind).z))
	await press("interact")
	if game.simple_repair:
		check(mod.step in ["preparing","pickup"],"quick preparation starts at real timber")
		await until(func(): return mod.step=="pickup",4,"automatic preparation releases controls")
	else:
		check(mod.step=="position","physical timber selected")
		await adjust(mod,"lateral","move_right","move_left"); await press("interact")
		if kind=="cracked":
			await fix_rope(mod,"position"); await adjust(mod,"depth","move_back","move_forward"); await press("interact")
		await fix_rope(mod,"check"); await press("jump"); await wait(.25)
	var grip=mod.pickup_position()
	await go(Vector2(grip.x+1,game.player.position.z))
	await go(Vector2(grip.x+1,grip.z)); await go(Vector2(grip.x,grip.z))
	await press("interact")
	await until(func(): return game.player.carrying,22,"helper reaches the far end before both lift")
	check(game.player.carrying,"two-person carry begins")
	await shot("0%d_carry"%(5+index))
	if index==0:
		await go(Vector2(0,3.2)); await go(Vector2(0,-7.55))
	else:
		await go(Vector2(.65,-25.5)); await go(Vector2(.65,-26.85))
	await until(func(): return game.amu.position.distance_to(mod._helper_goal())<2.4,14,"carrying helper actually reaches the far board end")
	print("HELPER ",game.amu.position," goal ",mod._helper_goal()," obstruction ",mod.helper_blocker)
	if index==0 and showcase:
		await wait(.65);await shot("06c_forward_cover_sacrifice");await wait(1.5)
		check(game.player.carrying,"builder keeps holding the timber through the forward sacrifice and response")
	if index==0 and "--assault-demo" in OS.get_cmdline_user_args():
		await press("aim",.25)
		check(mod.step=="parked" and not game.player.carrying,"right click parks the carried timber")
		game.view.camera_rotation=Vector3(-18,0,0)
		await watch_crossing(); await shot("06a_crossing_under_fire")
		await shoot(game.enemies[0]); await shoot(game.enemies[1])
		await shot("06b_covering_fire")
		var resume=mod.pickup_position()
		await go(Vector2(resume.x,resume.z)); await press("interact")
		await until(func(): return game.player.carrying,22,"resume the parked board after covering allies")
	await press("interact")
	if game.simple_repair:
		await until(func(): return game.world.v2_repair_is_enabled(index),6,"one placement action fixes and opens bridge")
		await shot("0%d_repaired"%(7+index)); return
	await until(func(): return mod.step=="align",5,"both lower before alignment")
	check(mod.step=="align","lower board at actual gap")
	if failures: return
	await adjust(mod,"lateral","move_right","move_left")
	if index==1: await adjust(mod,"depth","move_back","move_forward")
	await press("interact"); await fix_rope(mod,"place_check")
	await press("jump"); await wait(.2)
	check(game.world.v2_repair_is_enabled(index),"inspection opens matching mesh and collision site%d"%index)
	await shot("0%d_repaired"%(7+index))
func climb():
	game.view.camera_rotation=Vector3(-12,-25,0)
	Input.action_press("move_forward")
	var clock=0.0
	var photographed=false
	while game.player.climbing and not game.failed and clock<16:
		Input.action_release("move_left"); Input.action_release("move_right")
		if game.player.balance>.06: Input.action_press("move_left")
		elif game.player.balance<-.06: Input.action_press("move_right")
		if not photographed and clock>4:
			photographed=true; chain_photos+=1
			await shot("chain_wind_%d"%chain_photos)
		await wait(.06); clock+=.06
	release_move()
	check(not game.failed and not game.player.climbing,"W with corrective A/D reaches real support")
func run(existing):
	game=existing; route_b="--route-b" in OS.get_cmdline_user_args(); showcase="--showcase" in OS.get_cmdline_user_args()
	folder=ProjectSettings.globalize_path("user://verification/v2_route_"+("b" if route_b else "a"))
	DirAccess.make_dir_recursive_absolute(folder)
	print("EVIDENCE_PATH ",folder)
	await wait(.7)
	for action in InputMap.get_actions(): InputMap.action_erase_events(action)
	game.view.set_process_input(false)
	game.save_store.path="user://v2_replay_"+("b" if route_b else "a")+".json"
	await shot("01_title")
	for button in game.hud.buttons.get_children():
		if button.text=="开始新故事": button.pressed.emit(); break
	await wait(.4)
	await go(Vector2(0,44.2)); Input.action_press("move_forward"); await press("jump",.45); await wait(.45); release_move()
	check(game.march.jumped,"jump over physical fallen timber")
	await go(Vector2(-2.6,36.9)); await press("interact"); await go(Vector2(0,30.7))
	check(game.ledger.current=="recon","march leads to reconnaissance")
	if failures: await finish(); return
	timings.march=game.elapsed
	await go(Vector2(0,16)); await press("observe")
	for key in ["firepoint","gap","cover"]: await observe(key)
	await shot("02_recon"); await press("observe")
	await go(Vector2(3.7,11.3) if route_b else Vector2(-1.1,11)); await press("interact")
	check(game.ledger.current=="escort","physical sign chooses route "+("B" if route_b else "A"))
	if failures: await finish(); return
	timings.recon=game.elapsed
	if route_b:
		await go(Vector2(4.9,10.1)); await press("interact")
		check(game.escort.blocker_cleared,"E clears actual side-route obstacle")
		await go(Vector2(5.8,11.9)); await press("interact")
		await go(Vector2(4.85,11.8)); await go(Vector2(4.85,2.3)); await go(Vector2(1.1,3.3))
	else:
		await go(Vector2(1.1,8)); await go(Vector2(1.1,3.3))
	await shoot(game.enemies[0]); await shoot(game.enemies[1]); await shot("03_cover")
	await until(func(): return not game.escort.assembling,14,"ally walks to assembly cover")
	await press("signal")
	await until(func(): return game.escort.leg>=1,12,"first suppression advance walks to cover")
	await press("signal")
	await until(func(): return game.ledger.current=="repair",14,"second suppression advance delivers supplies")
	await shot("04_supply_delivered")
	if failures: await finish(); return
	if showcase and "--battlefield-demo" in OS.get_cmdline_user_args():
		await artillery_view(0); await artillery_view(1)
	timings.escort=game.elapsed
	await repair_site(0)
	if failures: await finish(); return
	await repair_site(1)
	if failures: await finish(); return
	if "--assault-demo" in OS.get_cmdline_user_args():
		await shoot(game.enemies[0]); await shoot(game.enemies[1])
	timings.repair=game.elapsed
	await go(Vector2(.65,-26.5)); await go(Vector2(.65,-31.2)); await go(Vector2(.5,-53.3)); await go(Vector2(1.43,-54.3))
	if "--assault-demo" in OS.get_cmdline_user_args():
		await shoot(game.enemies[0]); await shoot(game.enemies[1])
	if route_b:
		await press("interact"); Input.action_press("move_forward"); Input.action_press("move_right")
		var fall_clock=0.0
		while not game.failed and fall_clock<5:
			await wait(.04); fall_clock+=.04
		release_move(); check(game.failed,"sustained wrong balance input reaches ordinary failure menu")
		if game.failed: game.hud.buttons.get_child(0).pressed.emit()
		await wait(.3)
		check(not game.failed and not game.player.climbing and game.traversal.checkpoint==0,"ordinary retry restores the nearby chain entrance")
	await press("interact"); await climb(); await shot("09_middle_support")
	check(game.traversal.phase=="shelter","first chain segment reaches checkpoint")
	await press("interact"); await adjust(game.traversal,"alignment","move_right","move_left")
	await press("jump")
	await until(func(): return not game.amu.moving and game.amu.position.distance_to(Vector3(1.2,0,-58.2))<1.8,20,"ally walks along chain to hold support rope")
	# Tension decays while waiting for the helper, so tension again immediately before inspection.
	await press("interact",1.5); await press("jump")
	check(game.traversal.fixed,"cooperation actually fixes the loose support plank")
	if failures: await finish(); return
	await shot("10_chain_crisis"); await press("interact"); await climb()
	check(game.ledger.current=="relay","second chain segment opens final relay")
	if failures: await finish(); return
	timings.traversal=game.elapsed
	await go(Vector2(.8,-74.8)); Input.action_press("observe")
	var clock=0.0
	while not game.relay.observed and clock<8:
		aim(game.relay.observation_point(),game.view.camera); await wait(.04); clock+=.04
	Input.action_release("observe"); check(game.relay.observed,"F real ray identifies fallen relay crossbar")
	await go(Vector2(1.05,-75.4)); await press("signal")
	await until(func(): return game.relay._allies_ready(),20,"signal brings both allies to their grips")
	await press("interact"); await adjust(game.relay,"angle","move_right","move_left")
	await press("interact",3.0); await press("jump"); await shot("11_relay")
	check(game.relay.clear,"aligned pull and inspection open physical relay barrier")
	await until(func(): return game.relay.phase=="confirm",12,"both allies walk through the raised passage")
	await go(Vector2(0,-80.5))
	if "--assault-demo" in OS.get_cmdline_user_args():
		await shoot(game.enemies[0]); await shoot(game.enemies[1])
		await until(func(): return game.assault.passed>0,35,"covering and repaired paths let reinforcements actually reach the far bank")
		await shot("11b_reinforcements_across")
	await press("interact"); await press("jump")
	await until(func(): return game.ledger.current=="complete" and game.hud.overlay.visible,9,"taking the bridge leads directly to settlement")
	check(not game.modern.active and not game.hud.modern_panel.visible,"no reconstruction epilogue is shown to the player")
	check(game.vanguard.sacrifice_seen,"forward covering fighter sacrifices himself during construction")
	await shot("13_complete");timings.relay=game.elapsed
	await finish()
func _process(_delta):
	if game and is_instance_valid(game) and game.started and not game.paused: fps.append(Performance.get_monitor(Performance.TIME_FPS))
func finish():
	if finishing: return
	finishing=true; release_move()
	for action in ["interact","jump","shoot","aim","observe","signal"]: Input.action_release(action)
	var samples=fps.duplicate(); samples.sort()
	var report={"failures":failures,"route":"B" if route_b else "A","elapsed_seconds":game.elapsed,"chapter_elapsed":timings,"current":game.ledger.current,"binary":OS.get_executable_path(),"rendering":RenderingServer.get_current_rendering_method(),"viewport":str(get_tree().root.size),"movie_maker":not Engine.get_write_movie_path().is_empty(),"input_replay":true,"assault":game.assault.snapshot(),"fps_samples":samples.size(),"fps_median":samples[samples.size()/2] if not samples.is_empty() else 0}
	report["battlefield"]=game.battlefield.diagnostics()
	report["vanguard"]=game.vanguard.snapshot();report["vanguard"]["shots"]=game.vanguard.shots;report["vanguard"]["sacrifice_elapsed"]=game.vanguard.sacrifice_elapsed
	var file=FileAccess.open(folder.path_join("report.json"),FileAccess.WRITE); file.store_string(JSON.stringify(report,"\t")); file.close()
	print("V2 REPLAY failures=",failures," route=",report.route," elapsed=",game.elapsed," current=",game.ledger.current)
	print("CHAPTER TIMINGS ",timings)
	for node in game.find_children("*","AudioStreamPlayer",true,false):
		node.stop(); node.stream=null
	game.queue_free(); await get_tree().process_frame; await wait(.4)
	# Fixed-FPS headless can outrun the asynchronous audio mixer at shutdown.
	# This is cleanup only, after the playthrough report and gameplay timer.
	if DisplayServer.get_name()=="headless": OS.delay_msec(350)
	get_tree().quit(1 if failures else 0)
