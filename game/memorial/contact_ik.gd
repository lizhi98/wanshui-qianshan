extends RefCounted
# After the authored full-body clip: only terrain/contact corrections, never a gait generator.
var visual
var responsive_player_feet := false
var contacts:Dictionary={}
var events:Array=[]
var clock:=0.0
var plant_serial:=0
var was_moving:=false
var stop_blend:=0.0
var pelvis_offset:=0.0
var debug_root
var max_reach_error:=0.0
const SOLE=.070
const PLANT_HEIGHT=.115
const RELEASE_HEIGHT=.145
const MAX_LOCK_OFFSET=.18
func setup(v):
 visual=v
 var actor=v.get_parent()
 responsive_player_feet=is_instance_valid(actor.mission) and actor==actor.mission.player
func reset(full:=false):
 contacts.clear();events.clear();was_moving=false;stop_blend=0
 if full:pelvis_offset=0
func probe(point:Vector3):
 return visual.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(point+Vector3.UP*.65,point-Vector3.UP*1.25,1))
func tick(delta):
 clock+=delta
 while events.size()>16:events.remove_at(0)
 var actor=visual.get_parent();var sk=visual.skeleton
 if actor.has_method("is_on_floor") and not actor.is_on_floor():reset();return
 var moving=visual.speed>.20 or visual.turning>.20;var goals={};var lower_target=0.0
 if was_moving and not moving:stop_blend=1.0
 if not moving:stop_blend=move_toward(stop_blend,0,delta/.25)
 else:stop_blend=0
 was_moving=moving
 for side in ["l","r"]:
  var bone=sk.find_bone("foot_"+side);var pose=sk.get_bone_global_pose(bone);var raw=sk.to_global(pose.origin);var hit=probe(raw)
  if hit.is_empty() or hit.normal.y<.55:continue
  var local_height=visual.to_local(raw).y
  var state:Dictionary=contacts.get(side,{"planted":false,"height":local_height,"point":hit.position,"normal":hit.normal,"released":false})
  if moving and state.has("stop_point"):
   state.erase("stop_point");state.planted=false;state.released=false
  var rising=local_height-float(state.height)>.003
  if local_height>visual.sole_offset(side)+.075:state.released=false
  if state.planted and moving and (local_height>visual.sole_offset(side)+.075 or Vector2(raw.x-state.point.x,raw.z-state.point.z).length()>MAX_LOCK_OFFSET):
   state.planted=false;state.released=true
  if not moving and stop_blend<=0:state.released=false
  if not state.planted and not state.has("stop_point") and not state.get("released",false) and (not moving or (local_height<visual.sole_offset(side)+.045 and not rising)):
   plant_serial+=1;state.plant_id=plant_serial;state.planted=true;state.point=hit.position;state.normal=hit.normal
   if moving:events.append({"side":side,"point":hit.position,"normal":hit.normal,"time":clock})
  state.height=local_height;state.raw_point=raw
  var goal=raw;var weight=0.0
  if state.planted:
   goal=state.point+Vector3.UP*visual.sole_offset(side);weight=1.0
  elif raw.y<hit.position.y+visual.sole_offset(side):
   goal.y=hit.position.y+visual.sole_offset(side);weight=1.0
  if not moving and stop_blend>0 and state.planted:
   goal=raw.lerp(state.point+Vector3.UP*visual.sole_offset(side),stop_blend);goal.y=maxf(goal.y,hit.position.y+visual.sole_offset(side));weight=1.0;state.planted=false;state.stop_point=state.point
  elif not moving and state.has("stop_point"):
   goal=raw.lerp(state.stop_point+Vector3.UP*visual.sole_offset(side),stop_blend);goal.y=maxf(goal.y,hit.position.y+visual.sole_offset(side));weight=1.0
   if stop_blend<=0:
    plant_serial+=1;state.plant_id=plant_serial;state.point=Vector3(raw.x,hit.position.y,raw.z);state.planted=true;state.erase("stop_point")
  if responsive_player_feet and moving:
   # Ease out the horizontal plant offset as the authored swing takes over.
   var offset=Vector3(goal.x-raw.x,0,goal.z-raw.z).limit_length(.055)
   var previous:Vector3=state.get("plant_offset",Vector3.ZERO)
   offset=previous.move_toward(offset,delta*.75)
   state.plant_offset=offset
   goal.x=raw.x+offset.x;goal.z=raw.z+offset.z
   var lift=maxf(0.0,hit.position.y+visual.sole_offset(side)-raw.y)
   var vertical=move_toward(float(state.get("plant_height_offset",0.0)),goal.y-raw.y,delta*.50)
   state.plant_height_offset=vertical
   goal.y=raw.y+maxf(vertical,lift)
   if offset.length_squared()>.000001 or absf(vertical)>.001:weight=1.0
  else:
   state.erase("plant_offset");state.erase("plant_height_offset")
  contacts[side]=state
  if weight>0:
   # A stopping foot interpolates horizontally too. Sample beneath the final
   # interpolated goal, not beneath the uncorrected foot on another slope point.
   var goal_hit=probe(goal)
   if not goal_hit.is_empty():goal.y=maxf(goal.y,goal_hit.position.y+visual.sole_offset(side))
   goals[side]={"point":goal,"normal":goal_hit.normal if not goal_hit.is_empty() else hit.normal}
   var upper=sk.find_bone("thigh_"+side);var lower=sk.find_bone("calf_"+side)
   var hip=sk.to_global(sk.get_bone_global_pose(upper).origin);var knee=sk.to_global(sk.get_bone_global_pose(lower).origin)
   var length=hip.distance_to(knee)+knee.distance_to(raw)-.012
   var horizontal=Vector2(goal.x-hip.x,goal.z-hip.z).length()
   var allowed=sqrt(maxf(.01,length*length-horizontal*horizontal))
   lower_target=minf(lower_target,goal.y+allowed-hip.y)
 pelvis_offset=move_toward(pelvis_offset,clampf(lower_target,-.13,0),delta*.65)
 visual.rig.position.y=visual.ground_origin_y+pelvis_offset
 sk.force_update_all_bone_transforms()
 # Pelvis translation also moves the swing leg: clearance must be re-evaluated afterwards.
 for side in ["l","r"]:
  if goals.has(side):continue
  var world_foot=sk.to_global(sk.get_bone_global_pose(sk.find_bone("foot_"+side)).origin)
  var hit=probe(world_foot)
  if not hit.is_empty() and world_foot.y<hit.position.y+visual.sole_offset(side):
   if not contacts.has(side):contacts[side]={"planted":false,"height":visual.to_local(world_foot).y,"point":hit.position,"normal":hit.normal,"released":false,"raw_point":world_foot}
   goals[side]={"point":Vector3(world_foot.x,hit.position.y+visual.sole_offset(side),world_foot.z),"normal":hit.normal}
 for side in goals:
  solve(side,goals[side].point,goals[side].normal)
 if "--debug-contact" in OS.get_cmdline_user_args():draw_debug(goals)
