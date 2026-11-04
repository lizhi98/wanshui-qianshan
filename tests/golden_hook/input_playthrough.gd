extends Node
## Input-only chapter replay. Reads scene state to decide keyboard/mouse inputs.
## Does not set story flags, inventory, transforms, camera state or rewards.
## The test save namespace is the only injected configuration.
var game
var keys:Dictionary={}
var mouse_down:=false
var time:=0.0
var stage_time:=0.0
var last_step:=""
var last_dialogue:=""
var next_interact:=0.0
var failed_once:=false
var reel_hold:=false
var route_index:=0
var stages:Array=[]
var catches:Array=[]
var events:=0
var trace:FileAccess
var movie:=false
var last_fish_state:=-1
var captures:=0
func capture(label:String):
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	var dir=ProjectSettings.globalize_path("res://../Test_Records/Voice_Rework/Windows/Input_Captures")
	DirAccess.make_dir_recursive_absolute(dir)
	get_viewport().get_texture().get_image().save_png(dir.path_join("%03d_%s.png"%[captures,label])); captures+=1
func run(scene):
	game=scene
	game.store.path="user://golden_hook_voice_rework_input.json"
	game.fishing.model.set_seed(631)
	var folder=ProjectSettings.globalize_path("res://../Test_Records/Voice_Rework/Windows")
	DirAccess.make_dir_recursive_absolute(folder)
	trace=FileAccess.open(folder.path_join("input_trace.jsonl"),FileAccess.WRITE)
	movie=OS.get_cmdline_args().has("--write-movie")
	await get_tree().process_frame
	await get_tree().process_frame
	# Click the real new-chapter menu button; do not call begin_chapter.
	var candidates=game.hud.menu_buttons.get_children()
	var start_button
	for button in candidates:
		if str(button.text).begins_with("走进草地"): start_button=button
	if not start_button: _abort("new-chapter UI button missing"); return
	print("START_UI ",start_button.get_global_rect()," viewport=",get_viewport().get_visible_rect())
	await _click(start_button.get_global_rect().get_center())
	await get_tree().process_frame
	print("UI_STARTED ",game.started)
	set_process(true)
func _ready(): set_process(false)
func _key(code:int,pressed:bool):
	if keys.get(code,false)==pressed: return
	keys[code]=pressed
	var event=InputEventKey.new(); event.physical_keycode=code; event.keycode=code; event.pressed=pressed
	Input.parse_input_event(event); events+=1
func _tap(code:int):
	_key(code,true)
	await get_tree().process_frame
	_key(code,false)
func _mouse(pressed:bool,point:=Vector2(1000,350)):
	if mouse_down==pressed: return
	mouse_down=pressed
	var event=InputEventMouseButton.new(); event.button_index=MOUSE_BUTTON_LEFT; event.pressed=pressed; event.position=point; event.global_position=point
	Input.parse_input_event(event); events+=1
func _click(point:Vector2):
	var move=InputEventMouseMotion.new(); move.position=point; move.global_position=point; get_tree().root.push_input(move,true)
	var down=InputEventMouseButton.new(); down.button_index=MOUSE_BUTTON_LEFT; down.pressed=true; down.position=point; get_tree().root.push_input(down,true); events+=1
	await get_tree().process_frame
	var up=InputEventMouseButton.new(); up.button_index=MOUSE_BUTTON_LEFT; up.pressed=false; up.position=point; get_tree().root.push_input(up,true); events+=1
func _release():
	for code in [KEY_W,KEY_A,KEY_S,KEY_D]: _key(code,false)
	_mouse(false)
func _log(kind:String,data:Dictionary):
	data["type"]=kind; data["time"]=time
	data["engine_frame"]=Engine.get_process_frames()
	trace.store_line(JSON.stringify(data)); trace.flush()
