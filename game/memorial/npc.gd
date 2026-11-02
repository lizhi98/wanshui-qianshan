extends "res://game/snow/npc.gd"
# One physical owner: route supplies intent, move_and_slide supplies translation.
var avoidance:NavigationAgent3D
var safe_velocity:=Vector3.ZERO
var avoidance_ready:=false
var pose_name:=""
var pace:=1.0
var march_index:=0
var horizontal_velocity:=Vector3.ZERO
var desired_speed:=0.0
var actual_speed:=0.0
var facing_target:=Vector3.ZERO
var facing_time:=0.0
var follow_waiting:=false
var target_changes:=0
var motion_state:="Idle"
var path_origin:=Vector3.ZERO
var corridor_origin:=Vector3.ZERO
var corridor_index:=-1
var stalled_seconds:=0.0
var replan_cooldown:=0.0
var replan_history:Array=[]
var formation_detour:=false
var formation_wait:=0.0
var formation_cooldown:=0.0
const ACCELERATION=4.5
const BRAKING=6.5
const ARRIVAL=.16
func request_facing(point:Vector3):facing_target=point;facing_time=.18
func walk(points:Array,speed:=1.85):
 super.walk(points,speed);path_origin=position;pose_name="";facing_time=0
 corridor_index=-1;stalled_seconds=0
 formation_detour=false;formation_wait=0
 if avoidance and not points.is_empty():avoidance.target_position=points[-1]
func _physics_process(delta):
 if mission.paused or mission.failed or not mission.started:return
 var before=position;var before_yaw=rotation.y;var wanted=Vector3.ZERO;var direction=Vector3.ZERO;desired_speed=0
 facing_time=maxf(0,facing_time-delta)
 if pose_name.is_empty() and moving:
  # Consume reached intermediate points in this tick; never skip the motion tick.
  while route_index<route.size():
   var to_goal:Vector3=route[route_index]-position;to_goal.y=0
   var tolerance=ARRIVAL if route_index==route.size()-1 else (.12 if formation_detour else .42)
   var previous:Vector3=path_origin if route_index==0 else route[route_index-1]
   var incoming:Vector3=route[route_index]-previous;incoming.y=0
   var beyond=(position-route[route_index]).dot(incoming.normalized())>0 if incoming.length()>.01 else false
   var passed=not formation_detour and route_index<route.size()-1 and beyond and to_goal.length()<.95
   if to_goal.length()>tolerance and not passed:break
   route_index+=1;target_changes+=1
  if route_index>=route.size():moving=false
  else:
   var to_goal:Vector3=route[route_index]-position;to_goal.y=0
   # Stay in the current path segment's walkable corridor. A long diagonal to
   # its endpoint can strand a passing actor below a steep bank after a bend.
   var segment_start:Vector3=path_origin if route_index==0 else route[route_index-1]
   if corridor_index==route_index:segment_start=corridor_origin
   segment_start.y=0;var segment_end:Vector3=route[route_index];segment_end.y=0
   var flat_position=Vector3(position.x,0,position.z)
   var center=Geometry3D.get_closest_point_to_segment(flat_position,segment_start,segment_end)
   var remaining=segment_end-center
   var seek=center+remaining.normalized()*minf(1.2,remaining.length())
   direction=(seek-flat_position).normalized()
   desired_speed=minf(moving_speed*pace,3.2 if ("Commander" in str(name) or "Guard" in str(name)) else 1.85)
   if route_index==route.size()-1:desired_speed=minf(desired_speed,sqrt(maxf(0,2*BRAKING*(to_goal.length()-.07))))
   if mission.stage in ["MARCH","STORM","CONTINUE"] and not mission.flags.get("at_pass",false):
    var gap=mission.world.route.nearest(mission.player.position).s-follow_distance-mission.world.route.nearest(position).s
    if gap<.10:follow_waiting=true
    elif gap>.65:follow_waiting=false
    desired_speed=minf(desired_speed,maxf(0,gap*1.5))
    if follow_waiting:desired_speed=0
   var turn_error=absf(angle_difference(rotation.y,atan2(direction.x,direction.z)))
   desired_speed*=clampf(cos(turn_error),.0,1.0)
   wanted=direction*desired_speed
 if not pose_name.is_empty():wanted=Vector3.ZERO
 horizontal_velocity=horizontal_velocity.move_toward(wanted,(BRAKING if wanted.length()<horizontal_velocity.length() else ACCELERATION)*delta)
 if not moving and horizontal_velocity.length()<.04:horizontal_velocity=Vector3.ZERO
 if is_on_floor():vertical_speed=-.5
 else:vertical_speed-=25*delta
 avoidance.velocity=horizontal_velocity
 avoidance.avoidance_priority=1.0 if not pose_name.is_empty() or not moving else .5+float(abs(hash(str(name)))%7)*.025
 var resolved=safe_velocity if avoidance_ready else Vector3.ZERO
 if not pose_name.is_empty():resolved=Vector3.ZERO
 velocity=resolved+Vector3.UP*vertical_speed;apply_floor_snap();move_and_slide()
 actual_speed=Vector2(position.x-before.x,position.z-before.z).length()/maxf(.00001,delta)
 _check_corridor_progress(delta,wanted)
 _check_formation_approach(delta,before)
 if facing_time>0:
  var toward=facing_target-position;rotation.y=rotate_toward(rotation.y,atan2(toward.x,toward.z),delta*2.8)
 elif direction.length()>.1:rotation.y=rotate_toward(rotation.y,atan2(direction.x,direction.z),delta*3.5)
 elif not moving and mission.stage in ["DISCOVERY","SALUTE"] and self!=mission.quartermaster:
  var toward=mission.quartermaster.position-position;rotation.y=rotate_toward(rotation.y,atan2(toward.x,toward.z),delta*1.8)
 visual.pose(pose_name);visual.speed=actual_speed;visual.armed=false
 visual.mode="pickup" if pose_name=="inspect" else ("run" if actual_speed>2.3 else "walk" if actual_speed>.13 else "idle")
 motion_state="Interact" if pose_name!="" else "Run" if actual_speed>2.3 else "Walk" if actual_speed>.13 else "Turn" if direction.length()>.1 and moving else "Stop" if horizontal_velocity.length()>.05 else "Idle"
 visual.turning=absf(angle_difference(before_yaw,rotation.y))/maxf(.0001,delta)
 visual.rotation.z=lerpf(visual.rotation.z,-mission.weather.force_at(position).x*.04,delta*3)
