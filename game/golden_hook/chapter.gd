extends Node3D
const Story=preload("res://game/golden_hook/chapter_state.gd")
const Store=preload("res://game/golden_hook/save_store.gd")
const Dialogue=preload("res://game/golden_hook/dialogue_data.gd")
const P=preload("res://game/golden_hook/props.gd")
const InputKeys=preload("res://game/golden_hook/input_keys.gd")
enum Phase { INTRO, COMBAT, PICKUP, COOPERATE, CROSSING, ENDING }
@export var standalone:=false
var phase:=Phase.INTRO
var story=Story.new()
var store=Store.new()
var player
var view
var world
var hud
var audio
var fishing
var elder
var shi
var qing
# The V4.1.3 shared camera uses these roster slots for occlusion. They refer
# to this chapter's actual actors; no earlier story characters are spawned.
var amu:
	get: return shi
var zhou:
	get: return elder
var marchers:
	get: return [qing] if is_instance_valid(qing) else []
var actors:Array=[]
var started:=false
var paused:=false
var failed:=false
var busy:=false
var elapsed:=0.0
var safe_position:=Vector3(-8,0,16)
var checkpoint_clock:=0.0
var reaction_window:=1.15
var demo_seen:=false
var crafting:=false:
	set(value):
		crafting=value
		# The craft close-up belongs to the elder; exclude the observer's body.
		# Every exit/restart/load path already resets crafting, restoring visibility.
		if is_instance_valid(player) and is_instance_valid(player.visual):
			player.visual.visible=not value
var heat_progress:=0.0
var bend_progress:=0.0
var dialogue_rows:Array=[]
var dialogue_index:=-1
var dialogue_left:=0.0
var dialogue_age:=0.0
var dialogue_group:=""
var dialogue_finish:Callable
var focus_point:=Vector3.ZERO
var focus_distance:=3.8
var pause_lock:=false
var demo_rod:Node3D
var demo_float:Node3D
var demo_line:Node3D
var session_epoch:=0
var demo_clock:=0.0
var demo_active:=false
var voice_actor
var performance_mode:=false
var secret_observed:=false
var escort_clock:=0.0
var walk_and_talk:=false
var dialogue_uses_camera:=false
var collapse_seen:=false
func _ready():
	if "--v11-manual-sandbox" in OS.get_cmdline_user_args():store.path="user://golden_hook_v11_manual_sandbox.json"
	DisplayServer.window_set_title("万水千山 · 金色的鱼钩 · 草地上的守护")
	_inputs()
	world=load("res://game/golden_hook/wetland_world.gd").new(); world.mission=self; add_child(world)
	player=load("res://objects/player.tscn").instantiate(); player.name="Xiaoliang"
	player.set_script(load("res://game/golden_hook/player.gd")); player.mission=self; player.visual_type=load("res://game/golden_hook/character.gd")
	player.position=world.at_ground(Vector3(-8,0,16)); player.rotation.y=PI; player.rotation_direction=PI; add_child(player)
	player.died.connect(recover_from_swamp)
	view=Node3D.new(); view.name="View"; view.set_script(load("res://game/camera.gd")); view.mission=self; view.target=player; view.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	var camera=Camera3D.new(); camera.name="Camera"; camera.current=true; camera.far=420; view.add_child(camera); add_child(view); player.view=view
	var fill=OmniLight3D.new(); camera.add_child(fill); fill.light_color=Color("c6d3ce"); fill.light_energy=.18; fill.omni_range=4.5
	elder=_actor("Zhou_Elder",world.points.elder); shi=_actor("Amu_Shi",world.points.comrade_a); qing=_actor("XiaoQing",world.points.comrade_b); actors=[elder,shi,qing]
	elder.scale=Vector3.ONE*1.035; qing.scale=Vector3.ONE*.97
	for actor in [shi,qing]: actor.visual.posture="seated"
	elder.visual.posture="kneel"
	hud=load("res://game/golden_hook/hud.gd").new(); hud.mission=self; add_child(hud)
	audio=load("res://game/golden_hook/audio_director.gd").new(); audio.mission=self; add_child(audio)
	fishing=load("res://game/golden_hook/fishing_view.gd").new(); fishing.mission=self; add_child(fishing)
	_load_preferences()
	story.changed.connect(_story_changed); world.update_story(story)
	if standalone or "--chapter3" in OS.get_cmdline_user_args(): call_deferred("begin_chapter")
	else: return_to_menu()
	if "--golden-smoke" in OS.get_cmdline_user_args(): call_deferred("export_smoke")
	if "--golden-replay" in OS.get_cmdline_user_args(): call_deferred("start_replay")
	if "--v11-action-lab" in OS.get_cmdline_user_args():call_deferred("start_action_lab")
func _inputs():
	for entry in [["sprint",KEY_SHIFT],["interact",KEY_E],["pause",KEY_ESCAPE],["bend_hook",KEY_D]]:
		if not InputMap.has_action(entry[0]):
			InputMap.add_action(entry[0]); var e=InputEventKey.new(); e.physical_keycode=entry[1]; InputMap.action_add_event(entry[0],e)
	for entry in [["shoot",MOUSE_BUTTON_LEFT],["aim",MOUSE_BUTTON_RIGHT]]:
		if not InputMap.has_action(entry[0]):
			InputMap.add_action(entry[0]); var e=InputEventMouseButton.new(); e.button_index=entry[1]; InputMap.action_add_event(entry[0],e)
	InputKeys.install_logical_fallbacks()
func _actor(actor_name:String,point:Vector3):
	var n=load("res://game/golden_hook/npc.gd").new(); n.name=actor_name; n.mission=self; n.visual_type=load("res://game/golden_hook/character.gd"); n.position=point; add_child(n)
	n.rotation.y=PI*.15
	return n
func begin_chapter(skip_intro:=false):
	session_epoch+=1
	_clear_demo()
	_cancel_dialogue(); fishing.exit(); _protect_unique_hook(); crafting=false; busy=false; started=true; paused=false; failed=false; elapsed=0; demo_seen=false; demo_active=false
	story=Story.new(); story.changed.connect(_story_changed); secret_observed=false;collapse_seen=false
	player.restore(world.at_ground(Vector3(-8,0,16))+Vector3(0,.12,0)); player.visual.posture="weak"; safe_position=player.position
	for pair in [[elder,"elder"],[shi,"comrade_a"],[qing,"comrade_b"]]:
		pair[0].moving=false; pair[0].position=world.points[pair[1]]; pair[0].visual.reset_pose()
	elder.visual.posture="kneel"
	for n in [shi,qing]: n.visual.posture="seated"
	world.set_final_weather(false); world.update_story(story); hud.menu.hide(); hud.hide_dialogue(); audio.set_mood("shortage")
	_reset_camera(); Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	if not skip_intro: play_dialogue("intro",func(): hud.map_panel.hide())
	save_checkpoint()
