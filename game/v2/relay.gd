extends Node3D
signal completed(result:Dictionary)
var mission
var active:=false
var phase:="observe"
var observed:=false
var clear:=false
var angle:=-.55
var pull:=0.0
var observation:=0.0
var feedback:=""
var wait_clock:=0.0
var barrier:MeshInstance3D
var rope:MeshInstance3D
var camera:Camera3D
var saved_fov:=66.0
const WINCH=Vector3(1.05,.05,-75.4)
const AMU_GRIP=Vector3(-.65,0,-76.0)
const ZHOU_GRIP=Vector3(.65,0,-76.0)
const CONFIRM=Vector3(0,.05,-80.5)
func setup(owner_mission):
	mission=owner_mission
	if barrier: return
	camera=mission.view.get_node("Camera")
	saved_fov=camera.fov
	var wood=_material(Color("8f704b"))
	var iron=_material(Color("505b5b"))
	barrier=_box("Fallen_relay_crossbar",Vector3(3.45,.22,.24),Vector3(0,.55,-77.2),wood,true)
	for x in [-1.7,1.7]: _box("Relay_guide_post",Vector3(.10,2.05,.10),Vector3(x,.95,-77.2),iron,true)
	rope=_box("Relay_rope",Vector3(.035,.035,2.0),Vector3(.95,.93,-76.2),_material(Color("cab67c")),false)
	_box("Relay_winch",Vector3(.45,.7,.55),Vector3(1.15,.35,-75.4),wood,false)
	_render()
func start(state:Dictionary={}):
	active=true
	observed=bool(state.get("observed",false))
	clear=bool(state.get("clear",false))
	angle=clampf(float(state.get("angle",-.55)),-1,1)
	pull=1.0 if clear else 0.0
	observation=0; feedback=""; wait_clock=0
	phase="crossing" if clear else ("signal" if observed else "observe")
	mission.player.locked=false; mission.player.climbing=false; mission.player.carrying=false
	mission.player.visual.rotation=Vector3.ZERO; mission.player.visual.hand_targets=[]
	if state.has("actors"): _restore_actors(state.actors)
	if clear: _send_across()
	_render()
func stop():
	active=false
	camera.fov=saved_fov
	if not mission: return
	mission.player.locked=false; mission.player.visual.hand_targets=[]; mission.player.visual.mode="idle"
	for actor in [mission.amu,mission.zhou]: actor.visual.hand_targets=[]; actor.fixed_pose=""
func observation_point()->Vector3: return Vector3(0,.60,-77.2)
func tick(delta:float):
	if not active or mission.paused or mission.failed: return
	if phase=="observe":
		var inspecting=Input.is_action_pressed("observe")
		camera.fov=lerpf(camera.fov,42.0 if inspecting else saved_fov,minf(delta*8,1))
		if inspecting and _can_see_obstruction():
			observation=minf(1,observation+delta/ .85)
			if observation>=1:
				observed=true; phase="signal"; camera.fov=saved_fov
				mission.say("林川","横档落下来了。到绳轮边发信号，一起抬回去。")
				mission.save_checkpoint()
		else: observation=maxf(0,observation-delta*.5)
	elif phase=="signal":
		if Input.is_action_just_pressed("signal"):
			if mission.player.position.distance_to(WINCH)<3:
				_walk_to_grip(mission.amu,AMU_GRIP)
				_walk_to_grip(mission.zhou,ZHOU_GRIP)
				phase="ready"; wait_clock=0
				mission.say("周班长","收到！你来引绳，我们托住横档。")
			else: feedback="靠近右侧绳轮，再按 Q 发信号。"
	elif phase in ["ready","pull"]:
		wait_clock+=delta
		for actor in [mission.amu,mission.zhou]:
			if not actor.moving and actor.position.distance_to(AMU_GRIP if actor==mission.amu else ZHOU_GRIP)<1.2:
				actor.fixed_pose="brace"; actor.face(mission.player.position)
		if wait_clock>18 and not _allies_ready():
			feedback="战友还没握住绳端。按 Q 重新给他们指路。"
			if Input.is_action_just_pressed("signal"):
				_walk_to_grip(mission.amu,AMU_GRIP); _walk_to_grip(mission.zhou,ZHOU_GRIP); wait_clock=0
		if phase=="pull":
			mission.player.position=mission.player.position.move_toward(WINCH,delta*1.6)
			mission.player.rotation.y=PI
			mission.player.visual.mode="brace"
			mission.player.visual.hand_targets=[Vector3(.85,.9,-75.75),Vector3(1.12,.9,-75.75)]
			angle=clampf(angle+Input.get_axis("move_left","move_right")*delta*.55,-1,1)
			if Input.is_action_pressed("interact") and absf(angle)<=.20: pull=minf(1,pull+delta/.28/10)
			if Input.is_action_just_pressed("jump"):
				if pull>=.999 and absf(angle)<=.20:
					if _allies_ready(): _clear_passage()
					else: feedback="横档已抬起，保持住，等两位战友握稳绳端。"
				else: feedback="先用 A / D 对齐引绳，再按住 E 拉起；完成后空格检查。"
	elif phase=="crossing":
		if _allies_across():
			phase="confirm"
			mission.say("阿木","我们过去了！到桥亭里确认后续通道。")
	_render()
func interact():
	if not active or mission.paused or mission.failed: return
	match phase:
		"ready":
			if mission.player.position.distance_to(WINCH)<2:
				phase="pull"; mission.player.locked=true
			else: feedback="到右侧绳轮前握住引绳。"
		"confirm":
			if mission.player.position.z<-78.2 and mission.player.position.distance_to(CONFIRM)<2.2:
				phase="done"; active=false
				completed.emit({"relay_clear":true,"allies_passed":true,"observed":true})
			else: feedback="通道已经打开，走到桥亭内确认两位战友平安通过。"
		"observe": feedback="先按住 F，把落下的横档放进观察准星。"
