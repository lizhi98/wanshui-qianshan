extends SceneTree
var g
var failures:=0
var moving_frames:=0
func _initialize():call_deferred("run")
func check(ok,label):
 print("PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func _process(_delta):
 if g and g.player.scripted_destination!=Vector3.INF and g.player.visual.speed>.2:
  moving_frames+=1
 return false
func run():
 g=load("res://game/golden_hook/main.tscn").instantiate();root.add_child(g);await process_frame
 g.begin_chapter(true);g.set_process(false)
 for fixture in [["put_greens","pot","cook_greens"],["greens_a","greens_a","supplies"],["needle","needle","craft"]]:
  g._cancel_dialogue();g.story.step=fixture[2];g.story.inventory.greens=2;g.story.done.erase(fixture[0])
  var point=g.world.points[fixture[1]]
  g.player.restore(g.world.at_ground(point+Vector3(1.9,0,1.2))+Vector3(0,.05,0))
  await create_timer(.3).timeout
  var before=moving_frames
  await g._do_action({"id":fixture[0],"point":point})
  check(moving_frames>before,"approach retains walking animation: "+fixture[0])
  check(g.player.scripted_destination==Vector3.INF,"approach controller released")
  check(g.story.done.get(fixture[0],false),"interaction completes: "+fixture[0])
  g.player.locked=true;await create_timer(.6).timeout
  var sk=g.player.visual.skeleton
  var hip=sk.to_global(sk.get_bone_global_pose(sk.find_bone("pelvis")).origin)
  var feet=Vector3.ZERO
  for side in ["l","r"]:feet+=sk.to_global(sk.get_bone_global_pose(sk.find_bone("foot_"+side)).origin)*.5
  var gap=Vector2(hip.x-feet.x,hip.z-feet.z).length()
  check(gap<.35,"feet remain beneath body after interaction; gap="+str(gap))
  g.player.locked=false
 g.queue_free();await process_frame;await create_timer(.4).timeout
 print("INTERACTION_GAIT_CHECK failures=",failures," moving_frames=",moving_frames);quit(1 if failures else 0)
