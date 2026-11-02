extends "res://game/mission.gd"
const Route=preload("res://game/snow/route.gd")
const Store=preload("res://game/snow/save_store.gd")
var stage:="INTRO"
var flags:Dictionary={}
var stats:Dictionary={"jumps":0,"signals":0,"clues":0,"walked_m":0.0}
var save_store=Store.new()
var last_checkpoint:Dictionary={}
var weather
var observation
var audio
var vegetation
var high_quality:=true
var marchers:Array=[]
var camera_observing:=false
var intro_clock:=0.0
var outro_clock:=0.0
var outro_active:=false
var intro_lines:=0
var outro_lines:=0
var map_panel:Control
var safe_point:=Vector3(0,.15,40)
var previous_position:=Vector3.ZERO
var milestone:=""
var spatial_voice:AudioStreamPlayer3D
var collapse_sound:AudioStreamPlayer3D
var fail_reason:=""
var observe_held:=false
var signal_held:=false
func _ready():
	process_physics_priority=20;_inputs()
	for entry in [["observe",KEY_F],["signal",KEY_Q]]:
		if not InputMap.has_action(entry[0]):InputMap.add_action(entry[0])
		var key=InputEventKey.new();key.physical_keycode=entry[1];InputMap.action_add_event(entry[0],key)
	world=_world_type().new();world.mission=self;world.name="JiajinMountain";add_child(world)
	player=load("res://objects/player.tscn").instantiate();player.set_script(_player_type());player.mission=self;player.visual_type=_visual_type();player.position=Vector3(0,.18,40);player.rotation.y=PI;player.rotation_direction=PI;add_child(player);player.died.connect(_on_death)
	view=Node3D.new();view.name="View";view.set_script(load("res://game/camera.gd"));view.mission=self;view.target=player;view.use_bridge_bounds=false;view.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	var camera=Camera3D.new();camera.name="Camera";camera.current=true;camera.far=950;view.add_child(camera);add_child(view);player.view=view
	amu=_actor("Amu",Vector3(-.55,.18,42),false);zhou=_actor("Zhou",Vector3(.55,.18,43.5),false)
	for i in 2:marchers.append(_actor("SnowMarcher%d"%i,Vector3(-.6+i*1.2,.18,45+i*1.5),false))
	for i in actors().size():actors()[i].follow_distance=2.6+i*1.65
	combat=load("res://game/combat.gd").new();combat.mission=self;add_child(combat)
	hud=_hud_type().new();hud.mission=self;add_child(hud)
	audio=_audio_type().new();audio.mission=self;add_child(audio)
	weather=_weather_type().new();add_child(weather);weather.setup(self)
	observation=load("res://game/snow/observation.gd").new();observation.setup(self)
	vegetation=load("res://game/snow/vegetation.gd").new();add_child(vegetation);vegetation.setup(self);world.set_quality(high_quality)
	spatial_voice=AudioStreamPlayer3D.new();add_child(spatial_voice);spatial_voice.max_distance=150;spatial_voice.unit_size=8;spatial_voice.volume_db=-7
	collapse_sound=AudioStreamPlayer3D.new();add_child(collapse_sound);collapse_sound.max_distance=120;collapse_sound.unit_size=25;collapse_sound.stream=load("res://assets/snow/audio/snow_slide.wav")
	DisplayServer.window_set_title("万水千山 · 雪线之上 V4.0");main_menu()
	if "--snow-replay" in OS.get_cmdline_user_args():call_deferred("_start_snow_replay")
	if "--smoke-snow" in OS.get_cmdline_user_args():call_deferred("_snow_smoke")
func _actor(actor_name:String,pos:Vector3,is_enemy:bool):
	var actor=_npc_type().new();actor.name=actor_name;actor.position=pos;actor.mission=self;actor.enemy=is_enemy;actor.visual_type=_visual_type();add_child(actor);return actor
