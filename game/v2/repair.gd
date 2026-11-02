extends Node3D
signal completed(result:Dictionary)

var mission
var active:=false
var site:=0
var step:="select"
var material:=""
var repaired:Array[bool]=[false,false]
var rope_assist:=false
var required_rounds:=1
var prep_round:=0
var lateral:=-.65
var depth:=-.55
var tension:=.45
var hold_progress:=0.0
var feedback:=""
var clock:=0.0
var unlock_delay:=0.0
var props:Node3D
var stock:Node3D
var bench:Node3D
var active_board:Node3D
var material_nodes:Dictionary={}
var obstacle_bodies:Array[StaticBody3D]=[]
var last_carry_transform:=Transform3D.IDENTITY
var board_blocked:=false
var helper_stalled:=0.0
var helper_blocker:=""
var carry_from_park:=false
var parked_origin:=Transform3D.IDENTITY
var navigation=preload("res://game/v2/carry_navigation.gd").new()
var helper_path:Array[Vector3]=[]
var helper_index:=0
var state_clock:=0.0
var rig_yaw:=PI
var lift_origin:=Transform3D.IDENTITY
var transition_log:Array[String]=[]
var recover_start:=Vector3.ZERO
var stalled_clock:=0.0
var request_clock:=0.0
var completed_once:=false
var _wood:Material
var _dark:StandardMaterial3D
var _rope:StandardMaterial3D
var _rope_nodes:Array[MeshInstance3D]=[]

func setup(m):
	mission=m
	navigation.setup(self)
	set_process(false)
	if props: return
	_wood=mission.world.wood
	_dark=mission.world.material(Color("28241d"))
	_rope=mission.world.material(Color("aa9465"))
	props=Node3D.new(); props.name="V2RepairMaterials"; add_child(props)
	stock=Node3D.new(); props.add_child(stock)
	for kind in ["good","cracked","bad"]:
		var timber=Node3D.new(); timber.name="Timber_"+kind; stock.add_child(timber)
		_build_timber(timber,kind)
		var label=Label3D.new(); label.font=load("res://assets/remaster/fonts/NotoSansSC.ttf")
		label.text={"good":"完好木板 · 可直接备料","cracked":"纵向裂纹 · 需要两道加固","bad":"贯穿朽裂 · 不宜通行"}[kind]
		label.font_size=32; label.pixel_size=.008; label.position=Vector3(0,1.0,0)
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; timber.add_child(label)
		material_nodes[kind]=timber
	bench=Node3D.new(); props.add_child(bench)
	_box(bench,Vector3(1.12,.08,2.84),Vector3(0,.64,0),_wood)
	for x in [-.42,.42]:
		for z in [-.85,.85]: _box(bench,Vector3(.07,.65,.07),Vector3(x,.32,z),_wood)
	active_board=Node3D.new(); active_board.name="CurrentRepairTimber"; add_child(active_board)
	# Clear loading lane; keep a small store at the bank edge.
	var rack=Node3D.new(); rack.name="BankStore"; props.add_child(rack)
	_box(rack,Vector3(.7,.65,.7),Vector3(6.8,.32,9.0),_wood,true)
	props.hide(); active_board.hide(); _obstacles(false)

func _box(parent:Node3D,size_value:Vector3,pos:Vector3,mat:Material,solid:=false)->MeshInstance3D:
	var mesh=MeshInstance3D.new(); var shape=BoxMesh.new(); shape.size=size_value
	mesh.mesh=shape; mesh.material_override=mat; mesh.position=pos; parent.add_child(mesh)
	if solid:
		var body=StaticBody3D.new(); body.collision_layer=1; body.collision_mask=0
		parent.add_child(body); body.position=pos
		var collider=CollisionShape3D.new(); var box_shape=BoxShape3D.new(); box_shape.size=size_value
		collider.shape=box_shape; body.add_child(collider); obstacle_bodies.append(body)
	return mesh

