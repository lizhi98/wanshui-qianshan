extends Node3D
signal completed(result:Dictionary)
const START_A=Vector3(.9,0,11.8)
const START_B=Vector3(3.7,0,11.8)
var mission
var active:=false
var route:="A"
var leg:=0
var moving:=false
var assembling:=false
var waiting_for_cover:=false
var window_remaining:=0.0
var blocker_cleared:=false
var blocker_position=Vector3(4,0,9.5)
var supply_position=Vector3(-3.9,0,4)
var paths:Array=[]
var safe_position=START_A
var last_health:Array[int]=[]
var completion_sent:=false
var route_props:Dictionary={"A":[],"B":[]}
var blocker:StaticBody3D
var supply:Node3D
var markers:Array[Node3D]=[]

func setup(m):
	mission=m
	if blocker: return
	route_props.A.append(_box("ShortRouteCover",Vector3(-.7,.43,5.7),Vector3(1.6,.9,.85),mission.world.stone))
	for pos in [Vector3(3.6,.43,5.8),Vector3(3.6,.43,1.05),Vector3(6.0,.43,4.3)]: route_props.B.append(_box("SideRouteCover",pos,Vector3(1.45,.9,.8),mission.world.stone))
	blocker=_box("MovableCrate",blocker_position+Vector3(0,.43,0),Vector3(1.0,.9,.8),mission.world.material(Color("795a3c")))
	supply=_box("AmmunitionSupply",supply_position+Vector3(0,.35,0),Vector3(.8,.7,.65),mission.world.material(Color("5f644a")))
	var supply_label=Label3D.new(); supply_label.text="补给箱 · E补充弹药"; supply_label.font_size=42; supply_label.pixel_size=.002; supply_label.position=Vector3(0,.8,0); supply_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; supply.add_child(supply_label)
	for body in route_props.A+route_props.B+[blocker,supply]: _set_prop(body,false)

func start(state:Dictionary={}):
	route=str(state.get("route","B" if int(state.get("choice",0))==1 else "A"))
	if not route in ["A","B"]: route="A"
	leg=clampi(int(state.get("leg",0)),0,2)
	blocker_cleared=bool(state.get("blocker_cleared",route=="A"))
	paths=[[Vector3(.9,0,9.2),Vector3(.9,0,6.8)],[Vector3(1.1,0,4.7),Vector3(1.7,0,2.0)]] if route=="A" else [[Vector3(4.85,0,11.8),Vector3(4.85,0,6.9),Vector3(3.6,0,6.9)],[Vector3(4.85,0,6.9),Vector3(4.85,0,2.3),Vector3(3.6,0,2.1)]]
	safe_position=(START_A if route=="A" else START_B) if leg==0 else paths[leg-1][-1]
	for name_value in route_props:
		for body in route_props[name_value]: _set_prop(body,name_value==route)
	_set_prop(blocker,route=="B" and not blocker_cleared)
	supply_position=Vector3(-3.9,0,4) if route=="A" else Vector3(5.8,0,13)
	supply.position=supply_position+Vector3(0,.35,0); _set_prop(supply,true)
	var health_state=state.get("enemy_health",[])
	last_health.clear()
	for i in mission.enemies.size():
		var enemy=mission.enemies[i]
		if i<health_state.size():
			enemy.health=clampi(int(health_state[i]),0,100); enemy.dead=enemy.health==0
			enemy.collision_layer=0 if enemy.dead else 4
			enemy.visual.mode="dead" if enemy.dead else "aim"
		last_health.append(enemy.health)
	moving=false; waiting_for_cover=false; window_remaining=0; completion_sent=false
	mission.amu.visual.armed=false
	if state.has("leg"):
		# Restore only to the last reached cover. Ordinary advances always walk.
		mission.amu.position=safe_position; mission.amu.moving=false; assembling=false
	else:
		assembling=mission.amu.position.distance_to(safe_position)>.35
		if assembling: mission.amu.walk([safe_position],1.85)
	active=leg<2
	if leg==2: call_deferred("_emit_completed")

func _threat(): return mission.enemies[mini(leg,mission.enemies.size()-1)] if not mission.enemies.is_empty() else null
func _inactive_threat()->bool:
	var enemy=_threat()
	return not is_instance_valid(enemy) or enemy.dead or enemy.health<=0

