extends SceneTree
var g
var rows:Array=[]
var frame:=0
var phase:="walk"
var time:=0.0
func _initialize():call_deferred("run")
func record():
 for a in [g.player]+g.actors()+[g.director.commander,g.director.guard]:
  var v=a.visual;var sk=v.skeleton;var bones={}
  for name in ["pelvis","spine_03","Head","hand_l","hand_r","foot_l","foot_r","calf_l","calf_r"]:
   var i=sk.find_bone(name)
   if i>=0:
    var q=v.to_local(sk.to_global(sk.get_bone_global_pose(i).origin));bones[name]=[q.x,q.y,q.z]
  rows.append({"frame":frame,"time":time,"phase":phase,"id":str(a.name),"position":[a.position.x,a.position.y,a.position.z],"velocity":[a.velocity.x,a.velocity.y,a.velocity.z],"floor":a.is_on_floor(),"yaw":a.rotation.y,"mode":v.mode,"pose":v.narrative_pose,"animation_speed":v.motion_speed,"bones":bones,"route":a.get("route_index")})
func run():
 g=load("res://game/memorial/main.tscn").instantiate();root.add_child(g);await create_timer(.4).timeout;g.save_store.path="user://v413_baseline_probe.json";g.begin();g.flags.intro_done=true;g.hud.center_title.text="";g.player.locked=false;g._reset_camera();g.view.set_process_input(false)
 print("CLIPS ",g.player.visual.animator.get_animation_list())
 var sk=g.player.visual.skeleton
 for name in ["root","pelvis","upperarm_l","upperarm_r","thigh_l","thigh_r","foot_l","foot_r"]:
  var i=sk.find_bone(name)
  if i>=0:print("BONE ",name," rest=",sk.get_bone_rest(i)," pose=",sk.get_bone_pose(i))
 g.set_process(false);g.set_physics_process(false);g.stage="SEARCH";g.view.camera_rotation=Vector3(-11,0,0)
 for a in g.actors():
  if a==g.quartermaster:continue
  a.pose_name="";a.walk(g._party_path(1,10,g.actors().find(a)),2.6)
 for action in InputMap.get_actions():InputMap.action_erase_events(action)
 Input.action_press("move_forward")
 for k in 900:
  await physics_frame;time+=1.0/60;frame+=1
  if k==600:Input.action_release("move_forward");phase="stop"
  if k==660:g.player.carrying=true;phase="carry";Input.action_press("move_forward")
  if k==780:g.player.carrying=false;phase="after_carry"
  record()
 Input.action_release("move_forward")
 var path="res://test_evidence/v413";DirAccess.make_dir_recursive_absolute(path);var f=FileAccess.open(path+"/baseline_motion.json",FileAccess.WRITE);f.store_string(JSON.stringify(rows));f.close()
 var v=g.player.visual;v.set_process(false);v.animation_tree.active=false
 var clips=[]
 for name in ["Idle_Loop","Walk_Loop","Jog_Fwd_Loop","Sprint_Loop"]:
  var anim=v.animator.get_animation(name);var samples=[]
  for k in 60:
   sk.clear_bones_global_pose_override();sk.reset_bone_poses();v.animator.play(name);v.animator.seek(anim.length*float(k)/60,true);sk.force_update_all_bone_transforms();var b={}
   for bone in ["pelvis","hand_l","hand_r","foot_l","foot_r"]:
    var i=sk.find_bone(bone);var q=v.to_local(sk.to_global(sk.get_bone_global_pose(i).origin));b[bone]=[q.x,q.y,q.z]
   samples.append(b)
  clips.append({"clip":name,"length":anim.length,"samples":samples})
 f=FileAccess.open(path+"/baseline_clips.json",FileAccess.WRITE);f.store_string(JSON.stringify(clips));f.close();print("BASELINE_CAPTURE ",rows.size())
 g.main_menu();g.queue_free();await process_frame;quit()
