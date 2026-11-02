extends "res://game/remaster/campaign.gd"
const Ledger=preload("res://game/v2/objectives.gd")
const V2Store=preload("res://game/v2/save_store.gd")
var ledger=Ledger.new()
var modules:Dictionary={}
var module_states:Dictionary={}
var current_module
var march
var assault
var battlefield
@export var riverbanks: Node3D
var scenery_detail
var vanguard
var vegetation
var simple_repair:=true
var recon
var escort
var repair
var traversal
var relay
var pause_lock:=false
var ending_clock:=0.0
var ending_active:=false
var checkpoint_clock:=0.0
func _init(): save_store=V2Store.new()
func player_type(): return load("res://game/v2/player.gd")
func world_type(): return load("res://game/v2/world.gd")
func hud_type(): return load("res://game/v2/hud.gd")
func modern_type(): return load("res://game/v33/retired_epilogue.gd")
func _ready():
	super._ready()
	process_physics_priority=20
	DisplayServer.window_set_title("飞夺泸定桥 · V3.3")
	for entry in [["observe",KEY_F],["signal",KEY_Q]]:
		if not InputMap.has_action(entry[0]): InputMap.add_action(entry[0])
		var key=InputEventKey.new(); key.physical_keycode=entry[1]; InputMap.action_add_event(entry[0],key)
	for id in ["march","recon","escort","repair","traversal","relay"]:
		var module=load("res://game/v2/"+id+".gd").new()
		module.name="V2_"+id; add_child(module); module.setup(self)
		module.completed.connect(func(result): _module_completed(id,result))
		modules[id]=module
	for label in find_children("*","Label3D",true,false):
		label.font_size=mini(label.font_size,28); label.pixel_size=minf(label.pixel_size,.004); label.visibility_range_end=12
	assault=load("res://game/v2/assault.gd").new(); assault.name="BridgeAssault"; add_child(assault); assault.setup(self)
	battlefield=load("res://game/v31/battlefield.gd").new(); battlefield.name="TwoBankBattlefield"; add_child(battlefield); battlefield.setup(self)
	scenery_detail=load("res://game/v32/environment_detail.gd").new(); scenery_detail.name="EnvironmentDetail"; add_child(scenery_detail); scenery_detail.setup(self)
	vanguard=load("res://game/v33/vanguard.gd").new();vanguard.name="ForwardCoverSquad";add_child(vanguard);vanguard.setup(self)
	vegetation=load("res://game/v33/foliage.gd").new();vegetation.name="LayeredVegetation";add_child(vegetation);vegetation.setup(self)
	march=modules.march; recon=modules.recon; escort=modules.escort; repair=modules.repair; traversal=modules.traversal; relay=modules.relay
	main_menu()
func main_menu():
	if started and not failed: save_checkpoint()
	_stop_modules()
	ending_active=false; ending_clock=0
	if not hud or not modern: return
	super.main_menu()
	var saved_story = save_store.read()
	var finished = not saved_story.is_empty() and saved_story.ledger.current in ["complete", "modern"]
	var actions = []
	if not saved_story.is_empty() and not finished:
		actions.append(["继续故事", continue_story])
	actions.append(["开始新故事", begin])
	if finished:
		actions.append(["查看上次通关结算", continue_story])
	actions.append_array([["章节选择",func():get_tree().change_scene_to_file("res://game/chapters/main.tscn")],["操作与画质",settings_menu],["历史档案与制作说明",archive_menu],["退出",quit_game]])
	var save_note="" if save_store.last_error.is_empty() else "\n\n"+save_store.last_error
	hud.show_menu("飞夺泸定桥","突击在前 · 铺板跟进\n\n突击组先过铁索，两岸火力压制。\n你与阿木跟在后面，将桥板铺到缺口。\n必要时右键放板射击，松开后 E 接着搬。\n\nWASD 移动 · E 铺板 · Tab详情\n角色与战斗调度为艺术化改编。"+save_note,actions)
func _stop_modules():
	if vanguard:vanguard.stop()
	if assault: assault.stop()
	if battlefield: battlefield.stop()
	if audio and audio.has_method("clear_voice"): audio.clear_voice()
	for module in modules.values(): module.stop()
	current_module=null
	if player:
		player.climbing=false; player.carrying=false; player.visual.hand_targets=[]
	for actor in [amu,zhou]+marchers:
		if is_instance_valid(actor): actor.moving=false; actor.fixed_pose=""; actor.visual.hand_targets=[]
