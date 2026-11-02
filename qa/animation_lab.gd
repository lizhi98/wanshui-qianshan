extends Node
# Explicit animation fixtures. Only memorial_replay.gd is the continuous game acceptance.
var g
var case_name:="A"
var clock:=0.0
var phase_clock:=0.0
var index:=-1
var phases:Array=[]
var subjects:Array=[]
var samples:Array=[]
var phase_events:Array=[]
var caption:Label
var folder:=""
var paused_column:=false
var last_shot:=""
var finished:=false
var floor_root
func _process(delta):
 if not g or finished:return
 clock+=delta;phase_clock+=delta
 if phase_clock>=float(phases[index][1]):next_phase()
 if finished:return
 var name=phases[index][0]
 if case_name in ["A","C"]:
  if name=="Turn":g.player.request_facing(g.player.position+Vector3(-10,0,0))
  camera_actor(g.player,name)
 elif case_name=="B":
  if clock>18 and not paused_column:
   paused_column=true
   for a in subjects:a.moving=false
  if clock>21 and clock-delta<=21:
   for a in subjects:a.moving=true
  var focus=Vector3.ZERO
  for a in subjects:focus+=a.position
  focus/=subjects.size();var eye=focus+Vector3(7,5.5,11)
  var floor_hit=get_viewport().get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(eye+Vector3.UP*200,eye-Vector3.UP*200,1))
  if not floor_hit.is_empty():eye.y=maxf(eye.y,floor_hit.position.y+3)
  g.view.camera.global_position=eye;g.view.camera.look_at(focus+Vector3.UP)
 else:camera_seated(name)
 caption.text="V4.1.5 动画专项夹具 · "+case_name+" / "+name+"  %.1fs"%phase_clock+"\n正面/背面/侧面观测 · 普通完整通关另行录制"
 record(delta)
 if phase_clock>1 and name!=last_shot and DisplayServer.get_name()!="headless":
  last_shot=name;call_deferred("shot",name)
func shot(name):
 await RenderingServer.frame_post_draw
 if not is_instance_valid(g):return
 get_tree().root.get_texture().get_image().save_png(folder.path_join(name+".png"))
func run(game):
 g=game
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--lab-case="):case_name=arg.get_slice("=",1)
 folder=ProjectSettings.globalize_path("res://test_evidence/v413/"+case_name) if not OS.has_feature("standalone") else ProjectSettings.globalize_path("user://verification/animation_v413/"+case_name)
 # A project export is also standalone; evidence goes to user:// for all executable runs.
 if not OS.get_executable_path().get_file().to_lower().contains("godot"):folder=ProjectSettings.globalize_path("user://verification/animation_v413/"+case_name)
 DirAccess.make_dir_recursive_absolute(folder)
 g.save_store.path="user://v413_lab_"+case_name+".json";g.begin();g.flags.intro_done=true;g.hud.hide_menu();g.hud.root_control.hide();g.set_process(false);g.set_physics_process(false);g.audio.clear_voice();g.weather.gust=0;g.weather.exposure=0;g.weather.strength=0;g.weather.flakes.hide();g.weather.mist.hide();g.crowd.hide();g.crowd.set_physics_process(false);g.view.cinematic=true;g.view.set_process_input(false)
 for a in g.actors()+[g.director.commander,g.director.guard]:a.moving=false;a.set_physics_process(false);a.hide()
 for action in InputMap.get_actions():InputMap.action_erase_events(action)
 var layer=CanvasLayer.new();add_child(layer);caption=Label.new();layer.add_child(caption);caption.position=Vector2(20,15);caption.add_theme_font_override("font",load("res://assets/remaster/fonts/NotoSansSC.ttf"));caption.add_theme_font_size_override("font_size",18);caption.add_theme_color_override("font_color",Color.WHITE);caption.add_theme_color_override("font_shadow_color",Color.BLACK);caption.add_theme_constant_override("shadow_outline_size",4)
 if case_name in ["A","C"]:
  g.world.hide();lab_ground();g.player.restore(Vector3(-60,200.02,500));g.player.rotation.y=PI/2;g.player.rotation_direction=PI/2;g.view.rotation=Vector3(0,-PI/2,0);g.view.camera_rotation=Vector3(-11,-90,0);subjects=[g.player]
  if case_name=="A":phases=[["Idle",5],["Walk",10],["Run",10],["Stop",2],["Turn",3],["Left",2],["Right",2],["Uphill",28],["Downhill",19],["Carry",3],["DropWalk",3],["StopAfterCarry",1],["Salute",9.2],["IdleAfterSalute",3]]
  else:phases=[["Idle",5],["Carry",5],["DropWalk",6],["Run",6],["Stop",3],["Salute",9.2],["IdleAfterSalute",5],["WalkAfterSalute",6],["Aim",3],["WalkAfterAim",5],["Take",3],["Handover",5],["WalkAfterInteraction",6],["Clear",6],["IdleAfterClear",4],["WalkAfterClear",6]]
 elif case_name=="B":
  g.player.locked=true;g.player.hide();g.stage="SEARCH";subjects=[g.amu,g.zhou,g.marchers[0],g.marchers[1],g.young,g.veteran]
  var route=g.world.route
  for i in subjects.size():
   var a=subjects[i];a.show();a.set_physics_process(true);var p=route.at(route.lengths[9]-float(i)*1.8);p.y=g.world.height_at(p)+.02;a.restore();a.position=p;a.rotation.y=atan2((route.POINTS[10]-p).x,(route.POINTS[10]-p).z);a.pose_name="";var points=[]
   for j in [10,11]:points.append(route.POINTS[j]+Vector3(.38,0,0))
   points.append(g.world.MEMORIAL+Vector3(-1,0,-2));points.append(route.POINTS[11]+Vector3(-.38,0,0));points.append(route.POINTS[10]+Vector3(-.38,0,0));points.append(route.at(route.lengths[9]-float(6-i)*1.3)+Vector3(-.38,0,0));a.walk(points,1.9+float(i%3)*.08)
  phases=[["UphillAndBend",18],["ColumnStop",3],["ResumeAndNarrow",24],["ReturnDownhill",30],["Finish",20]]
 else:
  g.player.locked=true;g.player.hide();var a=g.quartermaster;a.show();a.set_physics_process(true);a.position=g.world.MEMORIAL;a.rotation.y=2.214;a.pose_name="seated";g.stage="DISCOVERY";a.get_node("CampName").hide();subjects=[a];phases=[["SeatedFront",4],["SeatedLeft",4],["SeatedRight",4],["SeatedHigh",4]]
 next_phase()