func solve(side:String,world_goal:Vector3,world_normal:Vector3):
 var sk=visual.skeleton;var upper=sk.find_bone("thigh_"+side);var lower=sk.find_bone("calf_"+side);var end=sk.find_bone("foot_"+side)
 var a=sk.get_bone_global_pose(upper);var b=sk.get_bone_global_pose(lower);var c=sk.get_bone_global_pose(end)
 var authored_world=contacts[side].get("raw_point",world_goal)
 var goal=sk.to_local(world_goal);var l1=a.origin.distance_to(b.origin);var l2=b.origin.distance_to(c.origin);var ray=goal-a.origin
 if ray.length()>l1+l2+.01 and visual.speed>.2:
  contacts[side].planted=false;contacts[side].released=true
  var hit=probe(authored_world)
  if not hit.is_empty():world_goal=Vector3(authored_world.x,maxf(authored_world.y,hit.position.y+visual.sole_offset(side)),authored_world.z);goal=sk.to_local(world_goal);ray=goal-a.origin
 var extension_margin=.0001 if responsive_player_feet else .006
 var length=clampf(ray.length(),.08,l1+l2-extension_margin);var direction=ray.normalized()
 var along=(l1*l1-l2*l2+length*length)/(2*length);var height=sqrt(maxf(0,l1*l1-along*along))
 # The authored knee selects the bend side; no fixed arbitrary sideways pole.
 var pole=b.origin-a.origin;var bend=Vector3(pole-direction*direction.dot(pole)).normalized()
 if responsive_player_feet:
  # Preserve the clip's knee direction even when the ankle target crosses the leg axis.
  var authored_ray=(c.origin-a.origin).normalized()
  var authored_bend=pole.slide(authored_ray)
  if authored_bend.length_squared()>.000001:bend=authored_bend.slide(direction).normalized()
 if bend.length()<.5:bend=Vector3.FORWARD.slide(direction).normalized()
 var knee=a.origin+direction*along+bend*height;var ankle=a.origin+direction*length
 var q1=Quaternion((b.origin-a.origin).normalized(),(knee-a.origin).normalized());var q2=Quaternion((c.origin-b.origin).normalized(),(ankle-knee).normalized())
 a.basis=Basis(q1)*a.basis;b.basis=Basis(q2)*b.basis;b.origin=knee;c.origin=ankle
 var rest=sk.get_bone_global_rest(end).basis;var sole_axis=rest.inverse()*Vector3.UP
 var sole_normal=(c.basis*sole_axis).normalized();var desired_normal=(sk.global_basis.inverse()*world_normal).normalized()
 c.basis=Basis(Quaternion(sole_normal,desired_normal))*c.basis
 sk.set_bone_global_pose_override(upper,a,1,true);sk.set_bone_global_pose_override(lower,b,1,true);sk.set_bone_global_pose_override(end,c,1,true)
 var error=sk.to_global(ankle).distance_to(world_goal);max_reach_error=maxf(max_reach_error,error)
 contacts[side].reach_error=error
