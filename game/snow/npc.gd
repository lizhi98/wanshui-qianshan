extends "res://game/npc.gd"
var vertical_speed:=0.0
var movement_clock:=0.0
var jumps:=0
var follow_distance:=2.6
func _ready():
	super._ready();floor_snap_length=.5;floor_max_angle=deg_to_rad(49)
func _physics_process(delta):
	if dead or mission.paused or mission.failed:return
	if not mission.started:return
	var input=Vector3.ZERO
	if moving and route_index<route.size():
		var goal:Vector3=route[route_index];var diff=goal-position;diff.y=0
		if diff.length()<.28:
			route_index+=1
			if route_index>=route.size():moving=false
		else:
			input=diff.normalized()*moving_speed
			if mission.stage in ["BLIZZARD","SUMMIT"] and not mission.flags.get("at_pass",false):
				if mission.world.route.nearest(position).s>mission.world.route.nearest(mission.player.position).s-follow_distance:input=Vector3.ZERO
			if mission.weather:visual.rotation.z=lerpf(visual.rotation.z,mission.weather.force_at(position).x*-.045,delta*4)
			rotation.y=rotate_toward(rotation.y,atan2(input.x,input.z),delta*4)
			var here=mission.world.route.nearest(position)
			var next=position+diff.normalized()*.8
			if mission.world.height_at(next)-position.y>.48 and is_on_floor():vertical_speed=6.4;jumps+=1
			var step_distance=mission.world.route.lengths[23]+5-here.s
			if step_distance>.6 and step_distance<1.35 and is_on_floor():vertical_speed=7.5;jumps+=1
			for center in mission.world.jump_centers:
				if center-here.s>.75 and center-here.s<1.25 and is_on_floor():vertical_speed=8.6;jumps+=1
			if vertical_speed>0 or not is_on_floor():input=diff.normalized()*4.2
	if is_on_floor() and vertical_speed<=0:vertical_speed=-.5
	else:vertical_speed-=25*delta
	velocity=Vector3(input.x,vertical_speed,input.z);move_and_slide()
	visual.speed=Vector2(velocity.x,velocity.z).length()
	visual.mode="jump" if not is_on_floor() else ("walk" if visual.speed>.15 else "idle")
	visual.armed=false
	movement_clock+=delta
	if not moving:visual.speed=0
func snapshot()->Dictionary:
	var points=[]
	for i in range(route_index,route.size()):points.append([route[i].x,route[i].y,route[i].z])
	return {"position":[position.x,position.y,position.z],"route":points,"speed":moving_speed,"moving":moving,"vertical_speed":vertical_speed}
func restore_snow(data:Dictionary):
	var p=data.get("position",[start_position.x,start_position.y,start_position.z]);position=Vector3(p[0],p[1],p[2]);vertical_speed=float(data.get("vertical_speed",0));velocity=Vector3.ZERO;reset_physics_interpolation()
	var points=[]
	for v in data.get("route",[]):points.append(Vector3(v[0],v[1],v[2]))
	walk(points,float(data.get("speed",2.7)));moving=bool(data.get("moving",not points.is_empty()))
