extends "res://game/npc.gd"
## Wetland adapter of V4.1.3 motion: one physical root owner, bounded turn,
## acceleration/braking and the same RVO radius/horizon. No snow-route coupling.
var avoidance:NavigationAgent3D
var safe_velocity:=Vector3.ZERO
var avoidance_ready:=false
var horizontal_velocity:=Vector3.ZERO
var vertical_speed:=0.0
var path_origin:=Vector3.ZERO
var actual_speed:=0.0
var motion_state:="Idle"
const ACCELERATION=4.5
const BRAKING=6.5
func _ready():
	super._ready()
	floor_snap_length=.3
	avoidance=NavigationAgent3D.new();add_child(avoidance)
	avoidance.radius=.34;avoidance.height=1.7;avoidance.neighbor_distance=3.0;avoidance.max_neighbors=16;avoidance.time_horizon_agents=.7;avoidance.max_speed=3.2
	avoidance.avoidance_priority=.5+float(abs(hash(str(name)))%7)*.025
	avoidance.avoidance_enabled=true;avoidance.velocity_computed.connect(func(v): safe_velocity=Vector3(v.x,0,v.z);avoidance_ready=true)
func walk(points:Array,speed:=1.85):
	super.walk(points,speed);path_origin=position
	if avoidance and not points.is_empty():avoidance.target_position=points[-1]
func _physics_process(delta):
	if dead or not mission or mission.paused or mission.failed or not mission.started:return
	var before=position;var wanted=Vector3.ZERO;var direction=Vector3.ZERO
	if moving:
		while route_index<route.size():
			var offset:Vector3=route[route_index]-position;offset.y=0
			if offset.length()>(.16 if route_index==route.size()-1 else .42):break
			route_index+=1
		if route_index>=route.size():moving=false
		else:
			var start:Vector3=path_origin if route_index==0 else route[route_index-1];start.y=0
			var finish:Vector3=route[route_index];finish.y=0
			var flat=Vector3(position.x,0,position.z)
			var center=Geometry3D.get_closest_point_to_segment(flat,start,finish)
			var remaining=finish-center;var seek=center+remaining.normalized()*minf(1.2,remaining.length())
			direction=(seek-flat).normalized()
			var speed_limit=minf(moving_speed,3.2)
			if route_index==route.size()-1:speed_limit=minf(speed_limit,sqrt(maxf(0,2*BRAKING*(flat.distance_to(finish)-.07))))
			speed_limit*=clampf(cos(angle_difference(rotation.y,atan2(direction.x,direction.z))),0,1)
			wanted=direction*speed_limit
	var posed=visual.posture in ["kneel","seated","rising","collapsed"]
	if posed: wanted=Vector3.ZERO;horizontal_velocity=Vector3.ZERO
	horizontal_velocity=horizontal_velocity.move_toward(wanted,(BRAKING if wanted.length()<horizontal_velocity.length() else ACCELERATION)*delta)
	if not moving and horizontal_velocity.length()<.04:horizontal_velocity=Vector3.ZERO
	vertical_speed=-.5 if is_on_floor() else vertical_speed-25*delta
	avoidance.velocity=horizontal_velocity
	avoidance.avoidance_priority=1.0 if posed or not moving else .5+float(abs(hash(str(name)))%7)*.025
	var resolved=safe_velocity if avoidance_ready else Vector3.ZERO
	if posed:resolved=Vector3.ZERO
	if is_on_floor() and resolved.length_squared()>.0001:
		var normal=get_floor_normal();velocity=resolved.slide(normal).normalized()*resolved.length()-normal*.1
	else:velocity=resolved+Vector3.UP*vertical_speed
	apply_floor_snap();move_and_slide()
	actual_speed=Vector2(position.x-before.x,position.z-before.z).length()/maxf(delta,.00001)
	if direction.length()>.1:rotation.y=rotate_toward(rotation.y,atan2(direction.x,direction.z),delta*3.5)
	visual.speed=actual_speed;visual.mode="run" if actual_speed>2.3 else ("walk" if actual_speed>.13 else (fixed_pose if fixed_pose!="" else "idle"))
	motion_state="Interact" if posed else ("Walk" if actual_speed>.13 else ("Turn" if direction.length()>.1 and moving else "Idle"))
func restore():
	super.restore();horizontal_velocity=Vector3.ZERO;safe_velocity=Vector3.ZERO;vertical_speed=0
	if avoidance:avoidance.set_velocity_forced(Vector3.ZERO)