func actors()->Array:return [amu,zhou]+marchers
func actor_by_name(who:String):return {"林川":player,"阿木":amu,"周班长":zhou}.get(who)
func main_menu():
	started=false;paused=false;failed=false;outro_active=false;camera_observing=false;player.locked=true
	if audio:audio.clear_voice()
	for actor in actors():actor.moving=false
	if map_panel:map_panel.queue_free();map_panel=null
	view.cinematic=true;view.camera.global_position=Vector3(-20,17,62);view.camera.look_at(Vector3(0,19,-65));hud.center_title.text=""
	var actions=[]
	if save_store.exists():actions.append(["继续雪山关卡",continue_story])
	actions.append_array([["开始 · 雪线之上",begin],["操作与画质",settings_menu],["章节选择",chapter_menu],["退出",quit_game]])
	hud.show_menu("雪线之上 · 翻越夹金山","第二关　1935年6月\n\n观察山路，借岩避风。\n穿过滑塌险坡，寻找失散队伍，带大家翻过山口。\n\nWASD 移动 · 鼠标转视角 · Shift 奔跑\n空格 跳跃 · F 观察 · Q 发信号 · Esc 暂停",actions)
func begin():
	audio.clear_voice();flags.clear();stats={"jumps":0,"signals":0,"clues":0,"walked_m":0.0};observation.reset();world.set_collapsed(false)
	stage="INTRO";started=true;paused=false;failed=false;phase=Phase.INTRO;elapsed=0;retries=0;intro_clock=0;intro_lines=0;outro_lines=0;outro_active=false;weather.clock=0;weather.shelter_visits.clear();last_checkpoint={}
	player.restore(Vector3(0,.18,40));player.locked=true;previous_position=player.position
	for i in actors().size():
		var actor=actors()[i];actor.restore();var spawn=Vector3(-.55 if i%2 else .55,0,42+float(i)*1.3);spawn.y=world.height_at(spawn)+.35;actor.position=spawn;actor.vertical_speed=0;actor.jumps=0;actor.reset_physics_interpolation();actor.walk(_party_path(1,2,i),1.3)
	safe_point=player.position;hud.hide_menu();hud.center_title.text="1935年6月，夹金山。";Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	_show_route_map()
	save_checkpoint()
func _process(delta):
	var observe_now=Input.is_action_pressed("observe");var signal_now=Input.is_action_pressed("signal")
	var observe_press=observe_now and not observe_held;var signal_press=signal_now and not signal_held
	observe_held=observe_now;signal_held=signal_now
	if Input.is_action_just_pressed("pause") and started:toggle_pause()
	if not started or paused or failed:return
	elapsed+=delta
	if stage=="INTRO":_intro(delta);return
	if outro_active:_outro(delta);return
	if stage=="COMPLETE":return
	if observe_press:camera_observing=not camera_observing;print("SNOW_OBSERVE ",camera_observing," frame=",Engine.get_process_frames())
	if signal_press:signal_party()
	observation.tick(delta)