func return_to_menu():
	session_epoch+=1; demo_active=false
	_clear_demo()
	if started: save_checkpoint()
	_cancel_dialogue(); fishing.exit(); _protect_unique_hook(); crafting=false; busy=false; started=false; paused=false; player.locked=true; player.scripted_destination=Vector3.INF
	for n in actors: n.moving=false
	_scenic_camera(); hud.map_panel.hide(); hud.fishing_panel.hide(); hud.hide_dialogue(); audio.set_mood("shortage"); audio.set_paused(false)
	var actions=[]
	var saved = store.read() if store.exists() else {}
	var completed = saved.get("chapter", {}).get("step", "") == "archive"
	if not saved.is_empty() and not completed:
		actions.append(["继续上次进度", continue_chapter])
	actions.append(["开始 · 金色的鱼钩", begin_chapter])
	if completed:
		actions.append(["回看本章结尾", continue_chapter])
	actions.append_array([["操作与画质", settings_menu], ["章节选择", chapter_menu]])
	hud.show_menu("金色的鱼钩", "1935年秋，草地深处。\n跟随老班长寻找食物，把一碗热汤送到战友手中。\n\nWASD 移动 · 鼠标转向 · E 交互", actions)
func chapter_menu():
	if started: save_checkpoint()
	get_tree().change_scene_to_file("res://game/chapters/main.tscn")
func _back_menu():
	if started and paused: _show_pause_menu()
	else: return_to_menu()
func settings_menu():
	hud.show_menu("操作与画质","制钩　左键加热，按住 D 弯钩，E 拴线。\n钓鱼　左键蓄力后松开抛竿，浮标下沉时按空格，再按住左键收线。\nQ 收竿 · E 重试 · Esc 暂停",[["咬钩反应窗口：%.2f秒"%reaction_window,func(): reaction_window=1.2 if reaction_window<1.2 else .9; _save_preferences(); settings_menu()],["音乐：%d%%"%int(audio.music_volume*100),func(): audio.music_volume=_next_volume(audio.music_volume); _save_preferences(); settings_menu()],["音效：%d%%"%int(audio.effects_volume*100),func(): audio.effects_volume=_next_volume(audio.effects_volume); _save_preferences(); settings_menu()],["配音：%d%%"%int(audio.voice_volume*100),func(): audio.voice_volume=_next_volume(audio.voice_volume); _save_preferences(); settings_menu()],["画质："+("性能" if performance_mode else "标准")+"",func(): set_performance_mode(not performance_mode); _save_preferences(); settings_menu()],["全屏 / 窗口",func(): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)],["返回",_back_menu]], false)
func _next_volume(value:float)->float: return .0 if value>.85 else (.5 if value<.1 else (1.0 if value>.6 else .85))
func set_performance_mode(low:bool):
	performance_mode=low; world.set_performance_mode(low); get_viewport().scaling_3d_scale=.75 if low else 1.0
	get_viewport().msaa_3d=Viewport.MSAA_DISABLED if low else Viewport.MSAA_4X
func _load_preferences():
	var cfg=ConfigFile.new()
	if cfg.load("user://golden_hook_preferences.cfg")==OK:
		audio.master=clampf(float(cfg.get_value("audio","volume",.85)),.1,1)
		for pair in [["music", "music_volume",.85],["effects","effects_volume",.85],["voice","voice_volume",1.0]]:audio.set(pair[1],clampf(float(cfg.get_value("audio",pair[0],pair[2])),0,1))
		reaction_window=clampf(float(cfg.get_value("play","reaction",1.15)),.9,1.2)
		set_performance_mode(bool(cfg.get_value("graphics","performance",false)))
func _save_preferences():
	var cfg=ConfigFile.new(); cfg.set_value("audio","volume",audio.master); cfg.set_value("play","reaction",reaction_window); cfg.set_value("graphics","performance",performance_mode); 
	for pair in [["music",audio.music_volume],["effects",audio.effects_volume],["voice",audio.voice_volume]]:cfg.set_value("audio",pair[0],pair[1])
	cfg.save("user://golden_hook_preferences.cfg")
func archive_menu():
	hud.show_menu("金色的鱼钩", "第三关完成。\n\n小梁把鱼钩包好，和战友们继续向前。\n那只盛过鱼汤的碗，那位守着他们走过草地的老班长，大家都记得。\n\n文学主题取自杨旭《金色的鱼钩》。", [["章节选择", chapter_menu], ["返回标题", return_to_menu]])
func _reset_camera():
	view.cinematic=false; view.camera_rotation=Vector3(-16,0,0); view.rotation_degrees=Vector3(-16,0,0)
	view.position=player.position+Vector3(0,1.35,0); view.camera.position=Vector3(.38,.12,4.6); view.camera.rotation=Vector3.ZERO; view.camera.fov=66
func _scenic_camera():
	view.cinematic=true; view.camera.global_position=Vector3(-24,12,30); view.camera.look_at(Vector3(4,0,-10)); view.camera.fov=57
func toggle_pause():
	if not started or (story.step == "archive" and hud.menu.visible): return
	if not paused:
		pause_lock=player.locked; paused=true; player.locked=true; audio.set_paused(true); save_checkpoint()
		_show_pause_menu()
	else:
		paused=false; player.locked=pause_lock; hud.menu.hide(); audio.set_paused(false); Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
func _show_pause_menu():
	hud.show_menu("金色的鱼钩 · 暂停", "已保存当前章节进度。", [["继续", toggle_pause], ["从检查点重试", continue_chapter], ["操作与画质", settings_menu], ["返回标题", return_to_menu]])
func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo and InputKeys.matches(event,KEY_ESCAPE):
		if started: toggle_pause(); get_viewport().set_input_as_handled()
		return
	if not started or paused: return
	if fishing.active:
		fishing.input(event); return
	if event is InputEventKey and event.pressed and not event.echo:
		if not dialogue_rows.is_empty() and (InputKeys.matches(event,KEY_E) or InputKeys.matches(event,KEY_SPACE)):
			if dialogue_age>.65: _next_line()
			get_viewport().set_input_as_handled(); return
		if InputKeys.matches(event,KEY_E) and not busy:
			interact(); get_viewport().set_input_as_handled()
