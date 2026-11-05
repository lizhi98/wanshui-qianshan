extends "res://game/v2/player.gd"
## Chapter adapter only: retains established input, gravity, collision sliding,
## facing smoothing and restore. Wetland surfaces multiply the base velocity.
var sink:=0.0
var scripted_destination:=Vector3.INF
var scripted_pace:=1.15
func walk_speed_multiplier() -> float:
	if mission and mission.story and mission.story.step=="leave": return 1.0
	return super.walk_speed_multiplier()
func walk_to(destination:Vector3,pace:float):scripted_destination=destination;scripted_pace=pace
func handle_controls(delta):
	super.handle_controls(delta)
	var ground=mission.world.surface_at(position)
	var factor={"grass":.86,"mud":.60,"shallow":.45,"swamp":.25}.get(ground,.86)
	movement_velocity*=factor
	if mission.story.step=="leave":movement_velocity=movement_velocity.limit_length(1.65)
func handle_effects(delta):
	var horizontal=Vector2(velocity.x,velocity.z).length()
	visual.speed=horizontal
	visual.walk_gait_scale=walk_speed_multiplier() if horizontal>.1 else 1.0
	visual.mode="walk" if horizontal>.1 else "idle"
	if not is_on_floor(): visual.mode="jump"
	if carrying: visual.mode="carry"
	step_time+=delta
	if horizontal>.4 and is_on_floor() and step_time>.55/walk_speed_multiplier():
		step_time=0; mission.sound("res://sounds/land.ogg",-31)
func _physics_process(delta):
	if scripted_destination!=Vector3.INF and mission and not mission.paused:
		visual.walk_gait_scale=1.0
		var direction=scripted_destination-position;direction.y=0
		if direction.length()<.13:scripted_destination=Vector3.INF;velocity=Vector3.ZERO;visual.speed=0;visual.mode="idle";return
		velocity=direction.normalized()*scripted_pace+Vector3.DOWN*.5;move_and_slide()
		rotation.y=rotate_toward(rotation.y,atan2(direction.x,direction.z),delta*2.8);rotation_direction=rotation.y;visual.speed=Vector2(velocity.x,velocity.z).length();visual.mode="walk";return
	super._physics_process(delta)
	if not mission or mission.paused or locked: return
	if mission.world.surface_at(position)=="swamp":
		sink+=delta/5.2
		mission.hud.terrain_warning="泥沼正在下陷 · 沿来路退回草甸"
		if sink>=1:
			mission.recover_from_swamp(); sink=0
	else:
		sink=move_toward(sink,0,delta*.8)
		mission.hud.terrain_warning="浅水 · 放慢脚步" if mission.world.surface_at(position)=="shallow" else ("湿泥 · 脚步变沉" if mission.world.surface_at(position)=="mud" else "")
	visual.position.y=-sink*.62
func restore(pos:Vector3):
	super.restore(pos)
	scripted_destination=Vector3.INF
	sink=0
	visual.position.y=0