func snapshot()->Dictionary:
 var data=super.snapshot();data.pose=pose_name;data.coat=visual.coat_received;data.yaw=rotation.y;return data
func restore_snow(data:Dictionary):
 if has_meta("formation_yielded"):remove_meta("formation_yielded")
 formation_detour=false;formation_wait=0;formation_cooldown=0
 super.restore_snow(data);horizontal_velocity=Vector3.ZERO;follow_waiting=false;pose_name=data.get("pose","");visual.set_coat(data.get("coat",false));visual.pose(pose_name);rotation.y=float(data.get("yaw",2.214 if pose_name=="seated" else rotation.y))
 replan_history.clear();stalled_seconds=0;replan_cooldown=0;corridor_index=-1
 safe_velocity=Vector3.ZERO
 if avoidance:avoidance.set_velocity_forced(Vector3.ZERO)
func restore():
 if has_meta("formation_yielded"):remove_meta("formation_yielded")
 formation_detour=false;formation_wait=0;formation_cooldown=0
 super.restore();horizontal_velocity=Vector3.ZERO;follow_waiting=false;facing_time=0;actual_speed=0
 replan_history.clear();stalled_seconds=0;replan_cooldown=0;corridor_index=-1
 safe_velocity=Vector3.ZERO
 if avoidance:avoidance.set_velocity_forced(Vector3.ZERO)

func _ready():
 super._ready();avoidance=NavigationAgent3D.new();add_child(avoidance);avoidance.radius=.34;avoidance.height=1.7;avoidance.neighbor_distance=3.0;avoidance.max_neighbors=16;avoidance.time_horizon_agents=.7;avoidance.max_speed=3.2;avoidance.avoidance_priority=.5+float(abs(hash(str(name)))%7)*.025;avoidance.avoidance_enabled=true;avoidance.velocity_computed.connect(_receive_safe_velocity)
 avoidance.target_position=global_position+Vector3(1000,0,1000)