func _process(delta):
	if not started or paused: return
	elapsed+=delta
	for actor in [player]+actors: actor.visual.speech_energy=audio.voice_energy if actor==voice_actor else 0.0
	if story.step in ["last_fishing","last_cook","last_deliver","farewell","keepsake"]: _care_tick(delta)
	if story.step in ["leave","archive"]: _escort_tick(delta)
	if not dialogue_rows.is_empty():
		dialogue_left-=delta; dialogue_age+=delta
		if dialogue_uses_camera:_cinematic_camera(delta)
		if dialogue_left<=0: _next_line()
	if fishing.active and dialogue_rows.is_empty(): fishing.tick(delta)
	if crafting and not busy and dialogue_rows.is_empty(): _craft_tick(delta)
	if demo_active: _demo_tick(delta)
	if story.step in ["march","search"] and not elder.moving and elder.position.distance_to(world.points.last_elder)<1.2 and not collapse_seen and not busy and dialogue_rows.is_empty() and player.position.distance_to(elder.position)<11:
		_collapse_witness()
	if story.step=="secret" and not elder.moving and elder.position.distance_to(world.points.secret)<1.2 and elder.visual.posture!="rising":
		elder.visual.posture="seated"; elder.visual.hold("scraps")
	if not player.locked and world.surface_at(player.position)=="grass" and player.is_on_floor(): safe_position=player.position
	checkpoint_clock+=delta
	if checkpoint_clock>12: checkpoint_clock=0; save_checkpoint()
func play_dialogue(group:String,finished:=Callable()):
	if not Dialogue.GROUPS.has(group) and group!="secret_notice": return
	dialogue_group=group; dialogue_rows=Dialogue.new().lines_for(group); dialogue_index=-1; dialogue_finish=finished
	if group=="supplies_done": _stand_for_supplies()
	walk_and_talk=group=="march"
	# Ordinary conversations retain the player's follow camera and mouse look.
	dialogue_uses_camera=group in ["intro","supplies_done","demo","secret_notice","secret","found_elder","last_soup","silence","keepsake","onward"]
	player.locked=not walk_and_talk;view.cinematic=dialogue_uses_camera;busy=not walk_and_talk
	if group in ["comrade_a","comrade_b","secret_notice","secret"]:
		_settle_comrade_conversation()
	focus_point=_dialogue_focus(group); focus_distance=4.1
	if group in ["secret","last_soup","silence"]: focus_distance=2.5
	_next_line()
func _next_line():
	audio.stop_voice(); dialogue_index+=1; dialogue_age=0
	if dialogue_index>=dialogue_rows.size():
		var callback=dialogue_finish;var used_camera=dialogue_uses_camera;_cancel_dialogue()
		busy=false; player.locked=crafting or fishing.active
		if not player.locked and used_camera: _reset_camera()
		if not player.locked and not callback.is_valid() and player.visual.posture=="kneel": player.visual.posture="weak"; player.visual.mode="idle"
		if callback.is_valid(): callback.call()
		return
	var row=dialogue_rows[dialogue_index]
	if dialogue_group=="supplies_done" and row.id=="supplies_done_04": world.fish_leap(); audio.cue("splash")
	hud.show_dialogue(row.speaker,row.text); dialogue_left=audio.speak(row)
	hud.map_panel.visible=dialogue_group=="intro" and dialogue_index<2
	var speaker_actor={"老班长":elder,"小梁":player,"小石":shi,"阿青":qing}.get(row.speaker)
	voice_actor=speaker_actor
	for actor in [player]+actors:
		actor.visual.conversation_role=0
		actor.visual.set_emotion(str(row.get("mood","")),actor==speaker_actor)
		actor.visual.look_enabled=actor.visual.posture!="collapsed"
		actor.visual.look_target=(speaker_actor.position if speaker_actor else focus_point)+Vector3(0,1.2,0)
	if speaker_actor and speaker_actor.visual.posture in ["standing","weak"]:
		speaker_actor.visual.mode="talk"; speaker_actor.visual.gesture="concerned" if dialogue_group in ["secret","last_soup"] else "explain"
		speaker_actor.visual.conversation_role=1
func _cancel_dialogue():
	walk_and_talk=false
	dialogue_uses_camera=false
	dialogue_rows=[]; dialogue_index=-1; dialogue_finish=Callable()
	voice_actor=null
	if hud: hud.hide_dialogue(); hud.map_panel.hide()
	if audio: audio.stop_voice()
	for actor in [player]+actors:
		if is_instance_valid(actor): actor.visual.conversation_role=0; actor.visual.look_enabled=false; actor.visual.release_emotion()
func _dialogue_focus(group:String)->Vector3:
	if group.begins_with("secret"): return elder.position+Vector3(0,.85,0)
	if group in ["found_elder","last_soup","silence"]: return _elder_head()+Vector3(0,.25,0)
	if group in ["keepsake","onward"]: return player.position+Vector3(0,1.15,0)
	if group=="march": return player.position+Vector3(1,1,-6)
	return elder.position+Vector3(0,1.15,0)
func _cinematic_camera(delta):
	var desired=focus_point+Vector3(-focus_distance*.72,focus_distance*.35,focus_distance)
	if dialogue_group=="intro" and dialogue_index<2: desired=Vector3(-24,12,30); focus_point=Vector3(0,0,-8)
	elif dialogue_group=="intro": focus_point=elder.position+Vector3(0,1.15,0); desired=focus_point+Vector3(-3,1.1,4)
	elif dialogue_group in ["found_elder","last_soup","silence"]:
		focus_point=_elder_head()+Vector3(0,.23,0); desired=focus_point+Vector3(1.8,.95,2.0)
	elif dialogue_group.begins_with("secret"):
		var row=dialogue_rows[dialogue_index]
		var actor=elder if row.speaker=="老班长" else player
		focus_point=actor.position+Vector3(0,.98 if actor==elder else 1.40,0)
		desired=focus_point+actor.global_basis*Vector3(.75,.2,1.4)
	elif dialogue_group=="onward":
		focus_point=player.position+Vector3(0,1,-2);desired=player.position+Vector3(8,6,8)
	elif dialogue_group=="supplies_done" and dialogue_rows[dialogue_index].id=="supplies_done_04":
		focus_point=world.PONDS[0]+Vector3(0,.2,0); desired=world.PONDS[0]+Vector3(-7,3.1,5)
	elif dialogue_group=="supplies_done": focus_point=elder.position+Vector3(0,1.15,0)
	view.camera.global_position=view.camera.global_position.lerp(desired,minf(delta*1.6,1))
	view.camera.look_at(focus_point,Vector3.UP); view.camera.fov=52
func _story_changed():
	world.update_story(story)
	if started: save_checkpoint()
func save_checkpoint():
	if not started: return
	var p=safe_position if world.surface_at(player.position)=="swamp" else player.position
	var data={"version":3,"chapter":story.snapshot(),"position":[p.x,p.y,p.z],"elapsed":elapsed,"demo_seen":demo_seen,"secret_observed":secret_observed,"collapse_seen":collapse_seen,"cast":_cast_snapshot()}
	if not store.write(data): hud.toast(store.last_error,5)
