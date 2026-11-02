# Rendered input replay. No phase changes, teleports or direct enemy damage.
# --timed-auto measures default reading speed; ordinary replay clicks through dialogue.
extends Node
var game
var failures := 0
var timed := false
var demo := false
var timings: Dictionary={}
var folder="res://test_evidence/remaster/playthrough/"
var fps: Array[float]=[]
var root: Window:
	get: return get_tree().root
func create_timer(seconds: float): return get_tree().create_timer(seconds)
func quit(code := 0): get_tree().quit(code)
func check(ok: bool,message: String):
	print(("PASS: " if ok else "FAIL: ")+message)
	if not ok: failures+=1
func shot(name: String):
	# A minimized window may skip frame_post_draw indefinitely. Explicitly draw
	# the viewport so capturing evidence cannot stall the running playthrough.
	RenderingServer.force_draw(false)
	var result=root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+name+".png"))
	check(result==OK,"saved viewport evidence: "+name)
	print("SHOT ",name," @ ",snappedf(game.elapsed,.1))
func press(action: String,duration := .12):
	await get_tree().process_frame
	Input.action_press(action)
	await create_timer(duration).timeout
	Input.action_release(action)
func go_to(point: Vector2,timeout := 32.0):
	var clock=0.0
	game.view.camera_rotation=Vector3(-12,0,0)
	await create_timer(.45).timeout
	while clock<timeout and not game.failed:
		var diff=point-Vector2(game.player.position.x,game.player.position.z)
		if diff.length()<.22: break
		# Keyboard input is camera-relative. Resolve the world goal through the
		# current yaw instead of assuming a fixed camera during transitions.
		var local_diff=Vector3(diff.x,0,diff.y).rotated(Vector3.UP,-game.view.rotation.y)
		for action in ["move_left","move_right","move_forward","move_back"]: Input.action_release(action)
		if absf(local_diff.x)>.15: Input.action_press("move_right" if local_diff.x>0 else "move_left")
		if absf(local_diff.z)>.15: Input.action_press("move_back" if local_diff.z>0 else "move_forward")
		await create_timer(.04).timeout
		clock+=.04
	for action in ["move_left","move_right","move_forward","move_back"]: Input.action_release(action)
	await create_timer(.3).timeout
	check(Vector2(game.player.position.x,game.player.position.z).distance_to(point)<.55,"walk to "+str(point))
	print("AT ",game.player.position," stage ",game.stage)
func talk(branch := 0):
	var clock=0.0
	var key=game.dialogue.key
	var held_line=-1
	game.dialogue.automatic=timed
	game.hud.set_auto(timed)
	while game.dialogue.active and clock<300:
		if not game.dialogue.loading and game.dialogue.line:
			if demo and game.dialogue.line_count!=held_line and game.dialogue.line_count%3==1:
				held_line=game.dialogue.line_count
				game.dialogue.fully_revealed=true
				await create_timer(2.6).timeout
			if game.dialogue.line.responses.size()>0 and game.dialogue.visible_chars>=game.dialogue.line.text.length():
				game.hud.choice_box.get_child(branch).pressed.emit()
			elif not timed:
				game.dialogue.advance()
		await create_timer(.12 if not timed else .3).timeout
		clock+=.12 if not timed else .3
	check(not game.dialogue.active,"dialogue completes: "+key)
	await create_timer(1).timeout
func event_done():
	var clock=0.0
	while not game.event.is_empty() and clock<12:
		await create_timer(.2).timeout
		clock+=.2
func shoot_enemy(enemy):
	Input.action_press("aim")
	await create_timer(.6).timeout
	var clock=0.0
	while not enemy.dead and clock<35 and not game.failed:
		var direction=enemy.position-game.player.position
		game.view.camera_rotation.y=rad_to_deg(atan2(-direction.x,-direction.z))
		game.view.camera.look_at(enemy.position+Vector3(0,1.36,0))
		if game.combat.ammo==0 and not game.combat.reloading: await press("reload")
		Input.action_press("shoot")
		await get_tree().process_frame
		clock+=game.get_process_delta_time()
	Input.action_release("shoot")
	Input.action_release("aim")
	Input.action_release("reload")
	check(enemy.dead,"defender subdued with real rifle rays")