func _receive_safe_velocity(value:Vector3):safe_velocity=Vector3(value.x,0,value.z);avoidance_ready=true
func _check_formation_approach(delta:float,before:Vector3):
 formation_cooldown=maxf(0,formation_cooldown-delta)
 if mission.stage!="CONTINUE" or not mission.flags.get("at_pass",false) or not moving or route.is_empty():formation_wait=0;return
 var goal:Vector3=route[-1];var d=Vector2(goal.x-position.x,goal.z-position.z)
 if d.length()>5 or formation_cooldown>0:return
 if not formation_detour and route_index!=route.size()-1:return
 var progress=Vector2(position.x-before.x,position.z-before.z).dot(d.normalized())/maxf(.00001,delta)
 if progress>.06:formation_wait=0;return
 formation_wait+=delta
 if formation_wait<2.5:return
 var obstacles:Array=[]
 for a in mission.actors()+[mission.director.commander,mission.director.guard,mission.player]:
  if a==self or absf(a.position.y-position.y)>2.5:continue
  if a!=mission.player and a.moving:continue
  var c=Vector2(a.position.x,a.position.z)
  if c.distance_to(Vector2(position.x,position.z))<7:obstacles.append(c)
 var points=load("res://game/memorial/formation_path.gd").new().plan(Vector2(position.x,position.z),Vector2(goal.x,goal.z),obstacles)
 formation_wait=0;formation_cooldown=7
 if points.is_empty():
  _request_formation_yield(goal)
  return
 var start=position;var new_route:Array=[]
 for p in points:
  var v=Vector3(p.x,0,p.y);v.y=mission.world.height_at(v);new_route.append(v)
 walk(new_route,moving_speed);formation_detour=true;path_origin=start
 replan_history.append({"kind":"formation_detour","time":mission.elapsed,"position":str(start),"goal":str(goal),"waypoints":points.size()})
 print("NPC_FORMATION_DETOUR ",name," ",replan_history[-1])
func _request_formation_yield(goal:Vector3):
 # A stopped pair can close a physical gap after another member entered it.
 # If no collision-free path exists, one standing comrade must actually step aside.
 var people=mission.actors()+[mission.director.commander,mission.director.guard,mission.player]
 var direction=Vector2(goal.x-position.x,goal.z-position.z).normalized()
 var best=INF;var selected=null;var destination=Vector3.ZERO
 var planner=load("res://game/memorial/formation_path.gd").new()
 for other in people:
  if other==self or other==mission.player or other.moving or other.pose_name!="" or other.has_meta("formation_yielded"):continue
  var origin=Vector2(other.position.x,other.position.z);var relative=origin-Vector2(position.x,position.z)
  if relative.length()>1.8 or relative.dot(direction)<0:continue
  var circles:Array=[]
  for a in people:
   if a!=other and absf(a.position.y-other.position.y)<2.5:circles.append(Vector2(a.position.x,a.position.z))
  circles.append(Vector2(goal.x,goal.z))
  for i in 16:
   var point=origin+Vector2.from_angle(TAU*float(i)/16)*1.1;var free=true
   if point.distance_to(Vector2(goal.x,goal.z))<.95:continue
   if point.distance_to(Vector2(mission.world.route.POINTS[mission.END_INDEX].x,mission.world.route.POINTS[mission.END_INDEX].z))>4.4:continue
   for c in circles:
    if point.distance_to(c)<.76:free=false;break
   if not free or not planner.clear(origin,point,circles,true):continue
   var score=relative.length()-relative.dot(direction)*.4+point.distance_to(Vector2(goal.x,goal.z))*.05
   if score<best:
    best=score;selected=other;destination=Vector3(point.x,0,point.y);destination.y=mission.world.height_at(destination)
 if selected==null:return
 selected.set_meta("formation_yielded",true);selected.walk([destination],1.15)
 replan_history.append({"kind":"formation_yield","time":mission.elapsed,"position":str(position),"goal":str(goal),"comrade":str(selected.name),"yield_destination":str(destination)})
 print("NPC_FORMATION_YIELD ",name," ",replan_history[-1])
func _check_corridor_progress(delta:float,wanted:Vector3):
 replan_cooldown=maxf(0,replan_cooldown-delta)
 if not moving or not pose_name.is_empty() or wanted.length()<.5 or actual_speed>.03:stalled_seconds=0;return
 # Waiting behind a real neighbour is ordinary queuing, not a navigation error.
 for other in mission.actors()+[mission.player,mission.director.commander,mission.director.guard]:
  if other!=self and absf(other.position.y-position.y)<1.0 and Vector2(other.position.x-position.x,other.position.z-position.z).length()<1.5:stalled_seconds=0;return
 stalled_seconds+=delta
 if stalled_seconds<1.5 or replan_cooldown>0:return
 refresh_corridor()
func refresh_corridor():
 # Same remaining waypoint, new approach segment from the physical position.
 # No transform correction, jump, waypoint consumption or task-state mutation.
 corridor_origin=position;corridor_index=route_index;stalled_seconds=0;replan_cooldown=3.0
 horizontal_velocity=Vector3.ZERO;safe_velocity=Vector3.ZERO
 avoidance.avoidance_enabled=false;avoidance.set_velocity_forced(Vector3.ZERO);avoidance.avoidance_enabled=true
 if route_index<route.size():avoidance.target_position=route[-1]
 replan_history.append({"time":mission.elapsed,"position":str(position),"waypoint":route_index})
 print("NPC_CORRIDOR_REPLAN ",name," ",replan_history[-1])