func continue_chapter()->bool:
	var data=store.read()
	if data.is_empty(): hud.toast(store.last_error,5); return false
	session_epoch+=1; demo_active=false
	_clear_demo()
	_cancel_dialogue(); fishing.exit(); _protect_unique_hook(); crafting=false; busy=false; paused=false; started=true; audio.set_paused(false)
	story=Story.new(); story.restore(data.chapter); story.changed.connect(_story_changed)
	var p=data.position; player.restore(Vector3(p[0],p[1]+.08,p[2])); safe_position=player.position
	elapsed=float(data.elapsed); demo_seen=bool(data.get("demo_seen",false)); secret_observed=bool(data.get("secret_observed",false));collapse_seen=bool(data.get("collapse_seen",Story.STEPS.find(story.step)>=Story.STEPS.find("search")));world.update_story(story)
	_restore_cast(data.get("cast",{})); hud.menu.hide(); _reset_camera(); Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	if story.step in ["heat","bend","tie","mount"]: _enter_craft()
	if story.step=="simmer": _simmer()
	if story.step=="last_deliver": player.visual.hold("bowl")
	if story.step=="farewell": _farewell_scene()
	if story.step=="archive": archive_menu(); player.locked=true
	return true
func _cast_snapshot()->Dictionary:
	var result={}
	for pair in [["elder",elder],["shi",shi],["qing",qing]]:
		var actor=pair[1];var route=[]
		if actor.moving:
			for i in range(actor.route_index,actor.route.size()):
				var waypoint=actor.route[i]
				route.append([waypoint.x,waypoint.y,waypoint.z])
		var p=actor.position
		result[pair[0]]={"position":[p.x,p.y,p.z],"yaw":actor.rotation.y,"posture":"weak" if actor.visual.posture=="rising" else actor.visual.posture,"held":actor.visual.held if actor.visual.held in ["bowl","scraps"] else "","route":route,"speed":actor.moving_speed}
	return result
func _restore_cast(saved:Dictionary={}):
	for n in actors: n.moving=false; n.visual.reset_pose()
	shi.visual.posture="seated"; qing.visual.posture="seated"
	var index=Story.STEPS.find(story.step)
	if index>=Story.STEPS.find("march"):
		shi.position=world.at_ground(Vector3(-1.5,0,-34)); qing.position=world.at_ground(Vector3(-2.5,0,-35))
		elder.position=world.points.last_elder; elder.visual.posture="collapsed"; world.set_final_weather(true)
	elif story.step=="secret": elder.position=world.points.secret; elder.visual.posture="seated"; elder.visual.hold("scraps")
	else: elder.position=world.points.elder; elder.visual.posture="kneel"
	audio.set_mood("memory" if story.step in ["leave","archive"] else ("silence" if index>=Story.STEPS.find("farewell") else ("urgent" if index>=Story.STEPS.find("search") else "shortage")))
	for pair in [["elder",elder],["shi",shi],["qing",qing]]:
		if not saved.has(pair[0]):continue
		var actor=pair[1];var data=saved[pair[0]];var p=data.position
		actor.position=Vector3(p[0],p[1],p[2]);actor.rotation.y=float(data.yaw);actor.horizontal_velocity=Vector3.ZERO;actor.safe_velocity=Vector3.ZERO;actor.vertical_speed=0;actor.avoidance.set_velocity_forced(Vector3.ZERO);actor.reset_physics_interpolation()
		actor.visual.previous_yaw=actor.rotation.y;actor.visual.restore_posture(data.posture);actor.visual.hold(data.held)
		var route=[]
		for point in data.route:route.append(Vector3(point[0],point[1],point[2]))
		if not route.is_empty():actor.walk(route,float(data.speed))
func _protect_unique_hook():
	var hook=world.work_hook
	if player.visual.held_node==hook: player.visual.held_node=null; player.visual.held=""
	if hook.get_parent()!=world: hook.reparent(world,true)
	hook.hide()
func recover_from_swamp():
	player.restore(safe_position+Vector3(0,.12,0)); _reset_camera(); hud.toast("回到最近的坚实草甸。物品与章节进度已保留。",4)
	save_checkpoint()
func sound(path:String,volume:float):
	var p=AudioStreamPlayer.new(); add_child(p); p.stream=load(path); p.volume_db=volume; p.finished.connect(p.queue_free); p.play()
func _entry(id:String,point:String,title:String)->Dictionary:
	return {"id":id,"point":world.points[point],"title":title}
func interactions()->Array:
	var options=[]
	match story.step:
		"supplies":
			var titles={"bag_a":"检查第一只粮袋","bag_b":"检查第二只粮袋","comrade_a":"问问小石的情况","comrade_b":"问问阿青的情况","ration":"查看剩余口粮","greens_a":"拾取食材","greens_b":"拾取食材"}
			for id in Story.SUPPLIES:
				if not story.done.get(id,false): options.append(_entry(id,id,titles[id]))
			if options.is_empty(): options.append(_entry("deliver_supplies","elder","把食材交给老班长"))
		"craft":
			for pair in [["needle","从旧衣袋取缝衣针"],["thread","收好一段线"],["branch","拾起结实的细枝"]]:
				if not story.done.get(pair[0],false): options.append(_entry(pair[0],pair[0],pair[1]))
			if options.is_empty(): options.append(_entry("place_parts","work","把针、线和细枝放在准备位置"))
		"heat","bend","tie","mount": options.append(_entry("resume_craft","work","继续制作鱼钩"))
		"first_fishing": options.append(_entry("fish","first_bank","准备钓鱼 · 还需 %d 条"%(2-story.inventory.fish)))
		"cook_fish": options.append(_entry("put_fish","pot","把两条小鱼放进锅里"))
		"cook_greens": options.append(_entry("put_greens","pot","加入带回的食材"))
		"light_fire": options.append(_entry("light_fire","pot","点燃营火"))
		"serve":
			if story.done.get("serve_a",false) and story.done.get("serve_b",false): options.append(_entry("drink_soup","pot","喝下留给自己的鱼汤"))
			elif player.visual.held!="bowl": options.append(_entry("take_bowl","pot","盛一碗热汤"))
			else:
				if not story.done.get("serve_a",false): options.append(_entry("serve_a","comrade_a","把鱼汤递给小石"))
				if not story.done.get("serve_b",false): options.append(_entry("serve_b","comrade_b","把鱼汤递给阿青"))
		"secret":
			if elder.moving:options.append({"id":"follow_elder","point":elder.position,"title":"沿草甸跟着老班长，先别惊动他"})
			if not elder.moving: options.append(_entry("understand" if secret_observed else "inspect_scraps","secret","告诉班长：明天让我多做一点" if secret_observed else "从侧后方看看他碗里的东西"))
		"march": options.append(_entry("continue_march","last_pot","沿实地前进，抵达下一处避风地"))
		"search": options.append(_entry("find_elder","last_elder","查看水塘旁的老班长"))
		"last_fishing": options.append(_entry("fish","last_bank","为老班长钓一条鱼"))
		"last_cook": options.append(_entry("last_cook","last_pot","与战友一起煮汤"))
		"last_deliver": options.append(_entry("last_deliver","last_elder","慢慢递上鱼汤"))
		"keepsake": options.append(_entry("collect_hook","hook","小心收起那枚鱼钩"))
		"leave": options.append(_entry("leave","exit","相互扶持，继续走出草地"))
	return options