func begin(_skip_opening:=false):
	_stop_modules()
	if modern.active: modern.stop()
	if dialogue.active: dialogue.cancel()
	_reset_cast()
	if traversal:
		traversal.start({}); traversal.stop()
	ledger=Ledger.new(); module_states={}; tasks={}; last_checkpoint={}
	started=true; paused=false; failed=false; dialogue_locked=false; interaction_busy=false
	elapsed=0; retries=0; kills=0; choice=0; crossed=false; assisted=false; event=""; ending_active=false
	combat.reset(); player.restore(Vector3(0,.1,45)); player.visual.armed=false
	world.sun.light_color=Color("fff2db")
	_reset_camera(); hud.hide_menu(); hud.hide_dialogue(); hud.hide_modern(); hud.center_title.text=""
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	amu.position=Vector3(.9,0,44); zhou.position=Vector3(-1,0,42)
	amu.walk([Vector3(.9,0,35),Vector3(.9,0,28),Vector3(.9,0,12)],1.8)
	zhou.walk([Vector3(-1,0,34),Vector3(-1,0,15)],1.6)
	for i in marchers.size(): marchers[i].walk([Vector3(-.8+i*1.6,0,20+i)],1.2)
	_activate_current({}); save_checkpoint()
	say("周班长","翻过倒木，取好物资，沿路去观察桥。")
func _process(delta):
	if started and not failed and Input.is_action_just_pressed("pause"): toggle_pause()
	if not started or paused or failed: return
	elapsed+=delta
	if ending_active:
		ending_clock+=delta
		if ending_clock>6 or Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("interact"):
			ending_active=false; hud.center_title.text=""; finish_story()
		return
	if modern.active: return
	if not is_instance_valid(current_module): return
	var module=current_module
	if repair and repair.active and repair.step=="carry" and Input.is_action_pressed("aim"): repair.suspend_carry()
	if Input.is_action_just_pressed("interact"): module.interact()
	
	checkpoint_clock+=delta
	if checkpoint_clock>=12:
		checkpoint_clock=0; save_checkpoint()
func _physics_process(delta):
	if started and not paused and not failed and not ending_active and not modern.active and is_instance_valid(current_module):
		current_module.tick(delta)
	if assault and started and not paused and not failed: assault.tick(delta)
	if vanguard and started and not paused and not failed:vanguard.tick(delta)

func say(who:String,text_value:String,_duration:=3.3):
	if audio and audio.has_method("enqueue_voice"):
		audio.enqueue_voice(who,text_value)
	else: hud.dialogue(who,text_value)

func interact():
	if started and not paused and not failed and is_instance_valid(current_module): current_module.interact()
func _activate_current(state:Dictionary):
	current_module=null
	if recon and recon.cover_body:
		recon.cover_body.visible=ledger.current in ["recon","escort"]
		recon.cover_body.collision_layer=1 if recon.cover_body.visible else 0
	match ledger.current:
		"march": stage="prologue"; phase=Phase.INTRO
		"recon": stage="prepare"; phase=Phase.INTRO
		"escort": stage="combat"; phase=Phase.COMBAT
		"repair": stage="timber"; phase=Phase.COOPERATE
		"traversal": stage="crossing"; phase=Phase.CROSSING
		"relay": stage="reunion"; phase=Phase.ENDING
		"complete": finish_story();return
	for actor in [player,zhou]+enemies: actor.visual.armed=ledger.current=="escort"
	if modules.has(ledger.current):
		current_module=modules[ledger.current]
		var data=state.duplicate(true)
		if ledger.current=="escort" and data.is_empty(): data={"route":module_states.get("recon",{}).get("route","A")}
		if ledger.current=="traversal" and module_states.get("repair",{}).get("rope_assist",false):
			player.balance_assist=true
		current_module.start(data)
	if assault and ledger.current in ["repair","traversal","relay"]:
		assault.start()
		if vanguard:vanguard.start()
func _module_completed(id:String,result:Dictionary):
	if ledger.current!=id or not started or failed: return
	module_states[id]=result.duplicate(true)
	if not ledger.finish(id): return
	modules[id].stop(); player.locked=false; player.visual.hand_targets=[]
	if id=="recon": choice=1 if result.get("route","A")=="B" else 0
	if id=="escort":
		combat.reloading=false; combat.reset()
		for actor in [player,zhou]+enemies: actor.visual.armed=false
		say("阿木","物资送到了。挑好木板，我们一起修。")
	if id=="repair":
		amu.walk([Vector3(0,0,-30.7),Vector3(.4,0,-53.2)],2)
		zhou.walk([Vector3(0,0,-11.5),Vector3(0,0,-30.7),Vector3(-.4,0,-53.1)],2)
	if id=="traversal":
		crossed=true
		for actor in [amu,zhou]: actor.walk([Vector3(1.43,0,-58.2),Vector3(1.43,0,-62.4),Vector3(-.6 if actor==amu else .6,0,-70)],2.5)
	if id=="relay":
		current_module=null; stage="reunion"; ending_active=true; ending_clock=0
		player.locked=true; hud.center_title.text="桥头已夺下，后续部队正在通过。\n\nSpace / E 继续 · 6秒"
		say("周班长","通道接上了。走，后面的人还等着呢。")
		save_checkpoint(); return
	_activate_current(module_states.get(ledger.current,{})); save_checkpoint()
