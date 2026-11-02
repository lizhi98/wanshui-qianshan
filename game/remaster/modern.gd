extends Node3D
var mission
var active := false
var scanned: Array[int]=[]
var scan_points: Array[Vector3]=[Vector3(-10,7,-10),Vector3(14,10,-39),Vector3(-9,7,-72)]
var selected := 0
var camera: Camera3D
var yaw := 0.0
var pitch := -.22
var radius := 50.0
var target := Vector3(0,0,-39)
var travelling := false
var travel_goal := Vector3.ZERO
var reconstruction: Node3D
var historic := false
var layer_visible := true
var orbit_mode := false
func _ready():
	camera=Camera3D.new()
	camera.far=600
	camera.fov=58
	add_child(camera)
	reconstruction=Node3D.new()
	mission.add_child(reconstruction)
func start():
	active=true
	position=Vector3(-18,11,-7)
	camera.current=true
	mission.player.locked=true
	for actor in [mission.player,mission.amu,mission.zhou]+mission.enemies+mission.marchers: actor.hide()
	if not mission.world.modern_mode: mission.world.set_modern()
	mission.world.modern_deck.show()
	historic=false
	layer_visible=true
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	mission.hud.show_modern()
	_build_layers()
func stop():
	active=false
	mission.view.camera.current=true
	reconstruction.hide()
func select_point(index: int):
	if index<0 or index>=3: return
	selected=index
	travel_goal=scan_points[index]
	travelling=true
	orbit_mode=false
func collect() -> bool:
	if not active or selected in scanned or position.distance_to(scan_points[selected])>3.2: return false
	scanned.append(selected)
	_build_layers()
	mission.audio.dialogue_tick()
	mission.tasks["scan%d"%selected]=true
	mission.hud.dialogue("数字记录",["底索层已建立：九根底索承担桥面荷载。","扶索层已建立：两侧共四根扶索，辅助通行与稳定。","桥面层已建立：木板把分散的承载结构连成道路。"][selected])
	mission.save_checkpoint()
	return true
func compare():
	historic=not historic
	mission.world.modern_deck.visible=not historic
	mission.hud.dialogue("场景对照","1935 剧情场景：桥板缺失与修复痕迹。" if historic else "数字重建场景：完整桥面。艺术化尺寸，非现场测绘成果。")
func toggle_layer():
	layer_visible=not layer_visible
	reconstruction.visible=layer_visible
func orbit():
	orbit_mode=true
	travelling=false
	var difference=position-target
	radius=clampf(difference.length(),10,110)
	yaw=atan2(difference.x,difference.z)
	pitch=clampf(-asin(difference.y/radius),-.9,-.07)
func inspect_structure(kind: int):
	mission.hud.dialogue("结构档案",["底索：九根铁索位于桥面下方。游戏采用缩短跨度与放大的链环，便于观察结构。","扶索：左右各两根，共四根。历史桥梁的桥面与扶索共同构成通行空间。","木板：剧情中的修补过程表现普通战士协作，并非对真实战斗细节的逐项复原。"][kind])
func _build_layers():
	for child in reconstruction.get_children(): child.queue_free()
	if scanned.is_empty(): return
	var mat=StandardMaterial3D.new()
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color=Color("72d9cb")
	mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a=.55
	for c in 13:
		if c<9 and not 0 in scanned: continue
		if c>=9 and not 1 in scanned: continue
		var x=-1.6+c*.4 if c<9 else (-1.86 if c<11 else 1.86)
		var y=.08 if c<9 else (.84 if c%2==1 else 1.54)
		var line=MeshInstance3D.new()
		var cylinder=CylinderMesh.new()
		cylinder.top_radius=.045
		cylinder.bottom_radius=.045
		cylinder.height=78
		cylinder.radial_segments=8
		line.mesh=cylinder
		line.material_override=mat
		line.rotation.x=PI/2
		line.position=Vector3(x,y,-39)
		reconstruction.add_child(line)
	if 2 in scanned:
		for i in 40:
			var plank=MeshInstance3D.new()
			var mesh=BoxMesh.new()
			mesh.size=Vector3(3.5,.04,.20)
			plank.mesh=mesh
			plank.material_override=mat
			plank.position=Vector3(0,.13,-i*2)
			reconstruction.add_child(plank)
	reconstruction.visible=layer_visible
func _unhandled_input(event):
	if not active or mission.paused: return
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if not orbit_mode: orbit()
		yaw-=event.relative.x*.006
		pitch=clampf(pitch-event.relative.y*.004,-1.0,-.05)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP:
			if not orbit_mode: orbit()
			radius=maxf(8,radius-3)
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN:
			if not orbit_mode: orbit()
			radius=minf(120,radius+3)
func _process(delta):
	if not active or mission.paused: return
	if Input.is_action_just_pressed("interact"): collect()
	if travelling:
		position=position.move_toward(travel_goal,delta*16)
		if position.distance_to(travel_goal)<.1: travelling=false
	elif orbit_mode:
		yaw+=Input.get_axis("move_left","move_right")*delta*.65
		radius=clampf(radius+Input.get_axis("move_forward","move_back")*delta*13,8,120)
		position=target+Vector3(sin(yaw)*cos(pitch),-sin(pitch),cos(yaw)*cos(pitch))*radius
	else:
		var movement=Vector3(Input.get_axis("move_left","move_right"),0,Input.get_axis("move_forward","move_back"))
		movement=movement.rotated(Vector3.UP,rotation.y)
		position+=movement*delta*8
		if Input.is_physical_key_pressed(KEY_Q): position.y+=delta*6
		if Input.is_physical_key_pressed(KEY_Z): position.y-=delta*6
		position.y=clampf(position.y,2,35)
	look_at(target,Vector3.UP)
	mission.hud.update_modern(scanned.size(),selected,position.distance_to(scan_points[selected]),scanned.size()==3)