func tick(delta:float):
	if not active or mission.paused or mission.failed: return
	window_remaining=maxf(0,window_remaining-delta)
	var enemy=_threat()
	if is_instance_valid(enemy):
		var index=mission.enemies.find(enemy)
		if enemy.health<last_health[index]: window_remaining=3.2
		last_health[index]=enemy.health
	if _inactive_threat(): window_remaining=3.2
	if assembling:
		if not mission.amu.moving and mission.amu.position.distance_to(safe_position)<.4: assembling=false
		return
	if moving:
		if window_remaining<=0 and not _inactive_threat():
			if not waiting_for_cover: mission.say("阿木","火力又抬头了，我先停住！")
			waiting_for_cover=true; mission.amu.moving=false; mission.amu.visual.speed=0
		elif waiting_for_cover:
			waiting_for_cover=false; mission.amu.moving=true
		if not waiting_for_cover and not mission.amu.moving and mission.amu.position.distance_to(paths[leg][-1])<.4:
			safe_position=paths[leg][-1]; moving=false; leg+=1; window_remaining=0
			mission.say("阿木","到了！" if leg==1 else "物资接应到位，可以准备修桥！")
			mission.save_checkpoint()
			if leg==2: active=false; _emit_completed()
		return
	if Input.is_action_just_pressed("signal"): _signal_advance()

func _signal_advance():
	if leg>=2 or moving or assembling: return
	if route=="B" and not blocker_cleared:
		mission.say("阿木","侧路的木箱挡住了，先挪开它。")
		return
	if window_remaining<=0:
		mission.say("周班长","先压住当前火力点，再发转移信号。")
		return
	mission.amu.walk(paths[leg],1.75)
	moving=true; waiting_for_cover=false
	mission.say("阿木","收到，掩护我转移！")

func interact():
	if not active or mission.paused or mission.failed: return
	if route=="B" and not blocker_cleared and mission.player.position.distance_to(blocker_position)<1.9:
		blocker_cleared=true; _set_prop(blocker,false)
		mission.say("林川","木箱挪开了，侧路能通过。")
		mission.save_checkpoint()
		return
	if mission.player.position.distance_to(supply_position)<1.8:
		mission.combat.ammo=5; mission.combat.reserve=maxi(30,mission.combat.reserve); mission.combat.reloading=false
		mission.say("林川","弹药补齐了。")

func status()->Dictionary:
	var objective="建立第%d次压制窗口"%(leg+1)
	var hint="瞄准射击当前火力点 · 窗口出现后按Q发信号"
	var detail="已推进 %d/2 · 路线%s\n安全窗口 %.1f秒 · 补给箱旁E可反复补弹"%[leg,route,window_remaining]
	var waypoint=(_threat().position+Vector3(0,1.8,0)) if is_instance_valid(_threat()) else safe_position+Vector3.UP
	if assembling: objective="阿木正在接应位置就位"; hint="可以先寻找对岸射击角度"; waypoint=safe_position+Vector3.UP
	elif route=="B" and not blocker_cleared: objective="侧路受阻 · 清开木箱"; hint="靠近木箱按E挪开 · 再压制并发Q信号"; waypoint=blocker_position+Vector3.UP
	elif moving:
		objective="阿木在途中等待掩护" if waiting_for_cover else "继续掩护 · 阿木正在转移"
		hint="再次有效命中，阿木会继续前进" if waiting_for_cover else "保住压制窗口 · 弹尽可到补给箱E补充"
		waypoint=mission.amu.position+Vector3(0,1.8,0)
	elif window_remaining>0: objective="压制窗口已建立 · 发出转移信号"; hint="Q 示意阿木前往下一处掩体"
	if leg>=2: objective="两次接应推进完成"; hint="物资已到桥头"; waypoint=safe_position+Vector3.UP
	return {"objective":objective,"hint":hint,"detail":detail,"progress":float(leg)/2,"waypoint":waypoint}

func snapshot()->Dictionary:
	var health:Array[int]=[]
	for enemy in mission.enemies: health.append(enemy.health)
	return {"route":route,"leg":leg,"blocker_cleared":blocker_cleared,"enemy_health":health,"npc_safe_position":[safe_position.x,safe_position.y,safe_position.z]}
func _emit_completed():
	if completion_sent: return
	completion_sent=true; completed.emit(snapshot())
func stop():
	active=false
	if moving or assembling: mission.amu.moving=false; mission.amu.visual.speed=0
	moving=false; assembling=false; waiting_for_cover=false
	# Battle cover must not remain as invisible/solid clutter during repair.
	for body in route_props.A+route_props.B+[blocker,supply]: _set_prop(body,false)
func _set_prop(body:Node3D,value:bool):
	body.visible=value
	if body is StaticBody3D: body.collision_layer=1 if value else 0
func _box(label:String,pos:Vector3,size_value:Vector3,material:Material)->StaticBody3D:
	var body=StaticBody3D.new(); body.name=label; add_child(body); body.position=pos
	var mesh=MeshInstance3D.new(); mesh.mesh=BoxMesh.new(); mesh.mesh.size=size_value
	mesh.material_override=material; body.add_child(mesh)
	var collider=CollisionShape3D.new(); collider.shape=BoxShape3D.new(); collider.shape.size=size_value; body.add_child(collider)
	return body