func _nearest()->Dictionary:
	var found={}; var distance=2.35
	for option in interactions():
		var d=Vector2(option.point.x-player.position.x,option.point.z-player.position.z).length()
		if d<distance: found=option; distance=d
	return found
func current_target()->Vector3:
	var options=interactions()
	if options.is_empty(): return Vector3.INF
	return options[0].point
func target_name()->String:
	var options=interactions()
	return options[0].title if not options.is_empty() else ""
func act_name()->String:
	var i=Story.STEPS.find(story.step)
	if i<=0: return "一 · 断粮"
	if i<=5: return "二 · 希望"
	if i==6: return "三 · 第一条鱼"
	if i<=13: return "四 · 鱼汤与秘密"
	if i<=18: return "五 · 为了老班长"
	return "六 · 金色的鱼钩"
func objective_text()->String:
	if crafting:
		return {"heat":"把针放在火上，留意金属颜色的变化","bend":"趁热把针弯成钩形","tie":"把钓线系到鱼钩上","mount":"把钓线装到细枝上"}.get(story.step,"")
	if story.step=="supplies":
		return "检查物资与战友 · %d / 5\n寻找两份食材 · %d / 2"%[int(story.done.get("bag_a",false))+int(story.done.get("bag_b",false))+int(story.done.get("comrade_a",false))+int(story.done.get("comrade_b",false))+int(story.done.get("ration",false)),story.inventory.greens]
	if story.step=="simmer": return "守在火塘旁，等热汤煮好"
	if story.step=="farewell": return "陪在老班长身旁"
	return target_name()
func interaction_hint()->String:
	if paused or not started: return ""
	if not dialogue_rows.is_empty(): return ""
	if crafting:
		return {"heat":"按住鼠标左键 · 加热  %d%%"%int(heat_progress*100),"bend":"按住 D · 弯钩  %d%%"%int(bend_progress*100),"tie":"E · 系牢钓线","mount":"E · 将鱼钩安装到鱼竿"}.get(story.step,"")
	if fishing.active: return "Q 收竿    ·    Esc 暂停"
	if busy: return ""
	var option=_nearest()
	if not option.is_empty(): return "[ E ]  "+option.title
	return "WASD 行走    ·    鼠标观察    ·    沿 ◇ 寻找目标"
func interact():
	if busy or not started or paused: return
	if crafting:
		if story.step=="tie": _tie_craft()
		elif story.step=="mount":
			_mount_craft()
		return
	var option=_nearest()
	if option.is_empty(): return
	if option.id=="follow_elder":return
	if option.id=="fish": try_fishing(); return
	if option.id=="resume_craft": _enter_craft(); return
	_do_action(option)
func try_fishing()->bool:
	if busy or story.step not in ["first_fishing","last_fishing"]: return false
	var index=1 if story.step=="last_fishing" else 0
	if player.position.distance_to(world.BANKS[index])>2.4: return false
	if index==0 and not demo_seen: _demonstrate()
	else: fishing.enter(index)
	return true
func _wait(seconds:float,epoch:=-1)->bool:
	if epoch<0: epoch=session_epoch
	var passed=0.0
	while passed<seconds and is_inside_tree():
		await get_tree().process_frame
		if epoch!=session_epoch or not started: return false
		if not paused: passed+=get_process_delta_time()
	return is_inside_tree() and epoch==session_epoch and started
func _approach(point:Vector3,distance:=.82):
	var epoch=session_epoch
	var direction=player.position-point; direction.y=0
	if direction.length()<.1: direction=Vector3.BACK
	var goal=world.at_ground(point+direction.normalized()*distance)
	var timeout=0.0
	while Vector2(player.position.x-goal.x,player.position.z-goal.z).length()>.05 and timeout<2.2:
		await get_tree().physics_frame
		if epoch!=session_epoch or not started: return
		if paused: continue
		var delta=get_physics_process_delta_time(); timeout+=delta
		var move=goal-player.position; move.y=0
		var offset=move.limit_length(delta*1.7)
		player.move_and_collide(offset); player.position.y=world.height_at(player.position)
		player.rotation.y=lerp_angle(player.rotation.y,atan2(move.x,move.z),minf(delta*9,1)); player.visual.speed=1.7; player.visual.mode="walk"
	var face=point-player.position
	player.rotation.y=atan2(face.x,face.z); player.rotation_direction=player.rotation.y; player.visual.speed=0
func _settle_comrade_conversation():
	# A conversation needs neither a scripted approach nor a reaching/weak pose.
	player.velocity=Vector3.ZERO; player.movement_velocity=Vector3.ZERO
	player.visual.speed=0; player.visual.walk_gait_scale=1.0
	player.visual.posture="standing"; player.visual.mode="idle"
	player.visual.hand_targets=[]
	if player.visual.ground_contact: player.visual.ground_contact.reset(true)

func _stand_for_supplies():
	elder.moving=false
	elder.visual.posture="standing"; elder.visual.mode="idle"; elder.visual.speed=0
	elder.visual.hand_targets=[]
	elder.face(player.position)