func lab_ground():
 floor_root=Node3D.new();g.add_child(floor_root);floor_root.name="AnimationLabFixture"
 var mesh=MeshInstance3D.new();mesh.mesh=BoxMesh.new();mesh.mesh.size=Vector3(200,.5,80);mesh.position=Vector3(0,199.75,500);var m=StandardMaterial3D.new();m.albedo_color=Color("737d87");m.roughness=.98;mesh.material_override=m;floor_root.add_child(mesh);mesh.create_trimesh_collision()
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for section in [[20.0,40.0,200.0,205.0],[40.0,50.0,205.0,205.0],[50.0,70.0,205.0,200.0]]:
  var p=[Vector3(section[0],section[2],495),Vector3(section[1],section[3],495),Vector3(section[0],section[2],505),Vector3(section[1],section[3],505)]
  for v in [p[0],p[1],p[2],p[1],p[3],p[2]]:st.add_vertex(v)
 st.generate_normals();var ramp=MeshInstance3D.new();ramp.mesh=st.commit();ramp.material_override=m;floor_root.add_child(ramp);ramp.create_trimesh_collision()
func next_phase():
 index+=1;phase_clock=0
 if index>=phases.size():finish();return
 var name=phases[index][0];phase_events.append({"phase":name,"time":clock});print("ANIMATION_LAB ",case_name," ",name," ",clock)
 if case_name not in ["A","C"]:return
 for a in ["move_forward","move_back","move_left","move_right","sprint"]:Input.action_release(a)
 g.player.carrying=name=="Carry";g.parcel.visible=g.player.carrying;g.player.locked=name in ["Salute","Turn","Aim","Take","Handover","Clear"]
 g.player.visual.pose({"Salute":"salute","Take":"take","Handover":"handover","Clear":"clear"}.get(name,""))
 if name=="Aim":g.player.visual.mode="aim"
 elif name in ["Take","Handover","Clear","IdleAfterClear"]:g.player.visual.mode="pickup" if name in ["Take","Clear"] else "idle"
 if name in ["Walk","Run","Uphill","Downhill","Carry","DropWalk","WalkAfterSalute","WalkAfterAim","WalkAfterInteraction","WalkAfterClear"]:Input.action_press("move_forward")
 if name=="Run":Input.action_press("sprint")
 if name=="Left":Input.action_press("move_left")
 if name=="Right":Input.action_press("move_right")
