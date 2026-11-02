extends "res://game/mission.gd"
const SaveStore=preload("res://game/remaster/save_store.gd")
var dialogue
var director
var audio
var modern
var save_store=SaveStore.new()
var choice := 0
var skipped_dialogues := 0
var stage := "prologue"
var tasks: Dictionary={}
var event := ""
var event_time := 0.0
var last_checkpoint: Dictionary={}
var high_quality := true
var master_volume := .8
var brace_start := Vector3.ZERO
var marchers: Array=[]

func character_type(): return preload("res://game/remaster/character_visual.gd")
func hud_type(): return preload("res://game/remaster/hud.gd")
func world_type(): return preload("res://game/remaster/world.gd")
func modern_type(): return load("res://game/remaster/modern.gd")

func _ready():
	super._ready()
	director=load("res://game/remaster/shot_director.gd").new()
	director.mission=self
	add_child(director)
	audio=load("res://game/remaster/audio.gd").new()
	audio.mission=self
	add_child(audio)
	dialogue=load("res://game/remaster/dialogue.gd").new()
	dialogue.mission=self
	add_child(dialogue)
	dialogue.finished.connect(_dialogue_finished)
	modern=modern_type().new()
	modern.mission=self
	add_child(modern)
	for i in 2:
		var marcher=_actor("Marcher%d"%i,Vector3(-.8+i*1.6,0,35+i*2),false)
		marchers.append(marcher)
	player.chain_from=-54.5
	player.chain_to=-62.2
	player.chain_duration=14.0
	combat.max_range=130
	combat.enemy_range=130
	combat.aim_assist=true
	combat.enemy_damage=3
	view.aim_fov=36
	view.camera.far=600
	for actor in [amu,zhou]:
		actor.chain_from=-54.8
		actor.chain_to=-62.2
	for i in enemies.size():
		enemies[i].position=Vector3(-1.30 if i==0 else 1.30,0,-80.9)
		enemies[i].start_position=enemies[i].position
		enemies[i].mobile_cover=true
	# A soft camera-side fill preserves facial readability in authored dialogue.
	var fill=OmniLight3D.new()
	fill.light_color=Color("b7d2df")
	fill.light_energy=.28
	fill.omni_range=9
	view.camera.add_child(fill)
	load_settings()
	main_menu()
	if "--verify-replay" in OS.get_cmdline_user_args(): call_deferred("_start_release_replay")

func _start_release_replay():
	var runner=load("res://qa/replay_controller.gd").new()
	get_tree().root.add_child(runner)
	runner.run(self)

func main_menu():
	if dialogue: dialogue.cancel()
	started=false
	paused=false
	player.locked=true
	if modern.active: modern.stop()
	director.landscape(Vector3(-24,10,11),Vector3(0,-1,-30),52)
	var actions=[]
	if save_store.exists(): actions.append(["继续故事",continue_story])
	actions.append_array([["开始新故事",begin],["操作与画质",settings_menu],["历史档案与制作说明",archive_menu],["退出",quit_game]])
	hud.show_menu("万水千山：战火中的木板","1935 · 大渡河\n\n一块木板，连接来路与前方。\n\n序章＋三个主线章节＋2026数字重建尾声\n\n林川、阿木、周班长均为虚构人物。\n故事以普通战士的协作为视角，向真实的夺桥英雄致敬。",actions)

func _reset_cast():
	for actor in [amu,zhou]+enemies:
		actor.restore()
		actor.show()
	player.show()
	world.reset_board()
	world.support_rope.hide()
	if world.modern_deck: world.modern_deck.hide()
	world.sun.light_energy=1.15
	world.environment.fog_density=.0017
	amu.position=Vector3(.9,0,28.0)
	zhou.position=Vector3(-1.5,0,27.2)
	amu.rotation.y=PI
	zhou.rotation.y=PI
	for actor in [amu,zhou,enemies[0],enemies[1]]: actor.visual.armed=false
	for i in marchers.size():
		marchers[i].restore()
		marchers[i].show()
		marchers[i].position=Vector3(-.8+i*1.6,0,35+i*2)