func _can_see_obstruction()->bool:
	if not barrier.visible or camera.global_position.distance_to(observation_point())>16: return false
	var direction=(observation_point()-camera.global_position).normalized()
	if (-camera.global_basis.z).dot(direction)<cos(deg_to_rad(7)): return false
	var query=PhysicsRayQueryParameters3D.create(camera.global_position,observation_point(),1)
	var hit=mission.get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or barrier.is_ancestor_of(hit.collider)
func _walk_to_grip(actor,goal:Vector3):
	var path=[]
	if actor.position.z>-54.4: path.append(Vector3(1.43,0,-54.4))
	if actor.position.z>-62.4: path.append(Vector3(1.43,0,-62.4))
	path.append(Vector3(goal.x,0,-73.5)); path.append(goal)
	actor.chain_from=-54.8; actor.chain_to=-62.2
	actor.walk(path,2.7)
func _allies_ready()->bool:
	return mission.amu.position.distance_to(AMU_GRIP)<1.2 and mission.zhou.position.distance_to(ZHOU_GRIP)<1.2 and not mission.amu.moving and not mission.zhou.moving
func _clear_passage():
	clear=true; pull=1; angle=0; phase="crossing"
	mission.player.locked=false; mission.player.visual.hand_targets=[]; mission.player.visual.mode="idle"
	for actor in [mission.amu,mission.zhou]: actor.visual.hand_targets=[]; actor.fixed_pose=""
	_render(); _send_across()
	mission.sound("res://assets/audio/wood.wav",-12)
	mission.save_checkpoint()
	mission.say("周班长","横档稳住了！让后面的同志接着走。")
func _send_across():
	mission.amu.walk([Vector3(-.65,0,-78.8),Vector3(-.65,0,-80.5)],2.1)
	mission.zhou.walk([Vector3(.65,0,-78.8),Vector3(.65,0,-81.0)],2.1)
func _allies_across()->bool:
	return mission.amu.position.z<-79.5 and mission.zhou.position.z<-79.5 and not mission.amu.moving and not mission.zhou.moving
func _render():
	if not barrier: return
	barrier.position.y=.55+pull*1.41
	barrier.rotation.z=0.0 if clear else angle*.20*(1-pull)
	rope.rotation.x=angle*.12
	rope.scale.z=1.0-pull*.18
func safe_position()->Vector3: return Vector3(0,.05,-78.7) if clear else WINCH
func snapshot()->Dictionary:
	var actors=[]
	for actor in [mission.amu,mission.zhou]: actors.append([actor.position.x,actor.position.y,actor.position.z])
	return {"phase":"crossing" if clear else ("signal" if observed else "observe"),"observed":observed,"clear":clear,"angle":angle,"actors":actors,"safe_position":[safe_position().x,safe_position().y,safe_position().z]}
func _restore_actors(data:Array):
	for i in mini(data.size(),2):
		var p=data[i]
		if p is Array and p.size()==3: [mission.amu,mission.zhou][i].position=Vector3(float(p[0]),float(p[1]),float(p[2]))
func status()->Dictionary:
	var objective="最后的接力 · 找出桥亭前的通行障碍"
	var hint="按住 F 观察落下的横档 · 自由转动镜头"
	var progress=observation
	var detail=feedback
	var point=observation_point()
	match phase:
		"signal": objective="在右侧绳轮发出协作信号"; hint="靠近绳轮 · Q 发信号"; point=WINCH
		"ready": objective="战友正在握住绳端 · 准备引绳"; hint="E 握住引绳 · 战友会按实际路线靠近"; point=WINCH; detail="阿木：%s　周班长：%s"%["就位" if mission.amu.position.distance_to(AMU_GRIP)<1.2 else "靠近中","就位" if mission.zhou.position.distance_to(ZHOU_GRIP)<1.2 else "靠近中"]
		"pull": objective="对齐引绳，与战友抬起横档"; hint="A / D 对齐 ±20% · 按住 E 拉起 · 空格检查"; progress=pull; point=WINCH; detail="引绳偏差 %+.0f%% · 抬起 %.0f%% · %s"%[angle*100,pull*100,feedback]
		"crossing": objective="保持通道，确认两位战友通过"; hint="可以移动 · 观察战友从刚打开的通道通过"; progress=.9; point=CONFIRM
		"confirm": objective="最后的接力 · 在桥亭确认通道"; hint="走过已抬起的横档 · E 确认"; progress=.95; point=CONFIRM
		"done": objective="道路相连 · 最后的接力完成"; hint=""; progress=1; point=CONFIRM
	return {"objective":objective,"hint":hint,"progress":progress,"detail":detail,"waypoint":point}
func _material(color:Color)->StandardMaterial3D:
	var mat=StandardMaterial3D.new(); mat.albedo_color=color; mat.roughness=.82; return mat
func _box(label:String,size_value:Vector3,pos:Vector3,mat:Material,solid:bool)->MeshInstance3D:
	var node=MeshInstance3D.new(); node.name=label; node.mesh=BoxMesh.new(); node.mesh.size=size_value; node.material_override=mat; add_child(node); node.position=pos
	if solid:
		var body=StaticBody3D.new(); body.collision_layer=1; node.add_child(body)
		var shape=CollisionShape3D.new(); shape.shape=BoxShape3D.new(); shape.shape.size=size_value; body.add_child(shape)
	return node