func _build_timber(parent:Node3D,kind:String):
	if kind=="bad":
		_box(parent,Vector3(.80,.13,1.10),Vector3(.04,0,.79),_wood).rotation.y=.07
		_box(parent,Vector3(.80,.13,1.08),Vector3(-.04,0,-.79),_wood).rotation.y=-.10
		for i in 4: _box(parent,Vector3(.035,.015,.92),Vector3(-.3+i*.19,.074,.72),_dark)
	else:
		_box(parent,Vector3(.94,.13,2.62),Vector3.ZERO,_wood)
		if kind=="cracked":
			for i in 5:
				var crack=_box(parent,Vector3(.018,.009,.52),Vector3(sin(i*1.7)*.07,.071,-1.0+i*.47),_dark)
				crack.rotation.y=.18 if i%2 else -.16

func _build_active():
	carry_from_park=false
	if active_board.get_parent()!=self: active_board.reparent(self,false)
	for child in active_board.get_children(): child.free()
	_rope_nodes.clear()
	_build_timber(active_board,material if material in ["good","cracked"] else "good")
	for i in 4:
		var ring=MeshInstance3D.new(); var torus=TorusMesh.new()
		torus.inner_radius=.46; torus.outer_radius=.476; torus.rings=20; torus.ring_segments=5
		ring.mesh=torus; ring.material_override=_rope; ring.rotation.x=PI/2
		ring.scale=Vector3(1,1,.16); ring.position.z=-.6+i*.4
		active_board.add_child(ring); _rope_nodes.append(ring); ring.hide()
	active_board.rotation=Vector3.ZERO
	active_board.position=_work_position()
	active_board.show()

func start(state:Dictionary={}):
	stop()
	active=true; site=clampi(int(state.get("site",0)),0,1)
	var prior=state.get("repaired",[false,false])
	repaired=[bool(prior[0]) if prior is Array and prior.size()>0 else false,bool(prior[1]) if prior is Array and prior.size()>1 else false]
	for i in 2: mission.world.set_v2_repair(i,repaired[i])
	rope_assist=bool(state.get("rope_assist",false))
	material=str(state.get("material",""))
	if material not in ["good","cracked"]: material=""
	required_rounds=2 if material=="cracked" else 1
	prep_round=clampi(int(state.get("prep_round",0)),0,required_rounds-1)
	step=str(state.get("step","select"))
	if step in ["carry","align","secure","place_check","join","npc_ready","lifting","lowering","recover","preparing","auto_secure","parked"]: step="pickup"
	if step not in ["select","position","tie","check","pickup","done"]: step="select"
	if material.is_empty(): step="select"
	if repaired[0] and not repaired[1]: site=1
	if repaired[0] and repaired[1]: step="done"
	lateral=clampf(float(state.get("lateral",-.65)),-1,1)
	depth=clampf(float(state.get("depth",-.55)),-1,1)
	hold_progress=0; tension=.45; clock=0; feedback=""; board_blocked=false
	state_clock=0; request_clock=0; completed_once=false; helper_path.clear()
	props.show(); _obstacles(site==0)
	_refresh_stock()
	if step!="select" and step!="done": _build_active()
	else: active_board.hide()
	if step=="position": _update_preparation_board()
	if step in ["check","pickup"]:
		for ring in _rope_nodes: ring.show()
	bench.visible=step in ["position","tie","check","pickup"]
	bench.position=_work_position()-Vector3(0,.76,0)
	mission.player.locked=step in ["position","tie","check"]
	if step=="done":
		active=false; props.hide(); _obstacles(false)
		completed.emit(_result())

func _refresh_stock():
	var station:Vector3=mission.world.get_v2_gap(site).station
	stock.position=station+Vector3(0,.19,0)
	var spacing=1.9 if site==0 else 1.02
	for i in 3:
		var kind=["good","cracked","bad"][i]
		material_nodes[kind].position=Vector3((i-1)*spacing,0,0)
	stock.visible=step=="select"

func material_position(kind:String)->Vector3:
	return material_nodes[kind].global_position+Vector3(0,-.19,1.30)

func _work_position()->Vector3:
	var station:Vector3=mission.world.get_v2_gap(site).station
	var spacing=1.9 if site==0 else 1.02
	var index=0 if material=="good" else 1
	return station+Vector3((index-1)*spacing,.76,0)

func safe_position()->Vector3:
	return _work_position()+Vector3(0,-.66,1.45)

func pickup_position()->Vector3:
	if carry_from_park:
		var point=active_board.to_global(Vector3(0,0,-1.55)); point.y=0; return point
	return _work_position()+Vector3(0,-.76,-1.55)