func begin(skip_opening := false):
	if dialogue.active: dialogue.close(true)
	if modern.active: modern.stop()
	_reset_cast()
	started=true
	paused=false
	failed=false
	phase=Phase.INTRO
	stage="prologue"
	tasks={}
	elapsed=0
	retries=0
	kills=0
	choice=0
	crossed=false
	assisted=false
	event=""
	combat.reset()
	player.restore(Vector3(0,.1,30.8))
	player.visual.armed=false
	_reset_camera()
	hud.hide_menu()
	hud.hide_dialogue()
	hud.hide_modern()
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	for i in marchers.size(): marchers[i].walk([Vector3(-.8+i*1.6,0,22+i)],1.15)
	save_checkpoint()
	if not skip_opening: _start_event("opening")

func _reset_camera():
	director.active=false
	director.returning=false
	view.position=player.position+Vector3(0,1.35,0)
	view.rotation=Vector3.ZERO
	view.camera_rotation=Vector3(-12,0,0)
	view.camera.position=Vector3(.38,.12,4.6)
	view.camera.rotation=Vector3.ZERO
	view.camera.current=true
	view.cinematic=false

func _process(delta):
	if started and not failed and Input.is_action_just_pressed("pause"): toggle_pause()
	if not started or paused or failed: return
	elapsed+=delta
	if not event.is_empty():
		_event_tick(delta)
		return
	if modern.active: return
	if dialogue.active: return
	if Input.is_action_just_pressed("interact"): interact()
	if interaction_busy:
		match stage:
			"brace": _brace_tick(delta)
			"timber": _pickup_tick(delta)
			"carrying": _place_tick(delta)
	if stage=="crossing" and crossed and player.position.z<-75 and not amu.moving and not zhou.moving:
		stage="reunion"
		phase=Phase.ENDING
		save_checkpoint()
		say("阿木","林川！我在桥亭这边！")
	if stage=="crossing" and not crossed and not player.climbing:
		if player.position.z<-35 and not tasks.get("chain_warning",false):
			tasks["chain_warning"]=true
			say("周班长","看前面，缺板的地方靠右抓索。一步一步来。")

func interact():
	if dialogue.active or interaction_busy or failed or paused or not started: return
	match stage:
		"prologue":
			if _near(zhou.position): dialogue.start("prologue")
			elif _near(Vector3(-2,0,28)):
				tasks["supply"]=true
				dialogue.start("supply")
		"approach":
			if _near(Vector3(0,0,16)):
				tasks["lookout"]=true
				_start_event("bridge_reveal")
			elif _near(Vector3(-2,0,28)) and not tasks.get("supply",false):
				tasks["supply"]=true
				dialogue.start("supply")
		"prepare":
			if _near(_preparation_point()):
				tasks["prepared"]=true
				if choice==0: _start_event("survey")
				else: dialogue.start("timber_check")
			elif _near(amu.position): dialogue.start("amu_optional")
			elif _near(Vector3(-3,0,5.5)): archive_menu()
		"signal":
			if _near(zhou.position): dialogue.start("signal")
		"combat":
			if _near(Vector3(-4.2,0,3.3)):
				combat.reserve=30
				player.health=mini(100,player.health+20)
				say("林川","补好弹药，再看清对岸。")
		"brace":
			if _near(Vector3(2.8,0,3)):
				interaction_busy=true
				action_time=0
				brace_start=player.position
				player.locked=true
				player.visual.mode="brace"
				amu.fixed_pose="brace"
				director.landscape(Vector3(5.6,2.3,5.3),Vector3(3.1,1.0,3),46)
		"timber", "carrying": super.interact()
		"crossing":
			if not crossed and not player.climbing and _near(Vector3(1.43,0,-54.5),1.7):
				player.start_climb()
				say("阿木","我在这边看着你。手抓稳，偏了就往反方向调！")
		"reunion":
			if _near(amu.position,3): dialogue.start("reunion")

func _near(point: Vector3,distance := 2.5) -> bool: return player.position.distance_to(point)<distance
func _preparation_point() -> Vector3: return Vector3(0,0,1.7) if choice==0 else Vector3(3,0,3)

func _start_event(event_name: String):
	event=event_name
	event_time=0
	player.locked=true
	player.visual.mode="idle"
	director.enter()
	if event=="opening":
		hud.center_title.text="山 河 有 声\n1935 · 大渡河"
		director.landscape(Vector3(-28,5,-19),Vector3(0,-3,-39),55)
	elif event=="bridge_reveal":
		hud.center_title.text="第一章  铁索横江"
		director.landscape(Vector3(-18,7,5),Vector3(0,-1,-35),52)
	elif event=="survey":
		hud.center_title.text="观察桥面 · 找出安全的路线"
		director.landscape(Vector3(4,3,-5),Vector3(0,0,-10),42)
	elif event=="after_bridge":
		hud.center_title.text="路还长着呢。"
		director.landscape(Vector3(-6,3,-84),Vector3(0,1,-77),48)

