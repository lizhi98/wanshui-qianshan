extends Node3D
signal completed(result:Dictionary)
const HOLD_TIME=1.1
const ROUTE_A=Vector3(-1.1,0,11.0)
const ROUTE_B=Vector3(3.7,0,11.3)
var mission
var active:=false
var observing:=false
var observation_camera:Camera3D
var targets:Dictionary={}
var found:Array[String]=[]
var route:=""
var focused:=""
var focus_progress:=0.0
var route_signs:Array[Node3D]=[]
var target_signs:Dictionary={}
var completion_sent:=false
var cover_body:StaticBody3D

func setup(m):
	mission=m
	if observation_camera: return
	observation_camera=Camera3D.new()
	observation_camera.name="V2ObservationCamera"
	observation_camera.fov=30
	observation_camera.near=.06
	observation_camera.far=600
	mission.view.add_child(observation_camera)
	observation_camera.position=Vector3(0,.25,-.35)
	observation_camera.current=false
	cover_body=_box("ReconCover",Vector3(3.4,.42,8),Vector3(1.75,.9,.85),mission.world.stone)
	var gap=Marker3D.new(); gap.name="BrokenBridgeSpan"; add_child(gap); gap.position=Vector3(0,.25,-9.4)
	var enemy=mission.enemies[0] if not mission.enemies.is_empty() else gap
	targets={"firepoint":{"anchor":enemy,"offset":Vector3(0,1.3,0),"title":"对岸火力点","hold":0.0},"gap":{"anchor":gap,"offset":Vector3.ZERO,"title":"桥面主要缺口","hold":0.0},"cover":{"anchor":cover_body,"offset":Vector3(0,.55,0),"title":"侧方安全掩体","hold":0.0}}
	for key in targets:
		var label=_label("?",target_point(key)+Vector3(0,.65,0),.15)
		target_signs[key]=label
	for entry in [[ROUTE_A,"A · 近桥短路\n掩体少 · E选择"],[ROUTE_B,"B · 侧方掩体\n需清通道 · E选择"]]:
		var marker=Node3D.new(); add_child(marker); marker.position=entry[0]
		var pole=_box("RoutePost",entry[0]+Vector3(0,.45,0),Vector3(.08,.9,.08),mission.world.material(Color("6e593f")),false)
		pole.reparent(marker,true)
		var sign=_label(entry[1],entry[0]+Vector3(0,1.25,0),.09); sign.reparent(marker,true)
		route_signs.append(marker); marker.hide()
	for label in target_signs.values(): label.hide()

func start(state:Dictionary={}):
	active=true; completion_sent=false; route=str(state.get("route","")); found.clear()
	for key in state.get("found",[]):
		if targets.has(key) and not key in found: found.append(key)
	for key in targets:
		targets[key].hold=0.0
		target_signs[key].text=targets[key].title if key in found else "?"
		target_signs[key].show()
	for marker in route_signs: marker.visible=found.size()==3
	focused=""; focus_progress=0
	if route in ["A","B"]: call_deferred("_emit_completed")

func target_point(key:String)->Vector3:
	if not targets.has(key): return Vector3.ZERO
	return targets[key].anchor.global_position+targets[key].offset

func _visible_target(key:String)->bool:
	var camera=observation_camera
	var point=target_point(key)
	var delta=point-camera.global_position
	if delta.length()<.8 or delta.length()>135: return false
	if (-camera.global_basis.z).dot(delta.normalized())<cos(deg_to_rad(3.2)): return false
	var query=PhysicsRayQueryParameters3D.create(camera.global_position,point,5)
	var hit=get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.collider==targets[key].anchor or camera.global_position.distance_to(hit.position)+.3>=delta.length()

func tick(delta:float):
	if not active or mission.paused or mission.failed: return
	if Input.is_action_just_pressed("observe"): _set_observing(not observing)
	if not observing or found.size()==3: return
	focused=""; var best=-1.0
	for key in targets:
		if key in found or not _visible_target(key): continue
		var score=(-observation_camera.global_basis.z).dot((target_point(key)-observation_camera.global_position).normalized())
		if score>best: best=score; focused=key
	for key in targets:
		if key==focused:
			targets[key].hold=minf(HOLD_TIME,float(targets[key].hold)+delta)
		else: targets[key].hold=maxf(0,float(targets[key].hold)-delta*.7)
	focus_progress=float(targets[focused].hold)/HOLD_TIME if not focused.is_empty() else 0.0
	if not focused.is_empty() and focus_progress>=1:
		found.append(focused); target_signs[focused].text="✓ "+targets[focused].title
		target_signs[focused].modulate=Color("91d4b4")
		mission.say("林川","发现："+targets[focused].title+"。")
		mission.save_checkpoint()
		if found.size()==3:
			for marker in route_signs: marker.show()
			mission.say("周班长","选近桥短路，或侧方掩体。到路牌处确认。")

func _set_observing(value:bool):
	observing=value
	if observing:
		mission.view.cinematic=false
		observation_camera.rotation=Vector3.ZERO
		observation_camera.make_current()
	else: mission.view.camera.make_current()

func interact():
	if not active or mission.paused or mission.failed or found.size()<3 or not route.is_empty(): return
	var a=mission.player.global_position.distance_to(ROUTE_A)
	var b=mission.player.global_position.distance_to(ROUTE_B)
	if minf(a,b)>1.65:
		mission.say("周班长","先走到A或B路牌旁，再确认路线。")
		return
	route="A" if a<b else "B"
	_set_observing(false)
	mission.save_checkpoint()
	_emit_completed()

func _emit_completed():
	if completion_sent or not route in ["A","B"]: return
	completion_sent=true
	completed.emit({"route":route,"choice":0 if route=="A" else 1,"found":found.duplicate()})

func status()->Dictionary:
	var detail="已发现 %d/3：火力点、断板缺口、安全掩体"%found.size()
	if not focused.is_empty(): detail+="\n正在辨认：%s  %d%%"%[targets[focused].title,int(focus_progress*100)]
	return {"objective":"桥头侦察 · 找出三个关键位置" if found.size()<3 else "选择接应路线 · 到A或B路牌确认","hint":"F 退出观察 · 自由转动视角，对准目标保持片刻" if observing else ("F 自由观察 · E 确认路线" if found.size()==3 else "F 进入观察 · 对准实物保持观察"),"progress":float(found.size())/3*.8+(0.2 if not route.is_empty() else 0.0),"detail":detail,"waypoint":Vector3(1.3,1,11.1) if found.size()==3 else Vector3(0,1,16)}

func snapshot()->Dictionary: return {"found":found.duplicate(),"route":route}
func stop():
	active=false; _set_observing(false)
	for marker in route_signs: marker.hide()
	for label in target_signs.values(): label.hide()
func _exit_tree():
	if is_instance_valid(observation_camera): observation_camera.queue_free()
func _label(text_value:String,pos:Vector3,font_scale:float)->Label3D:
	var label=Label3D.new(); label.text=text_value; label.font_size=44; label.pixel_size=.002*font_scale/.09; label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test=false; add_child(label); label.position=pos; return label
func _box(label:String,pos:Vector3,size_value:Vector3,material:Material,solid:=true)->Node3D:
	var body=StaticBody3D.new() if solid else Node3D.new(); body.name=label; add_child(body); body.position=pos
	var mesh=MeshInstance3D.new(); mesh.mesh=BoxMesh.new(); mesh.mesh.size=size_value
	mesh.material_override=material; body.add_child(mesh)
	if solid:
		var collider=CollisionShape3D.new(); collider.shape=BoxShape3D.new(); collider.shape.size=size_value; body.add_child(collider)
	return body