func tick(delta:float):
	if not active or mission.get("paused")==true or mission.get("failed")==true: return
	if Input.is_action_just_pressed("reload") and not mission.player.aiming:
		cancel_interaction("主动取消，木板返回备料点")
		return
	state_clock+=delta
	clock+=delta; unlock_delay=maxf(0,unlock_delay-delta)
	var nearest="good"; var nearest_distance=INF
	for kind in material_nodes:
		var distance=mission.player.global_position.distance_to(material_position(kind))
		if distance<nearest_distance: nearest=kind; nearest_distance=distance
	for kind in material_nodes:
		for child in material_nodes[kind].get_children():
			if child is Label3D: child.visible=step=="select" and kind==nearest and nearest_distance<2.8
	if step in ["select","pickup"]: mission.player.locked=unlock_delay>0
	match step:
		"preparing":
			mission.player.locked=false
			for i in _rope_nodes.size(): _rope_nodes[i].visible=state_clock>.2+i*.15
			if state_clock>(1.4 if material=="cracked" else .7):
				rope_assist=rope_assist or material=="cracked"
				_set_step("pickup","备料完成，去朝桥的一端接板")
				mission.player.visual.hand_targets=[]; mission.save_checkpoint()
		"auto_secure":
			_settle_at_gap(delta); _placement_hands()
			if state_clock>.7: _finish_site()
		"parked":
			mission.player.locked=false
			active_board.position.y=lerpf(parked_origin.origin.y,.12,smoothstep(0,1,minf(state_clock/.45,1)))
		"position":
			mission.player.locked=true
			if prep_round==0: lateral=clampf(lateral+Input.get_axis("move_left","move_right")*delta,-1,1)
			else: depth=clampf(depth+Input.get_axis("move_forward","move_back")*delta,-1,1)
			_update_preparation_board()
			_work_hands(delta)
		"tie", "secure":
			mission.player.locked=true
			tension=clampf(tension+delta*.075+Input.get_axis("move_left","move_right")*delta*.45,0,1)
			if Input.is_action_pressed("interact") and tension>.22 and tension<.82:
				hold_progress+=delta
				feedback="固定中 · 保持张力"
			else:
				hold_progress=maxf(0,hold_progress-delta*.22)
				if tension<=.22 or tension>=.82: feedback="张力偏离白区，A/D修正"
			if step=="secure": _placement_hands()
			else: _work_hands(delta)
			for i in _rope_nodes.size(): _rope_nodes[i].visible=float(i)/4<hold_progress/1.4
			if hold_progress>=1.4:
				hold_progress=0; tension=.45
				if step=="secure": step="place_check"
				elif prep_round+1<required_rounds:
					prep_round+=1; step="position"; depth=-.55
				else: step="check"
				feedback="固定完成 · Space检查" if step in ["check","place_check"] else "裂纹仍需另一道横向加固"
		"check":
			_work_hands(delta)
			if Input.is_action_just_pressed("jump"):
				rope_assist=rope_assist or material=="cracked"
				step="pickup"; unlock_delay=.18; mission.player.visual.hand_targets=[]
				mission.say("阿木","加固合格。我扶后端，你带路。")
				mission.save_checkpoint()
		"join":
			mission.player.locked=false
			request_clock+=delta
			if mission.player.position.distance_to(pickup_position())>2.5:
				cancel_interaction("已离开木板，可回来重新呼叫"); return
			_move_helper(_pickup_helper_goal(),delta)
			if mission.amu.position.distance_to(_pickup_helper_goal())<.13 and mission.player.position.distance_to(pickup_position())<.34:
				mission.amu.visual.speed=0
				_set_step("npc_ready","两端就位")
				mission.say("阿木","抓稳了，咱们一起抬！")
			elif request_clock>18:
				cancel_interaction("接应路线受阻，已释放操作；E 可重试")
		"npc_ready":
			mission.player.locked=false
			_face_pickup(delta)
			if mission.player.position.distance_to(pickup_position())>.65:
				cancel_interaction("已离开握持点，请重新呼叫"); return
			mission.player.move_and_collide((pickup_position()-mission.player.position).limit_length(delta*1.4))
			if state_clock>.45 and mission.player.position.distance_to(pickup_position())<.12:
				lift_origin=active_board.global_transform
				rig_yaw=active_board.global_rotation.y
				_set_step("lifting","同步抬起")
		"lifting":
			mission.player.locked=true
			mission.player.velocity=Vector3.ZERO; mission.player.movement_velocity=Vector3.ZERO
			_face_pickup(delta)
			var t=smoothstep(0,1,clampf(state_clock/.75,0,1))
			var target=lift_origin
			target.origin.y=1.04
			active_board.global_transform=lift_origin.interpolate_with(target,t)
			_grip_hands("pickup")
			if state_clock>=.75:
				mission.player.carrying=true; mission.player.locked=false
				bench.hide(); _set_step("carry","共同搬运")
				active_board.global_transform=_rig_transform(); mission.amu.position=_helper_goal(); _grip_hands("carry")
				mission.sound("res://assets/audio/wood.wav",-16)
				mission.say("林川","好，走！")
		"carry": _carry_tick(delta)
		"lowering":
			mission.player.locked=true
			var gap=mission.world.get_v2_gap(site)
			# Lower below the torso before feeding the board onto its supports.
			var t=clampf(state_clock/3.2,0,1)
			var lowered=lift_origin
			lowered.origin.y=.32
			if t<.45:
				active_board.global_transform=lift_origin.interpolate_with(lowered,smoothstep(0,1,t/.45))
				_grip_hands("place")
			else:
				active_board.global_transform=lowered.interpolate_with(Transform3D(Basis.IDENTITY,gap.center+Vector3(0,.38,0)),smoothstep(0,1,(t-.45)/.55))
				_settle_at_gap(delta); _placement_hands()
			if state_clock>=3.2:
				_set_step("auto_secure" if mission.get("simple_repair")==true else "align","两人放下，固定支撑")
				lateral=0; depth=0
		"recover":
			mission.player.locked=false
			active_board.position=recover_start-Vector3(0,minf(state_clock,.35)*.65,0)
			active_board.scale=Vector3.ONE*maxf(.01,1-state_clock/.45)
			if state_clock>=.45:
				active_board.scale=Vector3.ONE; _build_active(); bench.show()
				_set_step("pickup","安全返回备料点"); mission.save_checkpoint()
		"align":
			mission.player.locked=true
			_settle_at_gap(delta)
			lateral=clampf(lateral+Input.get_axis("move_left","move_right")*delta,-1,1)
			if site==1: depth=clampf(depth+Input.get_axis("move_forward","move_back")*delta,-1,1)
			var gap=mission.world.get_v2_gap(site)
			active_board.position=gap.center+Vector3(lateral*.48,.38,depth*.34 if site==1 else 0.0)
			active_board.rotation.y=depth*.22 if site==1 else 0.0
			_placement_hands()
		"place_check":
			_placement_hands()
			if Input.is_action_just_pressed("jump"): _finish_site()