func _physics_process(delta):
	if not started or failed:return
	weather.tick(delta)
	if paused:return
	world.tick(delta)
	var distance=player.position.distance_to(previous_position)
	if distance<2:stats.walked_m+=distance
	previous_position=player.position
	if stage=="INTRO" or outro_active or stage=="COMPLETE":return
	var n=world.route.nearest(player.position);var p=player.position
	if stage=="ROUTE_FINDING":
		if flags.get("route_seen",false) and p.distance_to(world.clues.route.point)<3:flags.route_confirmed=true
	elif stage=="BLIZZARD":
		for i in world.shelter_centers.size():
			if p.distance_to(world.shelter_centers[i])<3 and milestone!="shelter_%d"%i:
				milestone="shelter_%d"%i;safe_point=world.shelter_centers[i]+Vector3.UP*.15;save_checkpoint()
		if n.s>=world.route.lengths[11]-3:_transition("SLOPE_COLLAPSE",world.route.POINTS[11]);say("周班长","等风小一点再走，别急。")
	elif stage=="SLOPE_COLLAPSE":
		if not flags.get("collapse_triggered",false) and p.distance_to(world.route.POINTS[12])<5.5:
			flags.collapse_triggered=true;world.begin_collapse();view.shake=.75;collapse_sound.position=world.route.POINTS[12];collapse_sound.play();say("阿木","小心！上面的雪下来了！");say("周班长","往岩壁那边撤！");save_checkpoint()
		if flags.get("collapse_triggered",false):
			if p.distance_to(world.route.POINTS[13])<4:flags.collapse_evaded=true
			if world.collapse_time>3.6 and world.collapse_time<5.5 and p.distance_to(world.route.POINTS[12]+Vector3(0,0,-2))<4.2:fail("滑雪和落石封住了旧路。预警后向左侧岩壁撤开。")
			if flags.get("collapse_evaded",false) and n.s>world.route.lengths[15]:
				flags.detour_used=true;_send_party(11,16);_transition("REUNION",world.route.POINTS[16]);say("林川","周班长！阿木！");_distant_call()
	elif stage=="REUNION":
		if flags.get("ridge_seen",false) and p.distance_to(world.route.POINTS[19])<3 and _party_visible():flags.overlook=true
	elif stage=="SUMMIT":
		for i in world.jump_centers.size():
			if n.s>world.jump_centers[i]+2:flags["crossed_gap_%d"%i]=true
		if n.s>world.route.lengths[24]+3 and milestone!="last_shelter":milestone="last_shelter";safe_point=world.route.POINTS[24]+Vector3.UP*.15;save_checkpoint()
		if p.distance_to(world.route.POINTS[-1])<4 and flags.get("crossed_gap_0",false) and flags.get("crossed_gap_1",false):
			flags.at_pass=true
			player.locked=true
			if _gathered():outro_active=true;outro_clock=0;outro_lines=0;player.locked=true;camera_observing=false;view.cinematic=true
func _intro(delta:float):
	intro_clock+=delta
	if intro_clock<8:return
	if map_panel:map_panel.queue_free();map_panel=null
	var t=clampf((intro_clock-8)/12,0,1);view.camera.global_position=Vector3(-17,10,58).lerp(Vector3(-6,5,48),t);view.camera.look_at(Vector3(0,12,-25));hud.center_title.text="1935年6月，夹金山。" if intro_clock<12 else ""
	var lines=[[8.3,"阿木","桥过来了，可前面这座山，怎么连路都看不清？"],[13.5,"周班长","跟紧队伍。先认准山路，别在这地方走散。"],[18.5,"林川","我到前面看看。"]]
	while intro_lines<lines.size() and intro_clock>lines[intro_lines][0]:say(lines[intro_lines][1],lines[intro_lines][2]);intro_lines+=1
	if intro_clock>22 or Input.is_action_just_pressed("jump"):
		hud.center_title.text="";player.locked=false;_reset_camera();_transition("ROUTE_FINDING",world.route.POINTS[0])
func _reset_camera():
	view.cinematic=false;view.position=player.position+Vector3(0,1.35,0);view.rotation_degrees=Vector3(-12,0,0);view.camera_rotation=Vector3(-12,0,0);view.camera.position=Vector3(.38,.12,5.1);view.camera.rotation=Vector3.ZERO;view.camera.current=true
func _outro(delta:float):
	outro_clock+=delta;var t=clampf(outro_clock/25,0,1);var base=world.route.POINTS[-1]
	view.camera.global_position=base+Vector3(2,4+t*19,11+t*32);view.camera.look_at(base+Vector3(0,3,-16));player.rotation.y=lerp_angle(player.rotation.y,0,delta*.55)
	var lines=[[.5,"阿木","我们真的翻过来了……"],[5.0,"林川","一路走上来，我都不知道还能不能看到山的另一边。"],[13.0,"周班长","山翻过去了，前面还有路。"]]
	while outro_lines<lines.size() and outro_clock>lines[outro_lines][0]:say(lines[outro_lines][1],lines[outro_lines][2]);outro_lines+=1
	if outro_clock>20:hud.center_title.text="1935年6月，中央红军翻越夹金山。"
	if outro_clock>28 and not audio.voice_busy and audio.voice_queue.is_empty():finish_level()
