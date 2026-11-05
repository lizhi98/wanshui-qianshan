extends SceneTree
var failures:=0
func _initialize():call_deferred("run")
func check(ok,label):
 print("PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func run():
 var g=load("res://game/v2/main.tscn").instantiate();root.add_child(g);await process_frame
 g.set_process(false);g.set_physics_process(false);g.player.set_physics_process(false);g.combat.set_process(false);g.paused=false
 var v=g.player.visual;v.set_process(false);v.animation_offset=0;v.personality=0;v.armed=true;v.speed=1.4;v.mode="reload"
 var bone=v.skeleton.find_bone("calf_l")
 check(bone>=0,"leg bone located")
 var rotations=[]
 for i in 120:
  v._process(1.0/60.0)
  rotations.append(v.skeleton.get_bone_pose_rotation(bone))
 var range_angle=0.0
 for q in rotations.slice(60):range_angle=maxf(range_angle,rotations[60].angle_to(q))
 check(range_angle>.15,"walking legs keep cycling while reloading; radians="+str(range_angle))
 check(v.reload_blend==1 and v.action_blend==0,"reload isolated from full body actions")
 v.speed=3.8
 rotations.clear()
 for i in 120:
  v._process(1.0/60.0)
  rotations.append(v.skeleton.get_bone_pose_rotation(bone))
 range_angle=0.0
 for q in rotations.slice(60):range_angle=maxf(range_angle,rotations[60].angle_to(q))
 check(range_angle>.15,"running legs keep cycling during reload")
 v.mode="walk"
 for i in 30:v._process(1.0/60.0)
 check(v.reload_blend==0,"reload fades out on returning to locomotion")
 g.queue_free();await process_frame;await create_timer(.3).timeout
 for path in ["res://game/memorial/main.tscn","res://game/golden_hook/main.tscn"]:
  g=load(path).instantiate();root.add_child(g);await process_frame
  check(g.player.visual.get("upper_body_reload")!=true,"other chapter retains original action behavior")
  g.queue_free();await process_frame;await create_timer(.3).timeout
 print("RELOAD_LEGS_CHECK failures=",failures);quit(1 if failures else 0)