func draw_debug(goals:Dictionary):
 if not debug_root:
  debug_root=Node3D.new();debug_root.name="ContactDebugOnly";visual.add_child(debug_root);debug_root.set_as_top_level(true)
  debug_root.global_transform=Transform3D.IDENTITY
  for side in ["l","r","pelvis"]:
   var marker=MeshInstance3D.new();marker.name=side;var mesh=SphereMesh.new();mesh.radius=.035;mesh.height=.07;marker.mesh=mesh;var m=StandardMaterial3D.new();m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;m.albedo_color=Color.RED if side=="pelvis" else Color.GREEN if side=="l" else Color.ORANGE;marker.material_override=m;debug_root.add_child(marker)
 for side in ["l","r"]:
  var marker=debug_root.get_node(side);marker.visible=goals.has(side)
  if goals.has(side):marker.global_position=goals[side].point-Vector3.UP*visual.sole_offset(side)

 if debug_root:
  var pelvis=visual.skeleton.to_global(visual.skeleton.get_bone_global_pose(visual.skeleton.find_bone("pelvis")).origin);debug_root.get_node("pelvis").global_position=pelvis
  var rays=debug_root.get_node_or_null("Rays")
  if not rays:
   rays=MeshInstance3D.new();rays.name="Rays";debug_root.add_child(rays);var m=StandardMaterial3D.new();m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;m.vertex_color_use_as_albedo=true;rays.material_override=m
  var mesh=ImmediateMesh.new();mesh.surface_begin(Mesh.PRIMITIVE_LINES)
  for side in contacts:
   if not contacts[side].has("raw_point"):continue
   var point=contacts[side].raw_point;mesh.surface_set_color(Color.CYAN);mesh.surface_add_vertex(point+Vector3.UP*.65);mesh.surface_add_vertex(point-Vector3.UP*1.25)
  mesh.surface_end();rays.mesh=mesh