func interact():
	if not active or mission.get("paused")==true or mission.get("failed")==true: return
	match step:
		"select":
			var nearest=""; var distance=1.65
			for kind in ["good","cracked","bad"]:
				var d=mission.player.global_position.distance_to(material_position(kind))
				if d<distance: distance=d; nearest=kind
			if nearest.is_empty(): feedback="靠近木板端部，查看纹理和裂口"; return
			if nearest=="bad":
				feedback="贯穿朽裂，不能承重；换一块仍可继续"
				mission.say("阿木","这块朽了，换旁边的。")
				return
			material=nearest; required_rounds=2 if material=="cracked" else 1
			prep_round=0; lateral=-.65; depth=-.55; step="position"; hold_progress=0
			stock.hide(); _build_active(); bench.position=_work_position()-Vector3(0,.76,0); bench.show()
			mission.player.locked=true
			if mission.get("simple_repair")==true:
				mission.player.locked=false
				_set_step("preparing","自动检查并固定木料")
			feedback="需要两道加固，之后可用多余绳索辅助通行" if material=="cracked" else "好板只需定位、一道固定和检查"
		"position":
			if absf(lateral if prep_round==0 else depth)>.17: feedback="未对齐；先用A/D或W/S移入白色范围"; return
			step="tie"; hold_progress=0; tension=.45
		"parked":
			if state_clock<.45: return
			if mission.player.position.distance_to(pickup_position())<1.15: _begin_carry()
			else: feedback="靠近木板朝桥一端，E继续搬运"
		"pickup":
			if mission.player.global_position.distance_to(pickup_position())>.65: feedback="走到木板朝桥的一端（金色标记），再按 E 呼叫"; return
			_begin_carry()
		"carry":
			var goal:Vector3=mission.world.get_v2_gap(site).approach
			if mission.player.position.distance_to(goal)>1.45: feedback="先把木板送到缺口前的标记处"; return
			lift_origin=active_board.global_transform
			mission.player.carrying=false; mission.player.locked=true
			_set_step("lowering","到达目标，两人共同放下")
			mission.sound("res://assets/audio/wood.wav",-16)
		"align":
			if absf(lateral)>.17 or (site==1 and absf(depth)>.17): feedback="未对齐，板端尚未压住两侧支撑"; return
			step="secure"; hold_progress=0; tension=.45
			active_board.position=mission.world.get_v2_gap(site).center+Vector3(0,.32,0); active_board.rotation=Vector3.ZERO