func current_status()->Dictionary:
	if is_instance_valid(current_module): return current_module.status()
	return {"objective":"通道已打通","hint":"","progress":1.0,"detail":"","waypoint":Vector3.INF}
func objective_text()->String: return str(current_status().get("objective",""))
func interaction_hint()->String:
	if not started or paused: return ""
	return str(current_status().get("hint",""))
func waypoint()->Vector3: return current_status().get("waypoint",Vector3.INF)
func chapter_title()->String:
	return {"march":"序章 · 山路接应","recon":"第一章 · 观察与选路","escort":"第二章 · 压制接应","repair":"第三章 · 两处缺板","traversal":"第四章 · 迎风攀索","relay":"第五章 · 引绳接应","modern":"尾声 · 2026数字重建","complete":"道路相连，记忆相续"}.get(ledger.current,"")
func _enemy_defeated():
	kills=0
	for enemy in enemies:
		if enemy.dead: kills+=1
func on_chain_finished(): pass
func save_checkpoint():
	if not started or not player or modules.is_empty(): return
	if is_instance_valid(current_module): module_states[ledger.current]=current_module.snapshot()
	var pos=player.position
	if ledger.current=="repair" and repair.step in ["carry","join","npc_ready","lifting","lowering","recover","align","secure","place_check","parked","preparing","auto_secure"]: pos=repair.safe_position()
	if ledger.current=="traversal": pos=traversal.safe_position()
	if ledger.current=="modern" or ledger.current=="complete": pos=Vector3(0,.1,-80.5)
	var data={"version":3,"ledger":ledger.snapshot(),"modules":module_states.duplicate(true),"position":[pos.x,pos.y,pos.z],"elapsed":elapsed,"retries":retries,"choice":choice,"ammo":combat.ammo,"reserve":combat.reserve,"assault":assault.snapshot() if assault else {}}
	data["vanguard"]=vanguard.snapshot() if vanguard else {}
	if save_store.write(data): last_checkpoint=data.duplicate(true)
	else: say("存档",save_store.last_error)
func continue_story()->bool:
	var data=save_store.read()
	if data.is_empty(): return false
	_apply_snapshot(data); return true
func _apply_snapshot(data:Dictionary):
	_stop_modules()
	if modern.active: modern.stop()
	_reset_cast(); ledger=Ledger.new()
	if not ledger.restore(data.get("ledger",{})): return
	module_states=data.get("modules",{}).duplicate(true)
	elapsed=float(data.get("elapsed",0)); retries=int(data.get("retries",0)); choice=int(data.get("choice",0)); event=""
	started=true; paused=false; failed=false; interaction_busy=false; dialogue_locked=false; ending_active=false
	var pos=data.position; player.restore(Vector3(float(pos[0]),float(pos[1]),float(pos[2])))
	combat.reset(); combat.ammo=clampi(int(data.get("ammo",5)),0,5); combat.reserve=clampi(int(data.get("reserve",30)),0,999)
	var repaired=module_states.get("repair",{}).get("repaired",[false,false])
	for i in 2: world.set_v2_repair(i,repaired is Array and repaired.size()>i and bool(repaired[i]))
	if ledger.current in ["traversal","relay","modern","complete"]:
		amu.position=Vector3(.4,0,-53.1); zhou.position=Vector3(-.4,0,-53.1)
	if ledger.current in ["relay","modern","complete"]:
		traversal.start({"checkpoint":2,"fixed":true}); traversal.stop()
		amu.position=Vector3(-.6,0,-70); zhou.position=Vector3(.6,0,-70)
	_reset_camera(); hud.hide_menu(); hud.hide_dialogue(); hud.hide_modern(); hud.center_title.text=""
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	last_checkpoint=data.duplicate(true)
	_activate_current(module_states.get(ledger.current,{}))
	if assault and assault.active: assault.restore(data.get("assault",{}))
	if vanguard and vanguard.active:vanguard.restore(data.get("vanguard",{}))
