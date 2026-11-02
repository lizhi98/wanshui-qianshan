extends Node3D

enum Phase { INTRO, COMBAT, PICKUP, COOPERATE, CROSSING, ENDING }
var phase := Phase.INTRO
var player
var view
var world
var combat
var hud
var amu
var zhou
var enemies: Array = []
var started := false
var paused := false
var failed := false
var dialogue_locked := false
var dialogue_remaining := 0.0
var interaction_busy := false
var action_time := 0.0
var elapsed := 0.0
var intro_time := 0.0
var ending_time := 0.0
var intro_line := -1
var ending_line := -1
var kills := 0
var retries := 0
var crossed := false
var assisted := false
var cooperate_line := false
var checkpoint := Phase.COMBAT
var placement_start: Transform3D
var pickup_start: Vector3
var ambience: AudioStreamPlayer

func _ready():
	_inputs()
	world = world_type().new()
	world.mission = self
	add_child(world)
	player = load("res://objects/player.tscn").instantiate()
	player.set_script(player_type())
	player.mission = self
	player.visual_type = character_type()
	player.position = Vector3(0,0.1,4.3)
	player.rotation.y = PI
	player.rotation_direction = PI
	add_child(player)
	player.collision_mask = 17
	player.died.connect(_on_death)
	view = Node3D.new()
	view.set_script(load("res://game/camera.gd"))
	view.name = "View"
	view.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	view.mission = self
	view.target = player
	var camera = Camera3D.new()
	camera.name = "Camera"
	camera.current = true
	camera.far = 260
	view.add_child(camera)
	add_child(view)
	player.view = view
	amu = _actor("Amu",Vector3(-0.95,0,3.1),false)
	zhou = _actor("Zhou",Vector3(-1.9,0,2.05),false)
	for i in 2:
		var enemy = _actor("Defender%d" % i,Vector3(-2.7 if i==0 else 2.7,0,-29.5),true)
		enemy.rotation.y = 0
		enemy.defeated.connect(_enemy_defeated)
		enemies.append(enemy)
	combat = load("res://game/combat.gd").new()
	combat.mission = self
	add_child(combat)
	hud = hud_type().new()
	hud.mission = self
	add_child(hud)
	player.hit.connect(func(): hud.hurt_tint = 0.26)
	ambience = AudioStreamPlayer.new()
	ambience.stream = load("res://assets/audio/river.wav")
	ambience.volume_db = -22
	add_child(ambience)
	ambience.finished.connect(ambience.play)
	ambience.play()
	_scenic_camera()
	if "--smoke-test" in OS.get_cmdline_user_args():
		call_deferred("_export_smoke")

func _export_smoke():
	await get_tree().create_timer(0.7).timeout
	var valid = player.visual.skeleton.get_bone_count()>60 and enemies.size()==2 and not world.repair_enabled and hud.overlay.visible
	await RenderingServer.frame_post_draw
	var path = OS.get_executable_path().get_base_dir().path_join("export_smoke.png")
	get_viewport().get_texture().get_image().save_png(path)
	print("EXPORT SMOKE: ", "PASS" if valid else "FAIL")
	get_tree().quit(0 if valid else 1)

func _inputs():
	for entry in [["sprint",KEY_SHIFT],["interact",KEY_E],["reload",KEY_R],["pause",KEY_ESCAPE]]:
		if not InputMap.has_action(entry[0]): InputMap.add_action(entry[0])
		var event = InputEventKey.new()
		event.physical_keycode = entry[1]
		InputMap.action_add_event(entry[0],event)
	for entry in [["shoot",MOUSE_BUTTON_LEFT],["aim",MOUSE_BUTTON_RIGHT]]:
		if not InputMap.has_action(entry[0]): InputMap.add_action(entry[0])
		var event = InputEventMouseButton.new()
		event.button_index = entry[1]
		InputMap.action_add_event(entry[0],event)

func _actor(actor_name: String, pos: Vector3, is_enemy: bool):
	var actor = load("res://game/npc.gd").new()
	actor.name = actor_name
	actor.mission = self
	actor.enemy = is_enemy
	actor.visual_type = character_type()
	actor.position = pos
	add_child(actor)
	return actor

func character_type():
	return preload("res://game/soldier_visual.gd")

func player_type(): return load("res://game/player.gd")

func world_type():
	return preload("res://game/bridge_world.gd")

func hud_type():
	return preload("res://game/hud.gd")