func clue_found(id:String):
	stats.clues+=1
	match id:
		"route":flags.route_seen=true;say("林川","这里有脚印，绕过岩石，路还往上。")
		"false_route":say("周班长","认准了就发信号，我们在后面接上。")
		"ridge_false":say("林川","这串脚印到断崖就停了，不能走这边。")
		"ridge":flags.ridge_seen=true;say("林川","布条系在背风处，脚印从右边绕过去了。")
func signal_party():
	if stage=="ROUTE_FINDING" and flags.get("route_confirmed",false):
		flags.route_signal=true;stats.signals+=1;_send_party(3,10);_transition("BLIZZARD",world.clues.route.point);say("林川","桥上是同志们掩护我们。这次，我来给大家认路。")
	elif stage=="REUNION" and flags.get("overlook",false):
		flags.reunion_signal=true;stats.signals+=1;_send_party(17,27);_transition("SUMMIT",world.route.POINTS[19]);spatial_voice.stop();say("阿木","林川！这边能看见你了！");say("周班长","把路认准，带大家上去！");say("林川","跟着我，前面就是山口！")
func _send_party(first:int,last:int):
	for i in actors().size():
		var actor=actors()[i];var points=[]
		if actor.moving:
			for j in range(actor.route_index,actor.route.size()):points.append(actor.route[j])
		if first>0:points.append(world.route.POINTS[first-1])
		points.append_array(_party_path(first,last,i));actor.walk(points,2.85+float(i%2)*.08)
func _party_path(first:int,last:int,index:int)->Array:
	var points=[]
	for i in range(first,last+1):
		if i==12:continue
		if i==13 and first<=11:points.append(Vector3(2,48.5,-173))
		var p=world.route.POINTS[i]
		if i==last and i<27:
			var tangent=world.route.nearest(p).tangent
			p-=tangent*float(index/2)*1.3;p+=tangent.cross(Vector3.UP)*(-.3 if index%2 else .3)
		if i==27:p+=Vector3((index%2)*1.4-.7,0,float(index/2)*1.2)
		points.append(p)
	return points
func _gathered()->bool:
	for actor in actors():
		if actor.moving or actor.position.distance_to(world.route.POINTS[-1])>5.5:return false
	return true
func _party_visible()->bool:
	var eye=view.camera.global_position
	for actor in actors():
		var target=actor.position+Vector3.UP*1.3;var delta=target-eye
		if (-view.camera.global_basis.z).dot(delta.normalized())<.65:continue
		var hit=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(eye,target,1))
		if hit.is_empty():return true
	return false
func _distant_call():
	var text="林川——！我们在下面，听见就回一声！";var key=("阿木:"+text).md5_text();var entry=audio.voice_manifest.get(key,{})
	if ResourceLoader.exists(str(entry.get("file",""))):spatial_voice.position=amu.position+Vector3.UP*1.4;spatial_voice.stream=load(entry.file);spatial_voice.play()
func _transition(next:String,safe:Vector3):
	stage=next;safe_point=Vector3(safe.x,world.height_at(safe)+.15,safe.z);camera_observing=false;milestone="";save_checkpoint();print("SNOW_STAGE ",stage," elapsed=",elapsed," position=",player.position)
	if stage=="BLIZZARD":say("阿木","风越来越大了！");say("周班长","靠着岩壁走！别往空地上跑！")