func _set_step(next:String,reason:String):
	var line="[Carry] site=%d %s -> %s : %s"%[site,step,next,reason]
	print(line); transition_log.append(line)
	if transition_log.size()>80: transition_log.pop_front()
	step=next; state_clock=0; feedback=reason

func _begin_carry():
	mission.player.carrying=false; mission.player.locked=false
	mission.amu.moving=false; mission.amu.fixed_pose=""
	mission.player.visual.hand_targets=[]; mission.amu.visual.hand_targets=[]
	helper_path=navigation.route(mission.amu.position,_pickup_helper_goal()); helper_index=0
	request_clock=0; stalled_clock=0; helper_stalled=0
	_set_step("join","玩家呼叫，等待实际到位")
	mission.say("林川","同志，过来搭把手！")
	mission.say("阿木","来了！我接另一头！")
	mission.save_checkpoint()

func _pickup_helper_goal()->Vector3:
	if carry_from_park:
		var point=active_board.to_global(Vector3(0,0,1.55)); point.y=0; return point
	return _work_position()+Vector3(0,-.76,1.55)

func _face_pickup(delta:float):
	for actor in [mission.player,mission.amu]:
		var toward=active_board.global_position-actor.global_position; toward.y=0
		actor.rotation.y=lerp_angle(actor.rotation.y,atan2(toward.x,toward.z),minf(7*delta,1))
		actor.visual.speed=0; actor.visual.mode="pickup"
	mission.amu.fixed_pose="pickup"
	_grip_hands("pickup")

func _rig_transform()->Transform3D:
	return Transform3D(Basis(Vector3.UP,rig_yaw),mission.player.position+Basis(Vector3.UP,rig_yaw)*Vector3(0,1.04,1.55))

func _helper_goal()->Vector3:
	return mission.player.position+Basis(Vector3.UP,rig_yaw)*Vector3(0,0,3.10)

func _board_clear(transform_value:Transform3D)->bool:
	var q=PhysicsShapeQueryParameters3D.new(); var shape=BoxShape3D.new(); shape.size=Vector3(.98,.18,2.66)
	q.shape=shape; q.transform=transform_value; q.collision_mask=1; q.margin=.025
	return get_world_3d().direct_space_state.intersect_shape(q,1).is_empty()

func filter_carry_velocity(value:Vector3,delta:float)->Vector3:
	if mission.get("vanguard") and value.z<0 and mission.player.position.z<(-5.4 if site==0 else -25.3) and not mission.vanguard.frontline_ready(site):
		value.z=0;feedback="突击组正沿铁索就位，稳住木板稍候"
	if step!="carry": return value
	var motion=Vector3(value.x,0,value.z)*delta
	if motion.length()<.0005:
		board_blocked=false; return value
	# Sweep from the last accepted position; never roll back the player's pose.
	var q=PhysicsShapeQueryParameters3D.new(); var shape=BoxShape3D.new(); shape.size=Vector3(.98,.18,2.66)
	q.shape=shape; q.transform=active_board.global_transform; q.collision_mask=1; q.motion=motion; q.margin=.025
	var fraction=get_world_3d().direct_space_state.cast_motion(q)[0]
	var capsule=CapsuleShape3D.new(); capsule.radius=.30; capsule.height=1.70
	q.shape=capsule; q.transform=Transform3D(Basis.IDENTITY,_helper_goal()+Vector3(0,.9,0))
	fraction=minf(fraction,get_world_3d().direct_space_state.cast_motion(q)[0])
	var candidate=_helper_goal()+motion
	if not navigation.supported(candidate): fraction=0
	# Also protect the leader from stepping off the deck into either missing span.
	if not navigation.supported(mission.player.position+motion): fraction=0
	board_blocked=fraction<.99
	if board_blocked: feedback="前方受阻，松开方向键可后退或侧移；R 安全重试"
	return Vector3(value.x*fraction,value.y,value.z*fraction)