func begin():
	started = true
	hud.hide_menu()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta):
	if Input.is_action_just_pressed("pause") and started and not failed and not (phase == Phase.ENDING and ending_time>17):
		toggle_pause()
	if paused or failed or not started:
		return
	if phase == Phase.ENDING and ending_time>17 and hud.overlay.visible:
		return
	elapsed += delta
	if dialogue_remaining > 0:
		dialogue_remaining -= delta
		if dialogue_remaining<=0:
			dialogue_locked = false
			hud.dialogue("", "")
	if Input.is_action_just_pressed("interact"):
		interact()
	match phase:
		Phase.INTRO:
			_intro(delta)
		Phase.PICKUP:
			if interaction_busy: _pickup_tick(delta)
		Phase.COOPERATE:
			if interaction_busy:
				_place_tick(delta)
			elif not amu.moving and not cooperate_line and player.position.z < -6.5:
				cooperate_line = true
				say("阿木", "我扶着这边，你把木板放下！",2.5)
		Phase.CROSSING:
			if crossed and player.position.z < -23.5 and not amu.moving and not zhou.moving:
				_start_ending()
		Phase.ENDING:
			_ending(delta)

func _scenic_camera():
	view.position = Vector3(-6,5.8,10)
	view.rotation = Vector3.ZERO
	view.camera.position = Vector3.ZERO
	view.camera.look_at(Vector3(0,0,-12))

func _intro(delta):
	intro_time += delta
	var p = clampf(intro_time/6.5,0,1)
	p = p*p*(3.0-2.0*p)
	view.position = Vector3(-5,-6.5,-10).lerp(Vector3(-5.5,5.5,9),p)
	view.rotation = Vector3.ZERO
	view.camera.position = Vector3.ZERO
	view.camera.look_at(Vector3(0,-8.5,-14).lerp(Vector3(0,0.2,-9),p))
	hud.center_title.text = "战火中的木板\n1935 · 大渡河" if intro_time<5.5 else ""
	if intro_time>7:
		var close_p = clampf((intro_time-7)/8,0,1)
		view.position = Vector3(-5.5,5.5,9).lerp(Vector3(-2.0,2.6,7),close_p)
		view.camera.look_at(Vector3(0,1.0,2.0))
	var line = 0 if intro_time<11 else (1 if intro_time<15 else 2)
	if intro_time>7.3 and line!=intro_line:
		intro_line = line
		var who = ["周班长","阿木","周班长"][line]
		var text_value = ["前面的桥板断了，后面的同志还等着通过！","木板在这里，可是对岸还在开枪！","你先掩护，我和阿木想办法把木板运过去！"][line]
		say(who,text_value,4)
	if intro_time>20:
		finish_intro()

func finish_intro():
	if phase != Phase.INTRO:
		return
	started = true
	phase = Phase.COMBAT
	player.locked = false
	view.cinematic = false
	view.position = player.position+Vector3(0,1.35,0)
	view.rotation_degrees = Vector3(-12,0,0)
	view.camera_rotation = Vector3(-12,0,0)
	view.camera.position = Vector3(0.38,0.12,4.6)
	view.camera.rotation = Vector3.ZERO
	hud.hide_menu()
	hud.center_title.text = ""
	dialogue_locked = false
	dialogue_remaining = 0
	hud.dialogue("", "")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func say(who: String, text_value: String, duration := 3.3):
	dialogue_locked = true
	dialogue_remaining = duration
	hud.dialogue(who,text_value)

func _enemy_defeated():
	kills = 0
	for enemy in enemies:
		if enemy.dead: kills+=1
	if kills == 2 and phase == Phase.COMBAT:
		phase = Phase.PICKUP
		checkpoint = Phase.PICKUP
		combat.reloading = false
		amu.walk([Vector3(-0.8,0,2.0)])
		zhou.fixed_pose = "aim"
		say("阿木","林川！帮我搭把手！",3.0)

func interact():
	if dialogue_locked or paused or failed or interaction_busy:
		return
	if phase == Phase.COMBAT:
		if player.position.distance_to(Vector3(-4.2,0,3.3))<2:
			combat.reserve = 30
			say("林川","还有子弹，继续掩护！",1.5)
	elif phase == Phase.PICKUP:
		if player.position.distance_to(world.board_start)<2.0:
			interaction_busy = true
			action_time = 0
			player.locked = true
			pickup_start = player.position
			player.rotation.y = PI
			player.visual.mode = "pickup"
	elif phase == Phase.COOPERATE:
		if player.position.distance_to(Vector3(0,0,-7.9))<1.65 and not amu.moving:
			interaction_busy = true
			action_time = 0
			player.locked = true
			player.position = Vector3(0.35,0.0,-8.1)
			player.rotation.y = PI
			player.visual.mode = "place"
			amu.position = Vector3(-0.65,0,-8.1)
			amu.rotation.y = PI
			amu.fixed_pose = "place"
			world.board.reparent(world,true)
			placement_start = world.board.transform
	elif phase == Phase.CROSSING and not crossed and player.position.distance_to(Vector3(1.43,0,-16.35))<1.65:
		player.start_climb()