func _event_tick(delta):
	event_time+=delta
	var skip=Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("jump")
	match event:
		"opening":
			if event_time>3.5: director.landscape(Vector3(-4,2.7,33),Vector3(0,1,27),44)
			if event_time>7 or skip: _end_event()
		"bridge_reveal":
			if event_time>3: director.landscape(Vector3(-7,2,-25),Vector3(0,1,-75),50)
			if event_time>6.5 or skip:
				_end_event()
				dialogue.start("bridge")
		"survey":
			if event_time>4 or skip:
				_end_event()
				dialogue.start("survey")
		"after_bridge":
			director.landscape(Vector3(-6-event_time*2.2,3+event_time*1.1,-84+event_time*2.2),Vector3(0,0,-39),48)
			if event_time>7 or skip:
				_end_event()
				start_modern()

func _end_event():
	event=""
	hud.center_title.text=""
	player.locked=false
	director.leave()

func _brace_tick(delta):
	action_time+=delta
	player.position=brace_start.lerp(Vector3(2.8,0,3.6),clampf(action_time/.5,0,1))
	player.rotation.y=PI
	amu.position=amu.position.move_toward(Vector3(2.8,0,2.4),delta*2)
	amu.face(Vector3(2.8,0,4))
	amu.moving=false
	world.support.rotation.z=lerpf(world.support.rotation.z,0,minf(delta*4,1))
	world.support_rope.visible=action_time>1
	world.support_rope.scale=Vector3.ONE*clampf((action_time-1)/1.8,.05,1)
	player.visual.hand_targets=[Vector3(2.65,.83,3.15),Vector3(2.95,.83,3.15)]
	var tying=clampf((action_time-.8)*2,0,1)
	var loop=action_time*5.4
	amu.visual.hand_targets=[Vector3(2.66+sin(loop)*.045*tying,.84+cos(loop)*.035*tying,2.86),Vector3(2.94,.84+sin(loop+.8)*.018*tying,2.87+cos(loop)*.025*tying)]
	if action_time>=4.0:
		tasks["brace"]=true
		world.support_rope.scale=Vector3.ONE
		interaction_busy=false
		player.locked=false
		player.visual.hand_targets=[]
		amu.visual.hand_targets=[]
		amu.fixed_pose=""
		stage="timber"
		phase=Phase.PICKUP
		director.leave()
		amu.walk([Vector3(1.5,0,2.5)],1.4)
		sound("res://assets/audio/wood.wav",-16)
		save_checkpoint()
		say("阿木","横档固定好了！现在可以抬板。我扶后端，你托住前面。")

func _pickup_tick(delta):
	super._pickup_tick(delta)
	if not interaction_busy:
		stage="carrying"
		amu.visual.armed=false

func _place_tick(delta):
	if action_time==0: director.landscape(Vector3(3,2.1,-6.8),Vector3(0,.7,-9),48)
	super._place_tick(delta)
	if not interaction_busy:
		stage="crossing"
		tasks["laid"]=true
		director.leave()
		amu.walk([Vector3(0,0,-11.4),Vector3(-.6,0,-20),Vector3(-.6,0,-53.5)],2.4)
		zhou.walk([Vector3(0,0,0),Vector3(0,0,-11.5),Vector3(.55,0,-53.3)],2.5)
		save_checkpoint()
		dialogue.start("after_repair")

func _enemy_defeated():
	kills=0
	for enemy in enemies:
		if enemy.dead: kills+=1
	if kills==enemies.size() and stage=="combat":
		stage="brace"
		phase=Phase.PICKUP
		checkpoint=Phase.PICKUP
		combat.reloading=false
		for actor in [player,amu,zhou]+enemies: actor.visual.armed=false
		amu.walk([Vector3(3.7,0,3)],1.7)
		zhou.fixed_pose="idle"
		save_checkpoint()
		call_deferred("_post_combat")

