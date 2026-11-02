extends "res://game/snow/player.gd"
# CharacterBody is the only writer of player translation/yaw. Story requests a facing target.
var facing_target:=Vector3.ZERO
var facing_requested:=false
var heading_changes:=0
var walk_speed:=1.7
var run_speed:=3.8
var motion_state:="Idle"
var avoidance_presence:NavigationAgent3D
func request_facing(point:Vector3):facing_target=point;facing_requested=true
func _physics_process(delta):
 var before_yaw=rotation.y
 if climbing:super._physics_process(delta);return
 if locked:
  avoidance_presence.velocity=Vector3.ZERO
  movement_velocity=Vector3.ZERO;velocity=Vector3(0,-.5,0);apply_floor_snap();move_and_slide();visual.speed=0
  if facing_requested:
   var d=facing_target-position
   rotation.y=rotate_toward(rotation.y,atan2(d.x,d.z),delta*2.8);rotation_direction=rotation.y
  visual.turning=absf(angle_difference(before_yaw,rotation.y))/maxf(.0001,delta);motion_state="Turn" if visual.turning>.20 else "Idle"
  facing_requested=false;return
 handle_controls(delta);handle_gravity(delta)
 movement_velocity=avoid_people(movement_velocity,delta)
 var applied_velocity=velocity.lerp(movement_velocity,minf(delta*10,1.0));applied_velocity.y=-gravity;velocity=applied_velocity
 move_and_slide()
 avoidance_presence.velocity=Vector3(velocity.x,0,velocity.z)
 var horizontal=Vector2(velocity.x,velocity.z)
 if horizontal.length()>.08:rotation_direction=atan2(horizontal.x,horizontal.y)
 rotation.y=rotate_toward(rotation.y,rotation_direction,delta*3.5)
 handle_effects(delta)
 visual.turning=absf(angle_difference(before_yaw,rotation.y))/maxf(.0001,delta)
 motion_state="Carry" if carrying else "Aim" if aiming else "Run" if visual.mode=="run" else "Stop" if movement_velocity.length()<.10 and visual.speed>.10 else "Walk" if visual.speed>.10 else "Turn" if visual.turning>.20 else "Idle"
 if position.y< -5:damage(1000)
 previously_floored=is_on_floor();facing_requested=false

func handle_controls(delta):
 super.handle_controls(delta)
 if not carrying and not aiming:
  var wind=mission.weather.force_at(position) if mission.weather else Vector3.ZERO
  var speed_scale=run_speed/4.8 if Input.is_action_pressed("sprint") else walk_speed/(3.1*.83)
  movement_velocity=(movement_velocity-wind)*speed_scale+wind

func _ready():
 super._ready();collision_mask=1|16
 avoidance_presence=NavigationAgent3D.new();add_child(avoidance_presence);avoidance_presence.radius=.34;avoidance_presence.height=1.7;avoidance_presence.neighbor_distance=3.0;avoidance_presence.max_speed=4.0;avoidance_presence.avoidance_priority=1.0;avoidance_presence.avoidance_enabled=true;avoidance_presence.target_position=global_position+Vector3(1000,0,1000)

func avoid_people(wanted:Vector3,_delta:float)->Vector3:
 if not mission or not mission.get("director"):return wanted
 for other in mission.actors()+[mission.director.commander,mission.director.guard]:
  if absf(other.position.y-position.y)>.9:continue
  var away=position-other.position;away.y=0;var distance=away.length()
  if distance>.01 and distance<.72:
   var toward=-away/distance;var component=wanted.dot(toward)
   if component>0:wanted-=toward*component*(1-smoothstep(.57,.72,distance))
 return wanted