func _pickup_tick(delta):
	action_time += delta
	player.position = pickup_start.lerp(world.board_start+Vector3(0,-0.15,1.50),clampf(action_time/0.45,0,1))
	player.visual.hand_targets = [world.board.global_position+Vector3(-0.20,0.13,1.20),world.board.global_position+Vector3(0.20,0.13,1.20)]
	if action_time>=1.3:
		player.visual.rig.rotation.x = 0
		player.visual.hand_targets = []
		world.board.reparent(player.visual.carry_anchor,false)
		world.board.position = Vector3.ZERO
		world.board.rotation = Vector3.ZERO
		player.carrying = true
		player.locked = false
		player.visual.mode = "carry"
		phase = Phase.COOPERATE
		interaction_busy = false
		amu.walk([Vector3(-0.72,0,0),Vector3(-0.72,0,-6.4),Vector3(-0.72,0,-7.95)])
		sound("res://assets/audio/wood.wav",-15)
		say("周班长","稳住，沿着桥面把木板送到缺口。",2.8)

func _place_tick(delta):
	action_time += delta
	var p = clampf(action_time/2.1,0,1)
	p = p*p*(3.0-2.0*p)
	world.board.position = placement_start.origin.lerp(world.board_final,p)+Vector3(0,sin(p*PI)*0.18,0)
	world.board.rotation.x = sin(p*PI)*0.16
	player.visual.hand_targets = [world.board.global_position+Vector3(0.10,0.07,1.24),world.board.global_position+Vector3(0.42,0.07,1.24)]
	amu.visual.hand_targets = [world.board.global_position+Vector3(-0.42,0.07,1.24),world.board.global_position+Vector3(-0.12,0.07,1.24)]
	if action_time>=2.1:
		player.visual.hand_targets = []
		amu.visual.hand_targets = []
		world.board.position = world.board_final
		world.board.rotation = Vector3.ZERO
		world.enable_repair()
		player.carrying = false
		player.locked = false
		interaction_busy = false
		assisted = true
		phase = Phase.CROSSING
		checkpoint = Phase.CROSSING
		amu.walk([Vector3(0,0,-7.95),Vector3(0,0,-11.4),Vector3(-0.6,0,-14.7)])
		zhou.walk([Vector3(0,0,0),Vector3(0,0,-7.8),Vector3(0,0,-11.5),Vector3(0.55,0,-14.6)],2.3)
		sound("res://assets/audio/wood.wav",-8)
		say("周班长","前面的板子还没铺齐，抓紧铁索过去！",3.6)

func on_chain_finished():
	crossed = true
	amu.walk([Vector3(1.43,0,-16.3),Vector3(1.43,0,-21.2),Vector3(-0.75,0,-24.4)],2.6)
	zhou.walk([Vector3(1.43,0,-16.3),Vector3(1.43,0,-21.2),Vector3(0.8,0,-24.5)],2.8)

func _start_ending():
	phase = Phase.ENDING
	player.locked = true
	player.visual.mode = "idle"
	amu.face(player.position)
	zhou.face(player.position)
	view.cinematic = true
	ending_time = 0
	ending_line = -1

func _ending(delta):
	ending_time += delta
	var line = 0 if ending_time<4 else (1 if ending_time<8 else 2)
	if line!=ending_line and ending_time<12:
		ending_line = line
		say(["阿木","林川","周班长"][line],["过去了！终于过去了！","刚刚站在铁索上，我还以为自己撑不住了。","路还长，继续往前！"][line],3.8)
	view.rotation = Vector3.ZERO
	view.camera.position = Vector3.ZERO
	view.camera.rotation = Vector3.ZERO
	var p = clampf(ending_time/17,0,1)
	view.position = Vector3(-3.8,2.8,-22).lerp(Vector3(-10,10,-12),p)
	view.camera.look_at(Vector3(0,0,-21).lerp(Vector3(0,0,-13),p))
	if ending_time>12:
		hud.center_title.text = "大渡桥横铁索寒。"
	if ending_time>17 and not hud.overlay.visible:
		hud.center_title.text = ""
		hud.dialogue("", "")
		hud.show_menu("子剧情完成：战火中的木板","完成时间    %02d:%02d\n击败守军    %d / 2\n铺桥成功    ✓\n队友协作    ✓\n死亡重试    %d 次" % [int(elapsed)/60,int(elapsed)%60,kills,retries],[["重新游玩",restart],["退出",quit_game]])

func _on_death():
	failed = true
	combat.reloading = false
	hud.dialogue("", "")
	hud.show_menu("倒下了，但道路还要继续", "从最近检查点重试。\n\n战斗、铺桥与铁索阶段分别保存进度。\n死亡重试次数将记录在结算里。",[["从检查点重试",retry_checkpoint],["重新开始",restart],["退出",quit_game]])