func _post_combat():
	amu.walk([Vector3(player.position.x+1.2,0,player.position.z+.2)],2.0)
	var waited=0.0
	while amu.moving and waited<6:
		await get_tree().create_timer(.1).timeout
		waited+=.1
	if not failed and stage=="brace": dialogue.start("after_combat")

func on_chain_finished():
	crossed=true
	tasks["crossed"]=true
	amu.walk([Vector3(1.43,0,-54.5),Vector3(1.43,0,-62.3),Vector3(-.75,0,-78.9)],2.6)
	zhou.walk([Vector3(1.43,0,-54.5),Vector3(1.43,0,-62.3),Vector3(.8,0,-79.0)],2.8)
	say("阿木","过去了！我这就跟上，你先向桥亭走！")

func _dialogue_finished(key: String):
	match key:
		"prologue":
			stage="approach"
			amu.walk([Vector3(.7,0,17)],1.6)
			zhou.walk([Vector3(-1.1,0,16)],1.5)
			say("阿木","沿山路往前，有个能看清桥的地方。")
		"bridge":
			stage="prepare"
			amu.walk([Vector3(2.9,0,4)],1.9)
			zhou.walk([Vector3(-2,0,4.7)],1.8)
			say("周班长","突击队已经向前。我们做好接应，把后续的路铺牢。")
		"survey", "timber_check":
			stage="signal"
			say("周班长","准备妥当就来找我。不要急，先看清。")
		"signal":
			stage="combat"
			phase=Phase.COMBAT
			checkpoint=Phase.COMBAT
			for actor in [player,zhou]+enemies: actor.visual.armed=true
			amu.walk([Vector3(3.7,0,3)],1.8)
			hud.dialogue("周班长","掩护！利用桥头掩体，右键瞄准，R 装填。")
		"after_combat":
			amu.walk([Vector3(2.8,0,2.4)],1.7)
		"after_repair":
			amu.walk([Vector3(0,0,-11.4),Vector3(-.6,0,-53.5)],2.4)
			zhou.walk([Vector3(0,0,-11.5),Vector3(.55,0,-53.3)],2.5)
		"reunion": _start_event("after_bridge")
	if key not in ["amu_optional","supply"]: save_checkpoint()

func actor_by_name(who: String):
	if who=="阿木": return amu
	if who=="周班长": return zhou
	return player
func dialogue_partner(): return zhou if stage in ["prologue","signal"] else amu
func chapter_title() -> String:
	if stage in ["prologue","approach"]: return "序章  /  山河有声"
	if stage in ["prepare","signal"]: return "第一章  /  铁索横江"
	if stage in ["reunion"]: return "第三章  /  渡尽天险"
	if stage in ["modern","complete"]: return "尾声  /  九十年后的回答 · 2026"
	return "第二章  /  战火中的木板"
func waypoint() -> Vector3:
	match stage:
		"prologue", "signal": return zhou.position+Vector3(0,1.9,0)
		"approach": return Vector3(0,1.9,16)
		"prepare": return _preparation_point()+Vector3(0,1.5,0)
		"combat":
			for enemy in enemies:
				if not enemy.dead: return enemy.position+Vector3(0,2,0)
		"brace": return Vector3(2.8,1.9,3)
		"timber": return world.board_start+Vector3(0,1.5,0)
		"carrying": return Vector3(0,1.5,-7.9)
		"crossing": return Vector3(0,1.8,-78) if crossed else Vector3(1.43,1.8,-54.5)
		"reunion": return amu.position+Vector3(0,1.9,0)
	return Vector3.INF
func objective_text() -> String:
	match stage:
		"prologue": return "与周班长交谈 · 可检查路边物资"
		"approach": return "跟随战友，抵达观察点"
		"prepare": return "观察桥面缺口" if choice==0 else "与阿木检查木板"
		"signal": return "与周班长确认行动"
		"combat": return "掩护铺桥的战友 · 压制火力 %d / 2"%kills
		"brace": return "与阿木稳住物资横档"
		"timber": return "托起已经加固的木板"
		"carrying": return "搬运木板，与阿木协作铺设"
		"crossing": return "通过铁索，等候战友" if not crossed else "前往对岸桥亭，与战友会合"
		"reunion": return "走近阿木，确认大家平安"
		"modern": return "采集三个观察点 · 查看数字结构"
		"complete": return "故事完成 · 记忆仍在延续"
	return ""