func retry_checkpoint():
	var attempts=retries+1
	var data=last_checkpoint.duplicate(true) if not last_checkpoint.is_empty() else save_store.read()
	if data.is_empty(): begin(true)
	else: _apply_snapshot(data)
	retries=attempts; save_checkpoint()
func _on_death():
	failed=true; player.locked=true; combat.reloading=false
	hud.show_menu("回到最近的安全位置","已完成的修复和观察会保留。\n搬运中断后，木板回到当前备料点；铁索中断后回到最近支点。",[["从检查点重试",retry_checkpoint],["返回标题",main_menu],["退出",quit_game]])
func toggle_pause():
	if not paused:
		pause_lock=player.locked; paused=true; player.locked=true; save_checkpoint()
		hud.show_menu("暂停 · V3.3","F 观察 · Q 发信号 · E 交互 / 按住固定\nA/D 对齐或控制平衡 · Space 检查 · 搬板时 R 取消\n\n操作失败可以重试；到标题后可继续安全检查点。",[["继续",toggle_pause],["操作与画质",settings_menu],["历史档案",archive_menu],["从检查点重试",retry_checkpoint],["返回标题",main_menu]])
	else:
		paused=false; player.locked=pause_lock; hud.hide_menu()
		Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if modern.active else Input.MOUSE_MODE_CAPTURED
func _back_menu():
	if started:
		paused=true; toggle_pause()
	else: main_menu()
func settings_menu():
	if started and not paused: pause_lock=player.locked
	super.settings_menu()
	hud._button(hud.buttons,"精细修桥："+("开" if not simple_repair else "关（默认快捷铺板）"),func(): simple_repair=not simple_repair; settings_menu())
	hud._button(hud.buttons,"切换铁索辅助："+("开" if player.balance_assist else "关"),func(): player.balance_assist=not player.balance_assist; settings_menu())
func start_modern(_state:Dictionary={}):
	finish_story()
func finish_modern():
	finish_story()
func finish_story():
	if ledger.current!="complete":return
	stage="complete";phase=Phase.ENDING;ending_active=false;current_module=null
	if modern:modern.stop()
	hud.hide_modern();hud.center_title.text="";player.locked=true;player.carrying=false;player.climbing=false
	if battlefield:battlefield.stop()
	if vanguard:vanguard.stop()
	if assault:assault.stop()
	save_checkpoint();pause_lock=true;paused=true
	var duration="%02d:%02d"%[floori(elapsed / 60.0),int(elapsed)%60]
	hud.show_menu("飞夺泸定桥 · 通道已打通","V3.3 故事完成\n\n用时 %s · 重试 %d 次\n前方掩护 · 协作铺板 · 铁索突进 · 接应后续部队\n\n铭记牺牲的同志，向夺桥英雄致敬。\n林川、阿木、周班长为虚构人物。"%[duration,retries],[["继续第二关 · 雪线之上",func():get_tree().change_scene_to_file("res://game/snow/main.tscn")],["返回标题",main_menu],["退出",quit_game]])
func _start_release_replay():
	if ResourceLoader.exists("res://qa/v2_replay.gd"):
		var runner=load("res://qa/v2_replay.gd").new(); get_tree().root.add_child(runner); runner.run(self)
func _export_smoke():
	await get_tree().create_timer(1).timeout
	var valid=player.visual.skeleton.get_bone_count()==53 and modules.size()==6 and world.v2_gaps.size()==2 and vanguard.fighters.size()==2 and not modern.active and hud.overlay.visible
	valid=valid and audio.voice_manifest.size()>=47
	for entry in audio.voice_manifest.values():
		valid=valid and ResourceLoader.exists(entry.file) and load(entry.file).get_length()>.3
	audio.enqueue_voice("林川","同志，过来搭把手！")
	await get_tree().create_timer(.3).timeout
	valid=valid and audio.voice.playing and hud.bark_label.text=="林川：同志，过来搭把手！"
	print("V2 EXPORT SMOKE ","PASS" if valid else "FAIL", " voices=",audio.voice_manifest.size()," playback=",audio.voice.playing)
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw(false)
		get_viewport().get_texture().get_image().save_png(OS.get_executable_path().get_base_dir().path_join("v2_export_smoke.png"))
	for node in find_children("*","AudioStreamPlayer",true,false): node.stop(); node.stream=null
	# Allow the audio mixer to release stopped WAV playbacks before teardown.
	await get_tree().create_timer(0.35).timeout
	get_tree().quit(0 if valid else 1)