func _do_action(option:Dictionary):
	var epoch=session_epoch
	busy=true; player.locked=true
	var id=option.id; var point=option.point
	if id=="deliver_supplies": _stand_for_supplies()
	if id in ["comrade_a","comrade_b"]:
		_settle_comrade_conversation()
	else:
		var approach_distance = 1.15 if id in ["inspect_scraps","understand"] else (.66 if id=="last_deliver" else .82)
		await _approach(_elder_head() if id=="last_deliver" else point,approach_distance)
	if not started or epoch!=session_epoch: return
	var kneeling=id not in ["comrade_a","comrade_b","serve_a","serve_b","continue_march","leave","inspect_scraps","understand","deliver_supplies"]
	player.visual.posture="kneel" if kneeling else "standing"
	player.visual.hand_targets=[point+Vector3(-.07,.18,0),point+Vector3(.07,.18,0)] if kneeling else []
	if not await _wait(.8,epoch): return
	if id in ["greens_a","greens_b","needle","thread","branch"]:
		player.visual.hold("greens" if id.begins_with("greens") else "parcel"); audio.cue("pickup")
	if id=="take_bowl":
		player.visual.posture="standing"; player.visual.hold("bowl"); audio.cue("pickup")
		if not await _wait(.6,epoch): return
		_finish_action(); return
	if id in ["serve_a","serve_b"]:
		var receiver=shi if id=="serve_a" else qing
		if not await _handoff(receiver,epoch): return
	if id=="last_deliver":
		player.visual.posture="kneel"
		if not await _offer_bowl(epoch): return
	if id=="collect_hook":
		var actual_hook=world.work_hook
		actual_hook.reparent(player.visual,true); player.visual.held="hook"; player.visual.held_node=actual_hook; actual_hook.show()
		actual_hook.rotation=Vector3.ZERO; actual_hook.scale=Vector3.ONE*1.3
		if not await _wait(.12,epoch): return
		view.cinematic=true; view.camera.global_position=player.visual.to_global(Vector3(.42,.86,1.05)); view.camera.look_at(actual_hook.to_global(Vector3(0,.035,0))); view.camera.fov=38
		if not await _wait(1.6,epoch): return
		var hook_position=actual_hook.global_position
		player.visual.held_node=null;player.visual.held="";player.visual.hold("parcel")
		var cloth=player.visual.held_node;cloth.global_position=hook_position-Vector3(0,.012,0)
		player.visual.external_grip=true;player.visual.set_contact("parcel",cloth)
		actual_hook.reparent(cloth,false);actual_hook.position=Vector3(-.008,.012,-.028);actual_hook.rotation=Vector3(PI/2,0,0);actual_hook.scale=Vector3.ONE
		view.camera.global_position=cloth.global_position+Vector3(.32,.36,.42);view.camera.look_at(cloth.global_position);view.camera.fov=39
		for i in 24:
			P.set_wrap(cloth,(i+1)/24.0)
			if not await _wait(1.5/24,epoch):return
		actual_hook.hide()
		player.visual.posture="standing"
		if not await _wait(.65,epoch):return
		var start=cloth.global_position
		var target=player.visual.to_global(Vector3(-.095,1.27,.145))
		view.camera.global_position=player.visual.to_global(Vector3(.65,1.5,1.5));view.camera.look_at(player.position+Vector3(0,1.15,0))
		for i in 24:
			cloth.global_position=start.lerp(target,smoothstep(0,1,(i+1)/24.0))
			if not await _wait(1.1/24,epoch):return
		actual_hook.reparent(player.visual,false);actual_hook.position=Vector3(-.095,1.27,.145);actual_hook.hide();player.visual.hold("");player.visual.external_grip=false;player.visual.contact_prop=null

	if id=="drink_soup":
		player.visual.hold("bowl"); player.visual.posture="standing"
		if not await _wait(1.4,epoch): return
		player.visual.hold("")
	if id=="last_cook":
		world.final_flame.show(); audio.cue("fire")
		if not await _wait(3.2,epoch): return
		player.visual.hold("bowl")
	if id=="inspect_scraps":
		if elder.moving: _finish_action();return
		var bowl=elder.visual.held_node
		view.cinematic=true;audio.set_mood("silence")
		view.camera.global_position=bowl.global_position+elder.global_basis*Vector3(-.40,.32,.50)
		view.camera.look_at(bowl.global_position+Vector3(0,.055,0));view.camera.fov=36
		if not await _wait(1.4,epoch):return
		secret_observed=true;save_checkpoint();_finish_action();play_dialogue("secret_notice");return
	if id=="find_elder" and elder.moving:
		_finish_action(); hud.toast("沿水塘的实地走，他就在前面的岸边。",3); return
	var performed=true if id=="understand" else story.perform(id)
	if not performed: _finish_action(); return
	if id=="place_parts": _finish_action(); player.visual.hold(""); _enter_craft(); return
	if id=="deliver_supplies": player.visual.hold(""); _finish_action(); audio.set_mood("hope"); play_dialogue("supplies_done"); return
	if id=="light_fire":
		audio.cue("fire"); _finish_action(); _simmer(); return
	if id=="drink_soup":
		elder.visual.reset_pose(); elder.visual.hold("scraps"); audio.set_mood("silence"); elder.walk([world.at_ground(Vector3(-13,0,2)),world.points.secret],1.3)
		_finish_action(); play_dialogue("after_soup"); return
	if id=="understand":
		_finish_action(); elder.moving=false; elder.face(player.position); elder.visual.posture="seated"; elder.visual.hold("scraps"); _settle_comrade_conversation()
		audio.set_mood("silence")
		var bowl=elder.visual.held_node;elder.visual.external_grip=true;elder.visual.set_contact("bowl",bowl)
		var start=bowl.position
		for i in 15:
			bowl.position=start.lerp(Vector3(-.015,.59,.19),(i+1)/15.0)
			if not await _wait(.55/15,epoch):return
		if not await _wait(.8,epoch):return
		play_dialogue("secret",_secret_silence); return
	if id=="continue_march":
		_finish_action(); world.set_final_weather(true); audio.set_mood("urgent"); play_dialogue("search"); return
	if id=="find_elder":
		shi.walk([world.at_ground(_elder_head()+Vector3(.85,0,-.15))],1.1); qing.walk([world.at_ground(world.points.last_elder+Vector3(-.9,0,-.7))],1.2)
		_finish_action(); play_dialogue("found_elder"); return
	if id=="last_deliver": _finish_action(); _farewell_scene(); return
	if id=="collect_hook": _finish_action(); audio.set_mood("memory"); play_dialogue("keepsake"); return
	if id=="leave":
		_finish_action(); player.walk_to(world.at_ground(player.position+Vector3(0,0,-5)),1.15); play_dialogue("onward",_end_chapter); return
	_finish_action()
	if Dialogue.GROUPS.has(id):
		if id in ["serve_a","serve_b"]: audio.set_mood("warm")
		play_dialogue(id)
func _finish_action():
	busy=false; player.locked=false; player.visual.posture="weak"; player.visual.hand_targets=[]
	player.visual.mode="idle"; player.visual.speed=0
	if view.cinematic and not crafting and not fishing.active: _reset_camera()
	save_checkpoint()
func _handoff(receiver,epoch:int)->bool:
	var bowl=player.visual.held_node
	if not is_instance_valid(bowl): player.visual.hold("bowl"); bowl=player.visual.held_node
	var start=bowl.global_position
	receiver.face(player.position)
	var target=receiver.visual.to_global(Vector3(-.015,.61,.34))
	player.visual.external_grip=true
	player.visual.set_contact("bowl",bowl)
	for i in 30:
		if not await _wait(1.0/30,epoch): return false
		var point=start.lerp(target,(i+1)/30.0); bowl.global_position=point
		player.visual.hand_targets=player.visual.contact.targets("bowl",bowl)
		receiver.visual.hand_targets=player.visual.hand_targets
	bowl.reparent(receiver.visual,true); bowl.rotation=Vector3.ZERO; receiver.visual.held="bowl"; receiver.visual.held_node=bowl
	player.visual.held_node=null; player.visual.held=""; player.visual.external_grip=false; player.visual.hand_targets=[]; player.visual.contact_prop=null
	return await _wait(.7,epoch)