func interaction_hint() -> String:
	if not started or dialogue_locked or paused: return ""
	if not event.is_empty(): return "空格 / E  跳过镜头"
	if interaction_busy: return "稳住横档 · 阿木正在绑扎" if stage=="brace" else "与战友协作中…"
	match stage:
		"prologue":
			if _near(zhou.position): return "E  与周班长交谈"
			if _near(Vector3(-2,0,28)): return "E  检查行军物资"
		"approach":
			if _near(Vector3(0,0,16)): return "E  观察泸定桥"
			if _near(Vector3(-2,0,28)) and not tasks.get("supply",false): return "E  检查物资"
		"prepare":
			if _near(_preparation_point()): return "E  查看桥面与路线" if choice==0 else "E  检查木板与裂口"
			if _near(amu.position): return "E  与阿木交谈"
			if _near(Vector3(-3,0,5.5)): return "E  查看历史档案"
		"signal":
			if _near(zhou.position): return "E  准备好了"
		"combat":
			if _near(Vector3(-4.2,0,3.3)): return "E  补给弹药与体力"
			return "利用掩体 · 右键精确瞄准 · 左键射击 · R 装填"
		"brace":
			if _near(Vector3(2.8,0,3)): return "E  按住横档，配合阿木绑扎"
		"timber":
			if _near(world.board_start,2): return "E  托起木板"
		"carrying":
			if _near(Vector3(0,0,-7.9),1.65): return "等阿木就位" if amu.moving else "E  与阿木一起铺板"
			return "沿桥面搬运 · 靠近缺口前停下"
		"crossing":
			if player.climbing: return "W / S 前后移动 · A / D 反向调整平衡"
			if not crossed and _near(Vector3(1.43,0,-54.5),1.7): return "E  抓住右侧铁索"
			return "向桥亭前进，等候战友" if crossed else "沿木板中间前进 · 前方缺板处靠右抓索"
		"reunion":
			if _near(amu.position,3): return "E  阿木，你没事吧？"
	return "沿 ◇ 目标前进 · Esc 暂停 / 设置 / 档案"
func say(who: String,text_value: String,_duration := 3.3): hud.dialogue(who,text_value)

func save_checkpoint():
	if interaction_busy or player.climbing: return
	var safe_stage=stage
	var pos=player.position
	if stage=="carrying":
		safe_stage="timber"
		pos=Vector3(1.3,.1,3)
	if stage=="crossing" and not crossed: pos=Vector3(.8,.1,-52.8)
	var snapshot={"stage":safe_stage,"tasks":tasks.duplicate(true),"choice":choice,"elapsed":elapsed,"retries":retries,"kills":kills,"crossed":crossed,"assisted":assisted,"position":[pos.x,pos.y,pos.z],"repair":world.repair_enabled,"version":2}
	last_checkpoint=snapshot.duplicate(true)
	if not save_store.write(snapshot): say("存档",save_store.last_error)

func continue_story() -> bool:
	var snapshot=save_store.read()
	if snapshot.is_empty(): return false
	_apply_snapshot(snapshot)
	return true

func _apply_snapshot(snapshot: Dictionary):
	if dialogue.active:
		dialogue.active=false
		dialogue.loading=false
	_reset_cast()
	stage=snapshot.stage
	tasks=snapshot.tasks.duplicate(true)
	choice=int(snapshot.get("choice",0))
	elapsed=float(snapshot.get("elapsed",0))
	retries=int(snapshot.get("retries",0))
	kills=int(snapshot.get("kills",0))
	crossed=snapshot.get("crossed",false)
	assisted=snapshot.get("assisted",false)
	started=true
	failed=false
	paused=false
	dialogue_locked=false
	interaction_busy=false
	event=""
	hud.center_title.text=""
	var pos=snapshot.position
	hud.bark_label.text=""
	hud.bark_time=0
	player.restore(Vector3(float(pos[0]),float(pos[1]),float(pos[2])))
	combat.reset()
	phase=Phase.INTRO
	if stage=="combat": phase=Phase.COMBAT
	elif stage in ["brace","timber"]: phase=Phase.PICKUP
	elif stage=="crossing": phase=Phase.CROSSING
	elif stage in ["reunion","modern","complete"]: phase=Phase.ENDING
	if snapshot.get("repair",false):
		world.board.position=world.board_final
		world.enable_repair()
	world.support_rope.visible=tasks.get("brace",false)
	world.support_rope.scale=Vector3.ONE
	if kills==2:
		for enemy in enemies:
			enemy.dead=true
			enemy.collision_layer=0
			enemy.visual.mode="dead"
	if stage not in ["prologue","approach"]:
		amu.position=Vector3(3.7,0,3)
		zhou.position=Vector3(-2,0,4.7)
	if stage=="crossing":
		amu.position=Vector3(-.6,0,-53.5) if not crossed else Vector3(-.75,0,-78.9)
		zhou.position=Vector3(.55,0,-53.3) if not crossed else Vector3(.8,0,-79)
	if stage=="reunion":
		amu.position=Vector3(-.75,0,-78.9)
		zhou.position=Vector3(.8,0,-79)
	if stage=="approach":
		amu.walk([Vector3(.7,0,17)])
		zhou.walk([Vector3(-1.1,0,16)])
	for actor in [player,zhou]+enemies: actor.visual.armed=stage=="combat"
	_reset_camera()
	hud.hide_menu()
	hud.hide_dialogue()
	hud.hide_modern()
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	last_checkpoint=snapshot.duplicate(true)
	if stage in ["modern","complete"]: start_modern()