func _carry_tick(delta:float):
	mission.player.locked=false
	var velocity_value=Vector3(mission.player.velocity.x,0,mission.player.velocity.z)
	if velocity_value.length()>.10:
		var wanted=atan2(velocity_value.x,velocity_value.z)+PI
		var candidate_yaw=rotate_toward(rig_yaw,wanted,delta*1.4)
		var old_yaw=rig_yaw; rig_yaw=candidate_yaw
		if not _board_clear(_rig_transform()) or not navigation.clear_at(_helper_goal()): rig_yaw=old_yaw
	active_board.global_transform=_rig_transform()
	mission.player.rotation.y=rig_yaw
	if "rotation_direction" in mission.player: mission.player.rotation_direction=rig_yaw
	# Both grips belong to one collision-swept rig. NPC navigation cannot lock input.
	mission.amu.moving=false; mission.amu.fixed_pose="carry"
	mission.amu.position=_helper_goal(); mission.amu.rotation.y=rig_yaw+PI
	mission.amu.visual.speed=velocity_value.length(); mission.player.visual.speed=velocity_value.length()
	_grip_hands("carry")
	if board_blocked and Vector2(mission.player.movement_velocity.x,mission.player.movement_velocity.z).length()>.1:
		helper_stalled+=delta
		if helper_stalled>8: cancel_interaction("搬运持续受阻，已安全释放；回备料点按 E 重试")
	else: helper_stalled=0

func _grip_hands(pose:String):
	mission.player.visual.mode=pose; mission.amu.visual.mode=pose
	mission.amu.fixed_pose=pose
	mission.player.visual.hand_targets=[active_board.to_global(Vector3(-.28,.02,-1.21)),active_board.to_global(Vector3(.28,.02,-1.21))]
	mission.amu.visual.hand_targets=[active_board.to_global(Vector3(-.28,.02,1.21)),active_board.to_global(Vector3(.28,.02,1.21))]

func _move_helper(goal:Vector3,delta:float):
	mission.amu.moving=false
	if mission.amu.position.distance_to(goal)<.12:
		mission.amu.visual.speed=0; return
	stalled_clock+=delta
	if helper_path.is_empty() or helper_index>=helper_path.size():
		if stalled_clock>.9:
			helper_path=navigation.route(mission.amu.position,goal); helper_index=0; stalled_clock=0
		mission.amu.visual.speed=0; return
	var waypoint:Vector3=helper_path[helper_index]
	var diff=waypoint-mission.amu.position; diff.y=0
	if diff.length()<.06: helper_index+=1; return
	var before=mission.amu.position
	var motion=diff.normalized()*minf(delta*2.2,diff.length())
	mission.amu.move_and_collide(motion)
	var moved=mission.amu.position.distance_to(before)
	mission.amu.visual.speed=moved/maxf(delta,.001); mission.amu.visual.mode="walk"; mission.amu.fixed_pose="walk"
	mission.amu.rotation.y=rotate_toward(mission.amu.rotation.y,atan2(diff.x,diff.z),delta*3.2)
	if moved<.005:
		helper_stalled+=delta
		if helper_stalled>.8:
			helper_path=navigation.route(mission.amu.position,goal); helper_index=0; helper_stalled=0
			helper_blocker=navigation.last_error
	else: helper_stalled=0

func cancel_interaction(reason:String="取消搬运"):
	if not active or step in ["select","done","recover"]: return
	mission.player.locked=false; mission.player.carrying=false
	mission.player.velocity=Vector3.ZERO; mission.player.movement_velocity=Vector3.ZERO
	mission.player.visual.hand_targets=[]; mission.player.visual.mode="idle"
	mission.amu.visual.hand_targets=[]; mission.amu.fixed_pose=""; mission.amu.moving=false; mission.amu.visual.speed=0
	helper_path.clear(); helper_stalled=0; feedback=reason
	if step in ["position","tie","check","preparing"]:
		material=""; _set_step("select",reason); active_board.hide(); bench.hide(); _refresh_stock()
	else:
		recover_start=active_board.position; _set_step("recover",reason)