func _enter_craft():
	crafting=true; player.locked=true; view.cinematic=true; heat_progress=0; bend_progress=0
	elder.visual.reset_pose()
	var goal=world.flame.position+Vector3(-.62,0,.18) if story.step=="heat" else world.points.work+Vector3(-.45,0,-.6)
	elder.walk([world.at_ground(goal)],1.3)
	player.visual.posture="standing"
	player.visual.hand_targets=[]
	view.camera.global_position=world.points.work+Vector3(-1.3,1.35,1.35); view.camera.look_at(world.points.work+Vector3(0,.23,0)); view.camera.fov=42
func _exit_craft():
	crafting=false; player.locked=false; player.visual.reset_pose(); elder.visual.reset_pose(); _reset_camera(); save_checkpoint()
func _craft_tick(delta):
	var work=world.points.work
	elder.visual.posture="weak" if elder.moving else "kneel"
	if not elder.moving:elder.face(world.flame.position if story.step=="heat" else work)
	var goal=elder.visual.to_global(Vector3(-.12,1.0,.35)) if elder.moving else (world.flame.position+Vector3(-.38,.30,.28) if story.step=="heat" else work+Vector3(.02,.16,.08))
	world.work_hook.global_position=world.work_hook.global_position.lerp(goal,1-exp(-delta*12))
	elder.visual.external_grip=true;elder.visual.set_contact("hook",world.work_hook)
	player.visual.hand_targets=[]
	if story.step=="heat":
		var heat_focus=world.work_needle.global_position
		view.camera.global_position=view.camera.global_position.lerp(heat_focus+Vector3(.08,.26,.48),minf(delta*4,1)); view.camera.look_at(heat_focus+Vector3(.005,0,0));view.camera.fov=39
		heat_progress=clampf(heat_progress+(delta/2.5 if Input.is_action_pressed("shoot") and not elder.moving else -delta*.08),0,1)
		world.work_hook.set_heat(heat_progress)
		if heat_progress>=1:
			story.perform("heat"); audio.cue("fire"); elder.walk([world.at_ground(work+Vector3(-.45,0,-.6))],1.3)
	elif story.step=="bend":
		if Input.is_action_pressed("bend_hook") and not elder.moving: bend_progress=clampf(bend_progress+delta/1.7,0,1)
		world.work_hook.scale=Vector3.ONE*1.25;world.work_hook.set_bend(bend_progress);world.work_hook.set_heat(.55*(1-bend_progress))
		view.camera.global_position=view.camera.global_position.lerp(work+Vector3(-.38,.43,.55),minf(delta*4,1));view.camera.look_at(work+Vector3(0,.11,0));view.camera.fov=39
		if bend_progress>=1: story.perform("bend"); audio.cue("pickup")
func _tie_craft():
	var epoch=session_epoch;busy=true;world.work_thread.show()
	for i in 24:
		world.thread_progress=(i+1)/24.0
		if not await _wait(1.1/24,epoch):return
	story.perform("tie");audio.cue("pickup");busy=false
func _mount_craft():
	var epoch=session_epoch;busy=true
	view.camera.global_position=world.points.work+Vector3(-.55,.72,1.35);view.camera.look_at(world.points.work+Vector3(.16,.12,.11));view.camera.fov=43
	if not await _wait(1.25,epoch):return
	story.perform("mount");_exit_craft();busy=false
	elder.walk([world.at_ground(Vector3(-2,0,2)),world.points.first_bank+Vector3(0,0,-1.8)],1.8)
	play_dialogue("craft_done")
func _simmer():
	var epoch=session_epoch
	var simmer_began=elapsed
	busy=true; player.locked=true
	elder.visual.reset_pose();elder.visual.posture="weak";elder.walk([world.at_ground(world.points.pot+Vector3(-.58,0,-.23))],1.3)
	var wait_time=0.0
	while elder.moving and wait_time<3.0:
		if not await _wait(.05,epoch):return
		wait_time+=.05
	elder.visual.posture="kneel";elder.face(world.points.pot)
	var ladle=load("res://assets/golden_hook/models/soup_ladle.glb").instantiate();world.add_child(ladle);ladle.global_basis=elder.global_basis
	elder.visual.external_grip=true;elder.visual.set_contact("ladle",ladle)
	var stir_began=elapsed
	while elapsed-simmer_began<4.8:
		var angle=(elapsed-stir_began)/maxf(.3,4.8-wait_time)*TAU;ladle.global_position=world.points.pot+Vector3(cos(angle)*.10,.48+sin(angle*2)*.008,sin(angle)*.10)
		if not await _wait(.001,epoch):_clear_stir(ladle);return
	_clear_stir(ladle)
	story.perform("finish_soup"); elder.visual.hand_targets=[]; _finish_action(); audio.set_mood("warm"); play_dialogue("soup_ready")
func _clear_stir(ladle:Node3D):
	if elder.visual.contact_prop==ladle:elder.visual.external_grip=false;elder.visual.contact_prop=null;elder.visual.contact_profile="";elder.visual.hand_targets=[]
	if is_instance_valid(ladle):ladle.queue_free()
func _demonstrate():
	demo_clock=0; demo_active=true
	busy=true; player.locked=true
	elder.moving=false; elder.visual.posture="standing"; elder.face(world.PONDS[0])
	demo_rod=Node3D.new(); elder.visual.add_child(demo_rod); demo_rod.position=Vector3(-.08,1.07,.36)
	demo_rod.set_meta("shaft_slope",.181); elder.visual.set_contact("rod",demo_rod)
	P.cylinder(demo_rod,Vector3(0,0,-.18),Vector3(0,.45,2.3),.016,P.mat("796747"))
	elder.visual.hand_targets=elder.visual.contact.targets("rod",demo_rod)
	demo_float=P.ellipsoid(self,Vector3(.06,.13,.06),world.PONDS[0]+Vector3(-1,-.13,1),"bb5d40")
	demo_line=P.polyline(self,PackedVector3Array([demo_rod.to_global(Vector3(0,.45,2.3)),demo_float.position]),.002,P.mat("c7c0a4"))
	play_dialogue("demo",func():
		_clear_demo(); demo_seen=true; elder.visual.reset_pose(); save_checkpoint(); fishing.enter(0))
func _clear_demo():
	demo_active=false
	for prop in [demo_rod,demo_float,demo_line]:
		if is_instance_valid(prop): prop.queue_free()
	demo_rod=null; demo_float=null; demo_line=null