func instruction()->Dictionary:
	match stage:
		"ROUTE_FINDING":
			if not flags.get("route_seen",false):return {"title":"辨认岔路，寻找上行足迹","action":"F 观察脚印、落石与路的走向"}
			if not flags.get("route_confirmed",false):return {"title":"亲自走到脚印延伸的山道","action":"WASD 移动 · 注意右侧上坡的转弯"}
			return {"title":"认准山路，通知队伍跟上","action":"Q 发信号"}
		"BLIZZARD":return {"title":"借岩壁和巨石穿过风口","action":"强风时避风，风缓时前往下一处岩后"}
		"SLOPE_COLLAPSE":return {"title":"撤向左侧岩壁，再找侧路" if flags.get("collapse_triggered",false) else "观察前方积雪险坡","action":"听见落雪立即撤开 · 沿左侧岩壁绕行"}
		"REUNION":return {"title":"在雪脊寻找队伍的踪迹","action":"F 观察脚印与布条 · 看到下方队伍后 Q 呼叫" if not flags.get("overlook",false) else "Q 向下方队伍发信号"}
		"SUMMIT":return {"title":"在垭口等待后面的战友" if flags.get("at_pass",false) else "越过最后险坡，带队登顶","action":"WASD 移动 · 空格越过短裂隙与岩阶 · 等风再走"}
	return {"title":"雪线之上","action":""}
func objective_text()->String:return instruction().title
func interaction_hint()->String:return instruction().action
func waypoint()->Vector3:return Vector3.INF
func chapter_title()->String:return {"INTRO":"第二关 · 雪线之上","ROUTE_FINDING":"山脚 · 前路不明","BLIZZARD":"半山腰 · 风雪突袭","SLOPE_COLLAPSE":"险坡 · 意外发生","REUNION":"雪脊 · 寻找队伍","SUMMIT":"最后的山口","COMPLETE":"第二关完成 · 雪线之上"}.get(stage,"")
func say(who:String,text:String,_duration:=3.3):audio.enqueue_voice(who,text)
func sound(path:String,volume:=-12.0):
	if path=="res://sounds/land.ogg" and player and player.position.y>24:path="res://assets/snow/audio/snow_step.wav"
	super.sound(path,volume)
func save_checkpoint():
	if not started:return
	var data={"version":1,"chapter":"snow","stage":stage,"flags":flags.duplicate(true),"stats":stats.duplicate(true),"position":[safe_point.x,safe_point.y,safe_point.z],"actors":[],"elapsed":elapsed,"retries":retries,"weather_clock":weather.clock,"observed":observation.found.duplicate(true)}
	data["shelters"]=weather.shelter_visits.duplicate(true)
	for actor in actors():data.actors.append(actor.snapshot())
	if save_store.write(data):last_checkpoint=data.duplicate(true)
func continue_story()->bool:
	var data=save_store.read()
	if data.is_empty():return false
	restore_checkpoint(data);return true
func restore_checkpoint(data:Dictionary):
	if map_panel:map_panel.queue_free();map_panel=null
	audio.clear_voice();stage=data.stage;flags=data.flags.duplicate(true);stats=data.stats.duplicate(true);elapsed=float(data.elapsed);retries=int(data.retries);weather.clock=float(data.weather_clock)
	var p=data.position;safe_point=Vector3(p[0],p[1],p[2]);player.restore(safe_point);player.fall_top=safe_point.y;previous_position=player.position
	for i in actors().size():actors()[i].restore_snow(data.actors[i])
	observation.reset();observation.found=data.get("observed",{}).duplicate(true);weather.shelter_visits=data.get("shelters",{}).duplicate(true);world.set_collapsed(flags.get("collapse_triggered",false));started=true;paused=false;failed=false;outro_active=false;camera_observing=false;hud.hide_menu();hud.center_title.text="";_reset_camera();last_checkpoint=data.duplicate(true);Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	if stage=="INTRO":intro_clock=0;intro_lines=0;player.locked=true;view.cinematic=true;_show_route_map()
	if stage=="COMPLETE":_settlement()