func retry_checkpoint():
	retries += 1
	failed = false
	paused = false
	dialogue_locked = false
	dialogue_remaining = 0
	interaction_busy = false
	crossed = false
	cooperate_line = false
	player.visual.rig.rotation = Vector3.ZERO
	amu.restore()
	zhou.restore()
	combat.reset()
	if checkpoint == Phase.COMBAT:
		phase = Phase.COMBAT
		kills = 0
		for enemy in enemies: enemy.restore()
		world.reset_board()
		player.restore(Vector3(0,0.1,4.3))
	elif checkpoint == Phase.PICKUP:
		phase = Phase.PICKUP
		world.reset_board()
		player.restore(Vector3(0,0.1,2.8))
		amu.walk([Vector3(-0.8,0,2.0)])
	else:
		phase = Phase.CROSSING
		player.restore(Vector3(1.2,0.1,-15.8))
		amu.position = Vector3(-0.6,0,-14.7)
		zhou.position = Vector3(0.55,0,-14.6)
	view.cinematic = false
	view.camera_rotation = Vector3(-12,0,0)
	view.position = player.position+Vector3(0,1.35,0)
	hud.hide_menu()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func restart():
	phase = Phase.INTRO
	started = false
	paused = false
	failed = false
	dialogue_locked = false
	dialogue_remaining = 0
	interaction_busy = false
	intro_time = 0
	intro_line = -1
	ending_time = 0
	elapsed = 0
	kills = 0
	retries = 0
	crossed = false
	assisted = false
	cooperate_line = false
	checkpoint = Phase.COMBAT
	world.reset_board()
	player.restore(Vector3(0,0.1,4.3))
	player.locked = true
	player.visual.rig.rotation = Vector3.ZERO
	for actor in enemies+[amu,zhou]: actor.restore()
	combat.reset()
	view.cinematic = true
	_scenic_camera()
	hud.dialogue("", "")
	hud.center_title.text = ""
	hud.show_menu("万水千山：战火中的木板","1935 年 5 月 29 日 · 泸定桥\n\n掩护战友，修复桥面。\n\nWASD 移动，右键瞄准，左键射击，R 装填，E 交互。",[["开始行动",begin],["退出",quit_game]])

func toggle_pause():
	paused = not paused
	player.locked = paused or phase in [Phase.INTRO,Phase.ENDING] or interaction_busy
	if paused:
		hud.show_menu("暂停", "WASD 移动 · Shift 奔跑 · Space 跳跃\n右键瞄准 · 左键射击 · R 装填 · E 交互\n\n铁索上：W / S 前后移动，A / D 调整平衡。",[["继续",toggle_pause],["从检查点重试",retry_checkpoint],["退出",quit_game]])
	else:
		hud.hide_menu()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func objective_text() -> String:
	match phase:
		Phase.INTRO: return "与战友一起，跨过大渡河"
		Phase.COMBAT: return "掩护战友  ·  守军 %d / 2" % kills
		Phase.PICKUP: return "与阿木一起拾起木板"
		Phase.COOPERATE: return "将木板送到桥面缺口"
		Phase.CROSSING: return "通过铁索，抵达安全区域"
		Phase.ENDING: return "桥面已修复  ·  战友已通过"
	return ""

func interaction_hint() -> String:
	if paused or failed or not started or phase in [Phase.INTRO,Phase.ENDING] or dialogue_locked:
		return ""
	if interaction_busy: return "正在拾取木板…" if phase==Phase.PICKUP else "与阿木协作铺板…"
	if phase == Phase.COMBAT:
		if player.position.distance_to(Vector3(-4.2,0,3.3))<2: return "E  补充弹药"
		return "利用桥头掩体  ·  右键瞄准对岸守军"
	if phase == Phase.PICKUP:
		return "E  拾取木板" if player.position.distance_to(world.board_start)<2 else "木板在桥头右侧  ·  靠近后按 E"
	if phase == Phase.COOPERATE:
		if player.position.z > -6.5: return "沿桥面向前  ·  将木板送到第一处缺口"
		return "等待战友协助" if amu.moving else "E  与阿木协作铺设木板"
	if phase == Phase.CROSSING:
		if player.climbing: return "抓稳铁索，缓缓前进"
		if crossed: return "向前抵达安全区域，等候战友"
		if player.position.distance_to(Vector3(1.43,0,-16.35))<1.65: return "E  抓住右侧铁索"
		return "沿新铺木板的中间通过  ·  前方靠右抓索"
	return ""

func sound(path: String, volume := -12.0):
	var node = AudioStreamPlayer.new()
	node.stream = load(path)
	node.volume_db = volume
	add_child(node)
	node.finished.connect(node.queue_free)
	node.play()

func quit_game():
	if ambience: ambience.stop()
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()

func _exit_tree():
	if is_instance_valid(ambience):
		ambience.stop()
		ambience.stream = null