func _demo_tick(delta):
	demo_clock+=delta
	if not is_instance_valid(demo_rod): demo_active=false; return
	demo_rod.rotation.x=-sin(clampf(demo_clock/1.8,0,1)*PI)*.65
	elder.visual.hand_targets=elder.visual.contact.targets("rod",demo_rod)
	var start=demo_rod.to_global(Vector3(0,.45,2.3)); var finish=world.PONDS[0]+Vector3(-1,-.13,1)
	demo_float.visible=demo_clock>1.3
	if demo_clock<2:
		var t=clampf((demo_clock-1.3)/.7,0,1); demo_float.global_position=start.lerp(finish,t)+Vector3(0,sin(t*PI)*1.1,0)
	else: demo_float.global_position=finish+Vector3(0,sin(demo_clock*6)*.012-(.18 if fmod(demo_clock,12)>10.7 else 0.0),0)
	var line=demo_line.get_child(0); var direction=demo_float.global_position-start
	line.visible=direction.length()>.0001 and demo_float.visible
	if line.visible:
		line.position=(start+demo_float.global_position)*.5; line.mesh.height=direction.length(); line.quaternion=Quaternion(Vector3.UP,direction.normalized())
func after_fishing():
	if story.step=="first_fishing": play_dialogue("first_fish")
	elif story.step=="cook_fish":
		elder.walk([world.at_ground(Vector3(-2,0,2)),world.points.elder],1.6); play_dialogue("two_fish")
	elif story.step=="last_cook": play_dialogue("last_fish")
func _start_march():
	var epoch=session_epoch;busy=true;player.locked=true;view.cinematic=true
	for n in actors:
		n.visual.hold("");n.visual.posture="rising"
	if not await _wait(elder.visual.animator.get_animation("Sitting_Exit").length,epoch):return
	if story.step=="secret":story.perform("understand")
	for n in actors: n.visual.reset_pose(); n.visual.posture="weak"
	elder.walk([world.at_ground(Vector3(-15,0,-12)),world.at_ground(Vector3(-1,0,-18)),world.at_ground(Vector3(1,0,-29)),world.points.last_elder],1.55)
	shi.walk([world.at_ground(Vector3(-1,0,-12)),world.at_ground(Vector3(1,0,-25)),world.at_ground(Vector3(-1.5,0,-34))],1.75)
	qing.walk([world.at_ground(Vector3(0,0,-12)),world.at_ground(Vector3(2,0,-25)),world.at_ground(Vector3(-2.5,0,-35))],1.65)
	save_checkpoint()
	play_dialogue("march")
func _farewell_scene():
	audio.set_mood("silence"); elder.visual.posture="collapsed"; player.visual.posture="kneel"; player.visual.hold("bowl")
	play_dialogue("last_soup",func(): _farewell_silence())
func _elder_head()->Vector3:
	var skeleton=elder.visual.skeleton
	return skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("Head")).origin)
func _care_tick(delta):
	for actor in [shi,qing]:
		if actor.moving: continue
		var toward=elder.position-actor.position; toward.y=0
		if toward.length_squared()<.01: continue
		actor.rotation.y=lerp_angle(actor.rotation.y,atan2(toward.x,toward.z),1-exp(-delta*5))
		actor.visual.posture="kneel"
		if dialogue_rows.is_empty(): actor.visual.set_emotion("担心，低声",false)
		actor.visual.look_enabled=true; actor.visual.look_target=_elder_head()
func _farewell_silence():
	var epoch=session_epoch
	busy=true; player.locked=true
	if not await _wait(4.0,epoch): return
	story.perform("farewell")
	if is_instance_valid(player.visual.held_node):
		var bowl=player.visual.held_node; var start=bowl.global_position; var target=world.at_ground(elder.position+Vector3(.38,0,.3))+Vector3(0,.035,0)
		for i in 18:
			bowl.global_position=start.lerp(target,(i+1)/18.0)
			if not await _wait(.6/18,epoch): return
		bowl.reparent(world,true); player.visual.held_node=null; player.visual.held=""; player.visual.external_grip=false; player.visual.contact_prop=null; player.visual.hand_targets=[]
	play_dialogue("silence")
func _offer_bowl(epoch:int)->bool:
	if not is_instance_valid(player.visual.held_node): player.visual.hold("bowl")
	var bowl=player.visual.held_node; var start=bowl.global_position
	var direction=player.position-_elder_head(); direction.y=0
	if direction.length_squared()<.0001: direction=Vector3.BACK
	var target=_elder_head()+direction.normalized()*.14+Vector3(0,.09,0)
	player.visual.external_grip=true; player.visual.set_contact("bowl",bowl)
	for i in 30:
		var t=(i+1)/30.0; t=t*t*(3-2*t); bowl.global_position=start.lerp(target,t)
		if not await _wait(1.3/30,epoch): return false
	return await _wait(.4,epoch)
func _secret_silence():
	var epoch=session_epoch;busy=true;player.locked=true
	view.cinematic=true;view.camera.global_position=elder.position+elder.global_basis*Vector3(.75,1.15,1.3);view.camera.look_at(elder.position+Vector3(0,.92,0))
	if not await _wait(1.4,epoch):return
	_start_march()
func _collapse_witness():
	var epoch=session_epoch;collapse_seen=true;busy=true;player.locked=true;view.cinematic=true
	elder.visual.posture="collapsed"
	view.camera.global_position=elder.position+Vector3(2.7,1.4,-1.3);view.camera.look_at(elder.position+Vector3(0,.65,-.35));view.camera.fov=53
	if not await _wait(2.6,epoch):return
	_finish_action()
func _escort_tick(delta):
	escort_clock-=delta
	if escort_clock>0:return
	escort_clock=1.0
	for pair in [[shi,Vector3(-1.15,0,.7)],[qing,Vector3(1.15,0,1.1)]]:
		var actor=pair[0];var goal=world.at_ground(player.position+pair[1])
		if actor.position.distance_to(goal)>2.4:
			actor.visual.posture="weak";actor.walk([goal],1.8)
func _end_chapter():
	var epoch=session_epoch
	busy=true;player.locked=true;audio.set_mood("memory");view.cinematic=true
	view.camera.global_position=player.position+Vector3(11,8,12);view.camera.look_at(player.position+Vector3(0,1,-3));view.camera.fov=58
	hud.show_dialogue("谨以此章，铭记同行的人","一枚鱼钩，留住生命与信任。\n金色的光，照在继续前行的路上。")
	if not await _wait(5.0,epoch):return
	hud.hide_dialogue();busy=false;player.locked=true;save_checkpoint();archive_menu()

func export_smoke():
	await get_tree().create_timer(2).timeout
	var good=actors.size()==3 and player.visual.skeleton.get_bone_count()==53 and world.items.size()==8
	print("GOLDEN EXPORT SMOKE ","PASS" if good else "FAIL")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(OS.get_executable_path().get_base_dir().path_join("golden_export_smoke.png"))
	get_tree().quit(0 if good else 1)
func start_replay():
	var runner=load("res://qa/golden_input_playthrough.gd").new(); get_tree().root.add_child(runner); runner.run(self)
func start_action_lab():
	var runner=load("res://qa/golden_action_lab.gd").new();get_tree().root.add_child(runner);runner.run(self)
