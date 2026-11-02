extends "res://game/player.gd"
var fall_top:=0.0
var wind_accumulated:=0.0
func _ready():
	super._ready();floor_snap_length=.45;floor_max_angle=deg_to_rad(49);jump_strength=8.0
func handle_controls(delta):
	super.handle_controls(delta)
	if not Input.is_action_pressed("sprint"):movement_velocity*=.83
	if mission.weather:
		var force=mission.weather.force_at(position)
		movement_velocity*=1-mission.weather.exposure*.22
		movement_velocity+=force
		wind_accumulated+=force.length()*delta
		visual.rotation.z=lerpf(visual.rotation.z,-force.x*.055,delta*5)
		visual.rotation.x=lerpf(visual.rotation.x,-force.length()*.035,delta*5)
func handle_effects(delta):
	super.handle_effects(delta)
	if is_on_floor():
		if not previously_floored and fall_top-position.y>4.6:mission.fail("失足跌落，回到最近的避风点。")
		fall_top=position.y
	else:fall_top=maxf(fall_top,position.y)
func jump():
	if is_on_floor():
		super.jump();mission.stats["jumps"]+=1
func restore(pos:Vector3):
	super.restore(pos);fall_top=pos.y