func _update_preparation_board():
	active_board.position=_work_position()+Vector3(lateral*.22 if prep_round==0 else 0.0,0,depth*.25 if prep_round>0 else 0.0)

func _work_hands(delta:float):
	mission.player.visual.mode="brace"
	mission.player.visual.hand_targets=[active_board.to_global(Vector3(-.20,.08,1.08)),active_board.to_global(Vector3(.20,.08,1.08))]
	if mission.player.position.distance_to(safe_position())>.35:
		var direction=safe_position()-mission.player.position; direction.y=0
		mission.player.position+=direction.limit_length(delta*1.2)
	mission.player.rotation.y=PI
	if "rotation_direction" in mission.player: mission.player.rotation_direction=PI

func _settle_at_gap(delta:float):
	var gap=mission.world.get_v2_gap(site)
	var near_z=gap.center.z+gap.size.z*.5+.31
	var goal=Vector3(gap.center.x+.44,0,near_z)
	mission.player.move_and_collide((goal-mission.player.position).limit_length(delta*1.4))
	mission.player.rotation.y=PI
	if "rotation_direction" in mission.player: mission.player.rotation_direction=PI
	var helper_goal=Vector3(gap.center.x-.44,0,near_z)
	var before=mission.amu.position
	mission.amu.move_and_collide((helper_goal-before).limit_length(delta*2.0))
	mission.amu.visual.speed=mission.amu.position.distance_to(before)/maxf(.001,delta)
	mission.amu.rotation.y=rotate_toward(mission.amu.rotation.y,PI,delta*3.2)

func _placement_hands():
	# Feed onto the far support from two positions on the supported near edge.
	# Release the reaching IK while a carrier walks around the lowered timber.
	var actor_points=[
		[mission.player,[Vector3(.05,.08,1.20),Vector3(.42,.08,1.20)]],
		[mission.amu,[Vector3(-.42,.08,1.20),Vector3(-.05,.08,1.20)]]]
	for pair in actor_points:
		var actor=pair[0]
		var targets=[active_board.to_global(pair[1][0]),active_board.to_global(pair[1][1])]
		var planar=Vector2(targets[0].x-actor.position.x,targets[0].z-actor.position.z).length()
		if planar>.8:
			actor.visual.hand_targets=[]; actor.visual.mode="walk"
			if actor==mission.amu: actor.fixed_pose="walk"
		else:
			actor.visual.mode="place"; actor.visual.hand_targets=targets
			if actor==mission.amu: actor.fixed_pose="place"

func _finish_site():
	carry_from_park=false
	if completed_once or repaired[site]: return
	mission.world.set_v2_repair(site,true); repaired[site]=true
	mission.player.carrying=false; mission.player.visual.hand_targets=[]; mission.player.visual.mode="idle"
	mission.amu.visual.hand_targets=[]; mission.amu.fixed_pose=""; active_board.hide()
	mission.player.visual.carry_anchor.position=Vector3(0,1.14,1.48)
	if site==0:
		site=1; step="select"; material=""; prep_round=0; hold_progress=0; feedback=""
		_refresh_stock(); bench.hide(); _obstacles(false); mission.player.locked=false
		mission.say("阿木","放稳了！第一处通了，去接第二处。")
		mission.save_checkpoint()
	else:
		step="done"; active=false; completed_once=true; props.hide(); _obstacles(false); mission.player.locked=false
		mission.save_checkpoint(); mission.say("周班长","干得好！通道接上了，继续前进。 "); completed.emit(_result())

func _result()->Dictionary: return {"repaired":repaired.duplicate(),"rope_assist":rope_assist,"sites_completed":int(repaired[0])+int(repaired[1])}