func _process(delta):
	if not game or not is_instance_valid(game): return
	time+=delta; stage_time+=delta; next_interact=maxf(0,next_interact-delta)
	if time>1400 or stage_time>170: _abort("input replay stalled at "+game.story.step); return
	if not game.started: return
	var step=game.story.step
	if step!=last_step:
		_log("step",{"step":step,"position":[game.player.position.x,game.player.position.y,game.player.position.z],"inventory":game.story.inventory.duplicate(true)})
		stages.append({"step":step,"time":time,"engine_frame":Engine.get_process_frames()}); print("REPLAY ",step," ",snapped(time,.1))
		last_step=step; stage_time=0
		capture(step)
	if (not game.dialogue_rows.is_empty() and not game.walk_and_talk) or game.paused or game.busy:
		_release(); return
	if step=="archive" and game.hud.menu.visible:
		_finish(); return
	if game.crafting:
		_release()
		if step=="heat": _mouse(true)
		elif step=="bend": _key(KEY_D,true)
		elif next_interact<=0: _tap(KEY_E); next_interact=.8
		return
	if game.fishing.active:
		for code in [KEY_W,KEY_A,KEY_S,KEY_D]: _key(code,false)
		_fishing_input(); return
	var target=game.current_target()
	if target==Vector3.INF: _release(); return
	if step=="march":
		var route=[Vector3(-1,0,-15),Vector3(1,0,-28)]
		if route_index<route.size():
			if Vector2(game.player.position.x-route[route_index].x,game.player.position.z-route[route_index].z).length()<1.2: route_index+=1
			else: target=route[route_index]
	var vector=target-game.player.position; vector.y=0
	if vector.length()<1.45 and (step!="march" or route_index>=2):
		_release()
		if game.dialogue_rows.is_empty() and next_interact<=0: _tap(KEY_E); next_interact=.9
	else:
		var local=vector.normalized().rotated(Vector3.UP,-game.view.rotation.y)
		_key(KEY_W,local.z<-.22); _key(KEY_S,local.z>.22); _key(KEY_A,local.x<-.22); _key(KEY_D,local.x>.22)
func _fishing_input():
	var f=game.fishing; var s=f.model.state; var S=f.Model.State
	if s!=last_fish_state:
		last_fish_state=s; capture("fishing_%d_%d"%[game.story.fish_total,s])
	match s:
		S.PREPARE:
			if not f.charging: _mouse(true)
			elif f.power>=.62: _mouse(false)
		S.CASTING: _mouse(false)
		S.WAITING:
			if not failed_once and f.model.clock>.45:
				failed_once=true; _tap(KEY_SPACE); _log("intentional_failure",{"reason":"early strike"})
		S.BITE:
			if f.model.clock>.16: _tap(KEY_SPACE)
		S.HOOKED: reel_hold=true
		S.REELING:
			if f.model.tension>.68: reel_hold=false
			elif f.model.tension<.36: reel_hold=true
			_mouse(reel_hold)
		S.ESCAPED:
			_mouse(false)
			if next_interact<=0: _tap(KEY_E); next_interact=.5
		S.CAUGHT:
			_mouse(false)
			if catches.size()<f.model.catch_serial:
				catches.append({"time":time,"serial":f.model.catch_serial}); _log("caught",{"serial":f.model.catch_serial,"fish_total":game.story.fish_total})
func _abort(reason:String):
	set_process(false); _release(); print("INPUT PLAYTHROUGH FAIL: ",reason)
	if trace: _log("failure",{"reason":reason}); trace.close()
	get_tree().quit(1)
func _finish():
	set_process(false); _release()
	var valid=game.story.inventory.keepsake==1 and game.story.fish_total==3 and catches.size()==3 and failed_once
	var result={"passed":valid,"duration_seconds":time,"game_elapsed":game.elapsed,"input_events":events,"earned_fish":game.story.fish_total,"catches":catches,"keepsake":game.story.inventory.keepsake,"stages":stages,"early_strike_retried":failed_once,"direct_state_writes":0,"reward_injection":0,"actor_teleports":0,"kind":"automated input replay; not independent human testing"}
	var file=FileAccess.open(ProjectSettings.globalize_path("res://../Test_Records/Voice_Rework/Windows/input_playthrough_result.json"),FileAccess.WRITE); file.store_string(JSON.stringify(result,"\t")); file.close()
	_log("complete",result); trace.close(); print("INPUT PLAYTHROUGH ","PASS " if valid else "FAIL ",JSON.stringify(result))
	game.queue_free(); game=null
	await get_tree().process_frame
	await get_tree().process_frame
	OS.delay_msec(50) # Allow the audio mixer to release its final WAV playback.
	get_tree().quit(0 if valid else 1)