func fail(reason:String):
	if failed or stage=="COMPLETE":return
	failed=true;player.locked=true;fail_reason=reason
	hud.show_menu("回到最近的安全位置",reason+"\n\n已辨认的路线和已发生的滑塌会保留。",[["从检查点重试",retry_checkpoint],["返回雪山标题",main_menu]])
func _on_death():fail("失足或受伤，回到最近的避风点。")
func retry_checkpoint():
	var attempts=retries+1;var data=last_checkpoint.duplicate(true)
	if data.is_empty():begin();return
	restore_checkpoint(data);retries=attempts;save_checkpoint()
func _show_route_map():
	if map_panel:map_panel.queue_free()
	map_panel=load("res://game/snow/route_map.gd").new();hud.root_control.add_child(map_panel);map_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func toggle_pause():
	if failed or stage=="COMPLETE":return
	paused=not paused;player.locked=paused or stage=="INTRO" or outro_active
	if paused:save_checkpoint();hud.show_menu("雪线之上 · 暂停","WASD 移动 · Shift 奔跑 · 空格跳跃\nF 观察线索 · Q 发信号\n\n风雪中借岩避风，辨清山路再行动。",[["继续",toggle_pause],["从检查点重试",retry_checkpoint],["操作与画质",settings_menu],["返回雪山标题",main_menu]])
	else:hud.hide_menu();Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
func settings_menu():
	hud.show_menu("操作与画质","画质：%s\n鼠标转动视角；强风时观察雪粒方向，利用岩后避风。"%("高" if high_quality else "性能优先"),[["切换画质",func():high_quality=not high_quality;world.set_quality(high_quality);settings_menu()],["返回",func():paused=false;player.locked=stage=="INTRO" or outro_active;hud.hide_menu() if started else main_menu()]])
func finish_level():
	if stage!="SUMMIT" or not flags.get("reunion_signal",false) or not flags.get("at_pass",false) or not flags.get("crossed_gap_0",false) or not flags.get("crossed_gap_1",false) or not _gathered():return
	stage="COMPLETE";outro_active=false;flags.complete=true;safe_point=world.route.POINTS[-1]+Vector3.UP*.15;save_checkpoint();_settlement()
func _settlement():
	paused=true;player.locked=true;hud.center_title.text=""
	var text="第二关完成：雪线之上。\n\n用时 %02d:%02d · 重试 %d 次\n辨认线索 %d 处 · 发出信号 %d 次\n避风点 %d 处 · 跳跃 %d 次\n同行战友 %d / 4 人抵达\n\n地形距离经过压缩；滑塌地点与人物情节为艺术化虚构。"%[int(elapsed)/60,int(elapsed)%60,retries,int(stats.clues),int(stats.signals),weather.shelter_visits.size(),int(stats.jumps),actors().filter(func(a):return a.position.distance_to(world.route.POINTS[-1])<5.5).size()]
	hud.show_menu("雪线之上",text,[["章节选择",chapter_menu],["下一关 · 接口预留",func():hud.overlay_body.text="第二关已完成。第三关尚未接入，章节管理器已保留入口。"],["返回雪山标题",main_menu],["退出",quit_game]])
func chapter_menu():get_tree().change_scene_to_file("res://game/chapters/main.tscn")
func _start_snow_replay():
	var runner=load("res://qa/snow_replay.gd").new();get_tree().root.add_child(runner);runner.run(self)
func _snow_smoke():
	await get_tree().create_timer(.5).timeout
	print("SNOW_SMOKE ","PASS" if actors().size()==4 and player.visual.skeleton.get_bone_count()==53 and world.terrain!=null else "FAIL")
	get_tree().quit()

func _world_type():return load("res://game/snow/world.gd")
func _hud_type():return load("res://game/snow/hud.gd")
func _audio_type():return load("res://game/snow/audio.gd")
func _npc_type():return load("res://game/snow/npc.gd")
func _visual_type():return load("res://game/remaster/character_visual.gd")
func _weather_type():return load("res://game/snow/weather.gd")

func _player_type():return load("res://game/snow/player.gd")