func cleanup():
	print("REMASTER REPLAY: failures ",failures," elapsed ",snappedf(game.elapsed,.1)," shots ",game.combat.shots," hits ",game.combat.hit_count)
	print("CHAPTER TIMINGS ",timings)
	var sorted=fps.duplicate()
	sorted.sort()
	var report={"failures":failures,"elapsed_seconds":game.elapsed,"shots":game.combat.shots,"hits":game.combat.hit_count,"timed_auto":timed,"chapter_elapsed":timings,"shots_used":game.director.shots_used.keys(),"rendering":RenderingServer.get_current_rendering_method(),"fps_samples":fps.size(),"fps_p10":sorted[int(sorted.size()*.1)] if not sorted.is_empty() else 0,"fps_median":sorted[int(sorted.size()*.5)] if not sorted.is_empty() else 0}
	report["movie_maker"]=not Engine.get_write_movie_path().is_empty()
	report["viewport"]=str(root.size)
	report["binary"]=OS.get_executable_path().get_file()
	var file=FileAccess.open(folder+"report"+("_timed" if timed else "")+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	game.queue_free()
	await get_tree().process_frame
	await create_timer(.3).timeout
	quit(1 if failures else 0)
func _process(_delta):
	if game and is_instance_valid(game) and game.started and not game.paused: fps.append(Performance.get_monitor(Performance.TIME_FPS))
func run(existing_game=null):
	timed="--timed-auto" in OS.get_cmdline_user_args()
	demo="--demo" in OS.get_cmdline_user_args()
	if timed: folder="res://test_evidence/remaster/timed_playthrough/"
	if not OS.has_feature("editor") or "--release-evidence" in OS.get_cmdline_user_args(): folder="user://verification/"+("timed/" if timed else "replay/")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	print("EVIDENCE_PATH ",ProjectSettings.globalize_path(folder))
	if existing_game:
		game=existing_game
	else:
		game=load("res://game/remaster/main.tscn").instantiate()
		root.add_child(game)
		get_tree().current_scene=game
	await create_timer(1).timeout
	# Keep the deterministic replay isolated from keys typed in other desktop
	# windows. Programmatic Input.action_press/release still uses the real game.
	for action in InputMap.get_actions(): InputMap.action_erase_events(action)
	game.view.set_process_input(false)
	game.dialogue.set_process_unhandled_input(false)
	game.hud.root_control.propagate_call("set_mouse_filter",[Control.MOUSE_FILTER_IGNORE])
	game.save_store.path="user://remaster_replay_checkpoint.json"
	await shot("01_title")
	game.begin()
	await create_timer(3).timeout
	await shot("02_opening_gorge")
	await event_done()
	await go_to(Vector2(0,28.9))
	await press("interact")
	await create_timer(1).timeout
	if not timed: game.dialogue.advance()
	await shot("03_prologue")
	await talk(1)
	check(game.stage=="approach","prologue opens the mountain path")
	if failures: await cleanup(); return
	await go_to(Vector2(0,16))
	await press("interact")
	await create_timer(2).timeout
	await shot("04_bridge_reveal")
	await event_done()
	await talk()
	timings["prologue"]=game.elapsed
	await go_to(Vector2(0,5))
	await go_to(Vector2(2.5,3.4))
	await press("interact")
	await talk()
	check(game.stage=="signal","selected timber preparation opens the briefing")
	await go_to(Vector2(-.2,5))
	await press("interact")
	await talk()
	check(game.stage=="combat","briefing enters actual combat")
	timings["chapter_1"]=game.elapsed
	if failures: await cleanup(); return
	await go_to(Vector2(0,1.2))
	await shoot_enemy(game.enemies[0])
	await shot("05_combat")
	await shoot_enemy(game.enemies[1])
	await create_timer(7).timeout
	await talk()
	check(game.stage=="brace","combat opens a different cooperative task")
	if failures: await cleanup(); return
	await go_to(Vector2(0,4.5))
	await go_to(Vector2(2.8,4.2))
	await press("interact")
	await create_timer(2).timeout
	await shot("06_brace")
	await create_timer(2.4).timeout
	check(game.tasks.get("brace",false),"physical bracing and NPC tying are complete")
	await go_to(Vector2(1.2,3.2))
	await press("interact")
	await create_timer(.65).timeout
	await shot("07_pickup")
	await create_timer(1.0).timeout
	check(game.player.carrying,"E picks up a real carried board")
	await go_to(Vector2(0,1.4))
	await go_to(Vector2(0,-7.8))
	await create_timer(2).timeout
	await shot("08_carry")
	await press("interact")
	await create_timer(1).timeout
	await shot("09_cooperative_placement")
	await create_timer(1.3).timeout
	await talk()
	check(game.world.repair_enabled,"placed timber changes actual bridge collision")
	await go_to(Vector2(0,-12))
	check(not game.failed,"player crosses the physical repaired gap")
	await shot("10_repaired_gap")
	await go_to(Vector2(0,-53.8))
	await go_to(Vector2(1.43,-54.35))
	await press("interact")
	check(game.player.climbing,"E starts the longer chain crossing")
	Input.action_press("move_forward")
	var clock=0.0
	var chain_captured=false
	while game.player.climbing and clock<18 and not game.failed:
		Input.action_release("move_left")
		Input.action_release("move_right")
		if game.player.balance>.08: Input.action_press("move_left")
		elif game.player.balance<-.08: Input.action_press("move_right")
		if clock>6.7 and not chain_captured:
			chain_captured=true
			game.view.camera_rotation=Vector3(-27,38,0)
			await shot("11_chain_balance")
		await create_timer(.08).timeout
		clock+=.08
	for action in ["move_forward","move_left","move_right"]: Input.action_release(action)
	check(game.crossed and not game.failed,"W and corrective A/D traverse the real chain path")
	if failures: await cleanup(); return
	await go_to(Vector2(0,-77))
	await create_timer(6).timeout
	check(game.stage=="reunion","allies naturally follow and reach the far bank")
	timings["chapter_2"]=game.elapsed
	await press("interact")
	await create_timer(1).timeout
	if not timed: game.dialogue.advance()
	await shot("12_reunion")
	await talk()
	await create_timer(3.5).timeout
	await shot("13_ending_pullback")
	await event_done()
	check(game.modern.active,"ending flows into interactive digital observation")
	timings["chapter_3"]=game.elapsed
	if failures: await cleanup(); return
	for i in 3:
		game.modern.select_point(i)
		var wait_time=0.0
		while game.modern.travelling and wait_time<8:
			await create_timer(.1).timeout
			wait_time+=.1
		await press("interact")
		await create_timer(.4).timeout
		check(i in game.modern.scanned,"nearby E collects observation point "+str(i+1))
		await shot("14_scan_%d"%(i+1))
	game.modern.orbit()
	Input.action_press("move_right")
	await create_timer(2).timeout
	Input.action_release("move_right")
	game.modern.compare()
	await create_timer(.8).timeout
	await shot("15_structure_compare")
	game.modern.compare()
	game.hud.finish_button.pressed.emit()
	await create_timer(.5).timeout
	check(game.stage=="complete" and game.hud.overlay.visible,"complete reconstruction opens real settlement")
	await shot("16_completion")
	timings["epilogue"]=game.elapsed
	await cleanup()