func status()->Dictionary:
	var labels={"select":"检查木板，挑选合适材料","position":"定位木料" if prep_round==0 else "为裂纹加第二道横向支撑","tie":"按住绳索完成固定","check":"检查加固质量","pickup":"与阿木抬起木板","carry":"与阿木一起将木板送到金色标记", "join":"等待阿木到木板另一端", "npc_ready":"两端就位，准备一起抬", "lifting":"一起抬稳木板", "lowering":"一起放稳木板", "recover":"木板返回备料点","align":"将板端对准支撑","secure":"把桥板固定在支撑上","place_check":"检查桥板能否通行","done":"两处通道已接好"}
	var hints={"select":"靠近三类真实木板 · E 检查/选择","position":"A/D 横移至白区，再按 E · R 取消" if prep_round==0 else "W/S 调整横档，再按 E","tie":"按住 E 固定 · A/D 调张力","check":"Space 检查固定结果","pickup":"靠近木板端部 · E 呼叫阿木","carry":"WASD 搬运 · 金色标记处 E 放下 · R 取消重试", "join":"可以自由移动 · 在板端等候 · R 取消", "npc_ready":"即将一起抬板 · R 取消", "lifting":"正在共同抬起 · R 取消", "lowering":"正在共同放下 · R 取消", "recover":"已恢复自由行动 · 回备料点 E 重试","align":"A/D 横移 → E" if site==0 else "A/D 横移 + W/S 纵向/角度 → E","secure":"按住 E 固定 · A/D 调张力","place_check":"Space 检查并开放通行","done":"通道固定完成"}
	var progress_values={"select":.0,"position":.12,"tie":.26,"check":.38,"pickup":.44,"join":.46,"npc_ready":.48,"lifting":.50,"lowering":.68,"recover":.44,"carry":.58,"align":.73,"secure":.84,"place_check":.94,"done":1.0}
	var waypoint:Vector3=material_position("good") if step=="select" else (pickup_position() if step in ["pickup","join","npc_ready","lifting"] else safe_position())
	if step in ["carry","align","secure","place_check"]: waypoint=mission.world.get_v2_gap(site).approach
	var detail="%d/2处已通 · %s\n%s"%[int(repaired[0])+int(repaired[1]),"裂板加固后可获通行绳辅助" if material=="cracked" else "好板减少一道准备工序",feedback]
	if step in ["position","align"]: detail+="\n横移 %.2f%s"%[lateral," · 纵向 %.2f"%depth if site==1 or prep_round>0 else ""]
	if step in ["tie","secure"]: detail+="\n固定 %d%% · 张力 %d%%（22—82白区）"%[int(hold_progress/1.4*100),int(tension*100)]
	return {"objective":"%s · %s"%[mission.world.get_v2_gap(site).title,labels.get(step,"修复通道")],"hint":hints.get(step,"E 交互"),"progress":1.0 if step=="done" else (float(site)+progress_values.get(step,0.0))*.5,"detail":detail,"waypoint":waypoint+Vector3(0,1.2,0)}

func snapshot()->Dictionary:
	var safe_step="pickup" if step in ["carry","align","secure","place_check","join","npc_ready","lifting","lowering","recover","preparing","auto_secure","parked"] else step
	if step=="preparing": safe_step="select"
	var safe=safe_position()
	return {"site":site,"step":safe_step,"material":material,"repaired":repaired.duplicate(),"rope_assist":rope_assist,"prep_round":prep_round,"lateral":lateral,"depth":depth,"safe_position":[safe.x,safe.y,safe.z]}

func _obstacles(enabled:bool):
	for body in obstacle_bodies:
		body.collision_layer=1 if enabled else 0
		body.get_parent().visible=enabled

func stop():
	active=false
	if not mission: return
	mission.player.carrying=false; mission.player.locked=false
	helper_path.clear(); state_clock=0; helper_stalled=0
	mission.player.visual.hand_targets=[]; mission.player.visual.mode="idle"
	mission.player.visual.carry_anchor.position=Vector3(0,1.14,1.48)
	mission.amu.visual.hand_targets=[]; mission.amu.fixed_pose=""; mission.amu.moving=false
	if active_board:
		if active_board.get_parent()!=self: active_board.reparent(self,false)
		active_board.hide()
	if props: props.hide()
	_obstacles(false)

func suspend_carry():
	if step!="carry": return
	carry_from_park=true; parked_origin=active_board.global_transform
	mission.player.carrying=false; mission.player.locked=false
	mission.player.visual.hand_targets=[]; mission.player.visual.mode="idle"
	mission.amu.visual.hand_targets=[]; mission.amu.fixed_pose="idle"; mission.amu.visual.speed=0
	_set_step("parked","已放下木板；右键掩护，靠近板端E续搬")
