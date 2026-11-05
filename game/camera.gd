# Camera follow/zoom smoothing derives from Kenney scripts/view.gd (MIT).
extends "res://scripts/view.gd"

var mission
var cinematic := true
var shake := 0.0
var aim_fov := 48.0
var sensitivity := 1.0
var scale_aim_sensitivity := false
var focus_grace := .15
var use_bridge_bounds:=true
const CAMERA_MASK=1|16|32
const HIDDEN_FROM_CAMERA=1<<19
var camera_shape=SphereShape3D.new()
var shoulder_side:=1.0
var shoulder_lock:=0.0
var hidden_actors:Dictionary={}

func _notification(what):
	if what==NOTIFICATION_WM_WINDOW_FOCUS_IN: focus_grace=.15

func _ready():
	camera_rotation = Vector3(-12, 0, 0)
	zoom = 4.5
	$Camera.fov = 66
	$Camera.cull_mask&=~HIDDEN_FROM_CAMERA
	camera_shape.radius=.22

func _input(event):
	if event is InputEventMouseMotion and focus_grace<=0 and not cinematic and not mission.paused and not mission.failed and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var input_scale = sensitivity * _aim_input_scale()
		camera_rotation.y -= event.relative.x*0.14*input_scale
		camera_rotation.x = clampf(camera_rotation.x-event.relative.y*0.12*input_scale, -54, 30)

func _aim_input_scale() -> float:
	# Match screen-space mouse travel as the aiming FOV blends in.
	if scale_aim_sensitivity and target and target.aiming:
		return clampf(tan(deg_to_rad(camera.fov)*.5)/tan(deg_to_rad(66.0)*.5), .2, 1.0)
	return 1.0

func _physics_process(delta):
	focus_grace=maxf(0,focus_grace-delta)
	if cinematic:
		return
	if mission.paused:
		return
	position = position.lerp(target.position+Vector3(0, 1.35, 0), minf(delta*8, 1.0))
	rotation_degrees.x = lerpf(rotation_degrees.x, camera_rotation.x, minf(delta*12, 1.0))
	rotation_degrees.y = lerp_angle(rotation_degrees.y*PI/180.0, camera_rotation.y*PI/180.0, minf(delta*12, 1.0))*180.0/PI
	var aim = target.aiming or mission.get("camera_observing")==true
	var distance = 3.0 if aim else 5.1
	if target.climbing: distance = 3.5
	shoulder_lock=maxf(0,shoulder_lock-delta)
	var offset=.48 if aim else .38
	var preferred=shoulder_side
	var on_bridge=use_bridge_bounds and target.position.z< -.8 and target.position.z> -77.5
	if on_bridge:
		var right=to_global(Vector3(offset,.12,distance))
		var left=to_global(Vector3(-offset,.12,distance))
		if absf(right.x)>1.5 and absf(left.x)+.2<absf(right.x): preferred=-1.0
		elif absf(left.x)>1.5 and absf(right.x)+.2<absf(left.x): preferred=1.0
	if shoulder_lock<=0 and preferred!=shoulder_side:
		shoulder_side=preferred; shoulder_lock=.65
	var shoulder=offset*shoulder_side
	var desired_local=Vector3(shoulder,.12,distance)
	var desired=to_global(desired_local)
	for gate_z in ([0.0,-78.0] if use_bridge_bounds else []):
		if (global_position.z-gate_z)*(desired.z-gate_z)<0 and absf(global_position.z-gate_z)<6:
			var fraction=absf(global_position.z-gate_z)/maxf(.001,absf(desired.z-global_position.z))
			desired_local.z=minf(desired_local.z,maxf(.45,distance*fraction-.65))
	var safe=_sweep_to(to_global(desired_local))
	var retracted=camera.global_position.distance_to(global_position)>safe.distance_to(global_position)+.04
	var blend=1.0 if retracted else 1-exp(-delta*7)
	var smoothed=camera.global_position.lerp(safe,blend)
	camera.global_position=_sweep_to(smoothed)
	shake = move_toward(shake, 0.0, delta*4.0)
	camera.rotation.x = sin(Time.get_ticks_msec()*0.07)*shake*0.02
	camera.fov = lerpf(camera.fov, aim_fov if aim else 66.0, minf(delta*8, 1.0))
	handle_input(delta)
	_fade_occluding_allies(delta)

func _sweep_to(destination:Vector3)->Vector3:
	var query=PhysicsShapeQueryParameters3D.new(); query.shape=camera_shape
	query.transform=Transform3D(Basis.IDENTITY,global_position)
	query.collision_mask=CAMERA_MASK; query.margin=.04
	# A camera-only decorative proxy may surround a legal player position.
	var inside=get_world_3d().direct_space_state.intersect_shape(query,12)
	var exclusions:Array[RID]=[]
	for hit in inside: exclusions.append(hit.rid)
	query.exclude=exclusions; query.motion=destination-global_position
	var result=get_world_3d().direct_space_state.cast_motion(query)
	var fraction=maxf(0,float(result[0])-.025)
	return global_position+query.motion*fraction

func handle_input(delta):
	var input = Vector3(Input.get_axis("camera_up", "camera_down"), Input.get_axis("camera_left", "camera_right"), 0)
	camera_rotation += input.limit_length(1.0)*rotation_speed*delta*_aim_input_scale()
	camera_rotation.x = clampf(camera_rotation.x, -54, 30)

func recoil():
	shake = 1.0
	camera_rotation.x += 0.85

func _fade_occluding_allies(delta:float):
	var actors=[mission.player,mission.amu,mission.zhou]
	if mission.get("marchers"): actors.append_array(mission.marchers)
	if mission.get("assault"): actors.append_array(mission.assault.pool)
	if mission.get("vanguard"): actors.append_array(mission.vanguard.fighters)
	if mission.get("battlefield") and mission.battlefield.active: actors.append_array(mission.battlefield.soldiers)
	var eye=camera.global_position
	var aim_end=eye-camera.global_basis.z*8
	for actor in actors:
		if not is_instance_valid(actor) or not actor.visible: continue
		var chest=actor.global_position+Vector3(0,1.1,0)
		var near=eye.distance_to(chest)
		var obstructs=false
		if actor==mission.player:
			obstructs=near<1.75
		else:
			var segment=Geometry3D.get_closest_point_to_segment(chest,eye,aim_end)
			obstructs=near<1.0 or (near<4.0 and chest.distance_to(segment)<.62)
		var id=actor.get_instance_id()
		var hold=maxf(0,float(hidden_actors.get(id,0))-delta)
		if obstructs: hold=.22
		hidden_actors[id]=hold
		for mesh in actor.visual.find_children("*","MeshInstance3D",true,false):
			if not mesh.has_meta("camera_original_layers"): mesh.set_meta("camera_original_layers",mesh.layers)
			mesh.transparency=0
			mesh.layers=HIDDEN_FROM_CAMERA if hold>0 else int(mesh.get_meta("camera_original_layers"))