func camera_actor(a,name):
 var angle=[0.0,PI,PI*.5,-PI*.5][int(phase_clock/2.5)%4]
 var forward=a.global_basis.z;var right=a.global_basis.x;var focus=a.position+Vector3.UP*1.0
 g.view.camera.global_position=focus+forward*cos(angle)*3.2+right*sin(angle)*3.2+Vector3.UP*.95;g.view.camera.look_at(focus)
func camera_seated(name):
 var a=g.quartermaster;var center=a.position+Vector3.UP*.45;var forward=a.global_basis.z;var right=a.global_basis.x
 var eye=center+forward*3.1+Vector3.UP*.65
 if name=="SeatedLeft":eye=center+right*3.1+Vector3.UP*.55
 if name=="SeatedRight":eye=center-right*3.1+Vector3.UP*.55
 if name=="SeatedHigh":eye=center+(forward+right)*2.5+Vector3.UP*2.6
 g.view.camera.global_position=eye;g.view.camera.look_at(center)
func record(delta):
 for a in subjects:
  var v=a.visual;var sk=v.skeleton;var bones={};var ground={};var rotations={}
  for name in ["pelvis","spine_03","Head","hand_l","hand_r","foot_l","foot_r","calf_l","calf_r"]:
   var i=sk.find_bone(name)
   if i<0:continue
   var world=sk.to_global(sk.get_bone_global_pose(i).origin);var p=v.to_local(world);bones[name]=[p.x,p.y,p.z]
   var rotation=sk.get_bone_global_pose(i).basis.get_rotation_quaternion();rotations[name]=[rotation.x,rotation.y,rotation.z,rotation.w]
   if name.begins_with("foot"):
    var hit=get_viewport().get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(world+Vector3.UP*.7,world-Vector3.UP*1.2,1))
    if not hit.is_empty():ground[name]={"position":[world.x,world.y,world.z],"sole_gap":world.y-hit.position.y-v.sole_offset(name.get_slice("_",1)),"normal":[hit.normal.x,hit.normal.y,hit.normal.z]}
  var hit=get_viewport().get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(a.position+Vector3.UP*.3,a.position-Vector3.UP*1.2,1))
  var gap=a.position.y-hit.position.y if not hit.is_empty() else 100.0
  var raw_gap=gap
  if not hit.is_empty():
   var radius=.27 if a==g.player else .29
   var sphere_height=.265 if a==g.player else .29
   gap=(gap+sphere_height)*hit.normal.y-radius
  # Nearest lower-capsule contact also covers mesh seams and convex corners.
  var radius=.27 if a==g.player else .29;var sphere_height=.265 if a==g.player else .29
  var shape=SphereShape3D.new();shape.radius=radius+.06;var query=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1;query.transform=Transform3D(Basis.IDENTITY,a.position+Vector3.UP*sphere_height)
  var contact=get_viewport().get_world_3d().direct_space_state.get_rest_info(query)
  if not contact.is_empty():gap=(query.transform.origin-contact.point).dot(contact.normal)-radius
  samples.append({"time":clock,"dt":delta,"phase":phases[index][0],"id":str(a.name),"position":[a.position.x,a.position.y,a.position.z],"velocity":[a.velocity.x,a.velocity.y,a.velocity.z],"yaw":a.rotation.y,"floor":a.is_on_floor(),"ground_gap":gap,"ground_gap_vertical":raw_gap,"mode":v.mode,"pose":v.narrative_pose,"owner":v.active_owner,"animation_speed":v.motion_speed,"animation_rate":v.animation_tree.get("parameters/LocomotionRate/scale"),"bones":bones,"rotations":rotations,"feet":ground,"rig_y":v.rig.position.y,"contacts":v.contact_driver.contacts.duplicate(true) if v.contact_driver else {},"route_count":a.get("route").size() if a.get("route")!=null else 0,"route":a.get("route_index")})
func finish():
 finished=true
 for a in ["move_forward","move_back","move_left","move_right","sprint"]:Input.action_release(a)
 var f=FileAccess.open(folder.path_join("motion.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"case":case_name,"fixture":true,"binary":OS.get_executable_path(),"movie":not Engine.get_write_movie_path().is_empty(),"phases":phase_events,"samples":samples}));f.close()
 print("ANIMATION_LAB_CAPTURE ",case_name," samples=",samples.size()," time=",clock)
 g.main_menu();g.queue_free();await get_tree().process_frame;get_tree().quit()