func retry_checkpoint():
	var attempts=retries+1
	var snapshot=last_checkpoint if not last_checkpoint.is_empty() else save_store.read()
	if snapshot.is_empty():
		begin(true)
	else: _apply_snapshot(snapshot)
	retries=attempts
	save_checkpoint()

func restart(): begin()

func _on_death():
	failed=true
	combat.reloading=false
	hud.show_menu("歇一口气，再出发","最近的安全进度已保存。\n\n铁索上按 W 前进，A / D 向倾斜的反方向调整。\n回到检查点会补满体力，已铺木板和剧情选择会保留。",[["从检查点重试",retry_checkpoint],["返回标题",main_menu],["退出",quit_game]])

func toggle_pause():
	paused=not paused
	player.locked=paused or dialogue.active or interaction_busy or not event.is_empty() or modern.active
	if paused:
		hud.show_menu("暂停 · 路上稍歇","WASD 移动 · Shift 奔跑 · 鼠标转动视角\nE 交互 · 空格跳跃\n右键瞄准 · 左键射击 · R 装填\n铁索：W / S 前后，A / D 反向调整平衡\n\n对话可手动推进、自动播放或跳过本段。",[["继续",toggle_pause],["操作与画质",settings_menu],["历史档案",archive_menu],["从检查点重试",retry_checkpoint],["返回标题",main_menu]])
	else:
		hud.hide_menu()
		Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if modern.active or dialogue.active else Input.MOUSE_MODE_CAPTURED

func _back_menu():
	if started:
		paused=true
		toggle_pause()
	else: main_menu()

func settings_menu():
	if started:
		paused=true
		player.locked=true
	hud.show_menu("操作与画质","画质：%s\n瞄准辅助：%s（仅在准星靠近目标时生效）\n主音量：%d%%\n鼠标灵敏度：%.1f\n\n画质切换即时生效并保存在本机。\n高画质使用环境遮蔽与薄雾，性能模式降低渲染分辨率。"%["高" if high_quality else "性能优先","开" if combat.aim_assist else "关",int(master_volume*100),view.sensitivity],[["切换画质",func(): high_quality=not high_quality; world.set_quality(high_quality); save_settings(); settings_menu()],["切换瞄准辅助",func(): combat.aim_assist=not combat.aim_assist; save_settings(); settings_menu()],["调整音量",func(): master_volume=fmod(master_volume+.2,1.1); apply_volume(); save_settings(); settings_menu()],["调整灵敏度",func(): view.sensitivity=.5 if view.sensitivity>=1.5 else view.sensitivity+.25; save_settings(); settings_menu()],["返回",_back_menu]])

