extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://game/memorial/main.tscn").instantiate();root.add_child(g);await create_timer(.3).timeout;var v=g.player.visual;v.set_process(false);v.animation_tree.active=false;v.rig.position=Vector3.ZERO;var sk=v.skeleton;var clips=[]
 for name in ["Walk_Loop","Walk_Formal","Jog_Fwd_Loop","Sprint_Loop"]:
  var anim=v.animator.get_animation(name);var samples=[]
  for k in 120:
   sk.clear_bones_global_pose_override();sk.reset_bone_poses();v.animator.play(name);v.animator.seek(anim.length*float(k)/120,true);sk.force_update_all_bone_transforms();var b={}
   for bone in ["pelvis","hand_l","hand_r","foot_l","foot_r"]:
    var p=v.to_local(sk.to_global(sk.get_bone_global_pose(sk.find_bone(bone)).origin));b[bone]=[p.x,p.y,p.z]
   samples.append(b)
  clips.append({"clip":name,"length":anim.length,"samples":samples})
 var f=FileAccess.open("res://test_evidence/v413/resource_clips.json",FileAccess.WRITE);f.store_string(JSON.stringify(clips));f.close();g.queue_free();await process_frame;quit()