func archive_menu():
	if started:
		paused=true
		player.locked=true
	hud.show_menu("历史档案 · 路与记忆","[b]1935年5月29日[/b]\n红四团的22名突击队员攀索向前，后续部队一边铺设桥板一边前进，夺取泸定桥，为中央红军北上打开通道。\n\n[b]十三根铁索[/b]\n九根底索承托桥面，两侧各两根扶索。史实桥长约103米，本作采用78米的艺术化可玩跨度与放大的链环。\n\n[b]三个虚构人物[/b]\n林川、阿木、周班长代表普通战士的协作视角，不是22名突击队员的姓名或传记。两处火力点、修板和攀索路线是玩法改编。\n\n[b]2026：数字记录[/b]\n尾声是低空观察与结构建模的教学模拟，使用艺术场景，不是实际测绘数据。从1935至2026相隔91年，篇名“九十年后的回答”是文学表达。\n\n[b]史料[/b]\n中国军网《飞夺泸定桥场景》（2016-09-21）；泸定桥景区官网“关于我们”。完整链接、素材许可证与改编边界见随包文档。\n\n[b]制作[/b]\nGodot 4.6 · MPFB自然比例人物 · CC0服装改制\nDialogue Manager 4 · 实时3D演出\n中文男性神经合成配音，逐句设置语境与情绪。\n桥上战友受击、坠河与通过数量为非血腥的玩法演出，不对应具体烈士身份或史实伤亡数字。",[["返回",_back_menu]])

func save_settings():
	var config=ConfigFile.new()
	config.set_value("video","high",high_quality)
	config.set_value("audio","master",master_volume)
	config.set_value("controls","sensitivity",view.sensitivity)
	config.set_value("controls","assist",combat.aim_assist)
	config.save("user://remaster_settings.cfg")
func load_settings():
	var config=ConfigFile.new()
	config.load("user://remaster_settings.cfg")
	high_quality=bool(config.get_value("video","high",true))
	master_volume=clampf(float(config.get_value("audio","master",.8)),0,1)
	view.sensitivity=clampf(float(config.get_value("controls","sensitivity",1)),.5,1.5)
	combat.aim_assist=bool(config.get_value("controls","assist",true))
	world.set_quality(high_quality)
	apply_volume()
func apply_volume(): AudioServer.set_bus_volume_db(0,linear_to_db(maxf(master_volume,.0001)))

func start_modern():
	stage="modern"
	phase=Phase.ENDING
	player.locked=true
	for enemy in enemies: enemy.hide()
	director.active=false
	director.returning=false
	hud.center_title.text=""
	modern.start()
	modern.scanned.clear()
	for i in 3:
		if tasks.get("scan%d"%i,false): modern.scanned.append(i)
	modern._build_layers()
	save_checkpoint()
	hud.dialogue("九十年后的回答","2026 · 用三个虚拟观察点，记录桥梁的底索、扶索与桥面。")

func finish_modern():
	if modern.scanned.size()<3: return
	stage="complete"
	tasks["complete"]=true
	save_checkpoint()
	paused=true
	var duration="%02d:%02d"%[int(elapsed)/60,int(elapsed)%60]
	hud.show_menu("道路相连，记忆相续","故事完成\n\n用时  %s    重试  %d次\n协作固定横档  ✓    协作铺板  ✓\n铁索通行  ✓    数字结构记录  3 / 3\n\n历史中的勇士为后来的人打开了道路。\n今天的记录，是我们对这条路的一份回答。\n\n山东大学低空科学与工程学院\n2026年“赓续长征精神，智创青春新程”微程序大赛"%[duration,retries],[["继续观察数字桥梁",func(): paused=false; hud.hide_menu()],["历史档案",archive_menu],["返回标题",main_menu],["退出",quit_game]])

func _export_smoke():
	await get_tree().create_timer(1).timeout
	var valid=player.visual.skeleton.get_bone_count()==53 and dialogue!=null and world.chain_count==13
	for actor in [player,amu,zhou]:
		valid=valid and not actor.visual.rig.find_children("Fitted_field_cap*","MeshInstance3D",true,false).is_empty()
	var resource=get_node("/root/DialogueManager").create_resource_from_text(FileAccess.get_file_as_string("res://story/prologue.dialogue"))
	var first=await get_node("/root/DialogueManager").get_next_dialogue_line(resource,"start",[self])
	valid=valid and first!=null and not first.text.is_empty()
	RenderingServer.force_draw(false)
	get_viewport().get_texture().get_image().save_png(OS.get_executable_path().get_base_dir().path_join("remaster_export_smoke.png"))
	print("REMASTER EXPORT SMOKE: ","PASS" if valid else "FAIL")
	var finisher=load("res://qa/smoke_controller.gd").new()
	get_tree().root.add_child(finisher)
	finisher.finish(self,0 if valid else 1)
