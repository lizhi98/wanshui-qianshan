extends SceneTree
var failures:=0
func _initialize():call_deferred("run")
func check(ok,label):
 print("PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func run():
 var g=load("res://game/golden_hook/main.tscn").instantiate();root.add_child(g);await process_frame
 g.begin_chapter(true);g.set_process(false)
 for pair in [["comrade_a",g.shi],["comrade_b",g.qing]]:
  g._cancel_dialogue();g.busy=false;g.player.locked=false
  var p=g.player;var v=p.visual
  p.position=g.world.at_ground(pair[1].position+Vector3(1.15,0,.2));p.velocity=Vector3(1,0,0);p.movement_velocity=p.velocity
  var origin=p.position
  await g._do_action({"id":pair[0],"point":pair[1].position})
  check(Vector2(p.position.x-origin.x,p.position.z-origin.z).length()<.01,"no scripted slide into seated comrade: "+pair[0])
  check(p.velocity.length()<.01 and p.movement_velocity.length()<.01,"residual movement cleared")
  check(v.posture=="standing" and v.hand_targets.is_empty(),"stable standing dialogue without reaching")
  await create_timer(.5).timeout
  var sk=v.skeleton;var head=sk.find_bone("Head");var pelvis=sk.find_bone("pelvis")
  var initial=sk.get_bone_global_pose(head).origin-sk.get_bone_global_pose(pelvis).origin
  await create_timer(2).timeout
  var after=sk.get_bone_global_pose(head).origin-sk.get_bone_global_pose(pelvis).origin
  check(initial.distance_to(after)<.10,"listener torso stays stable over time")
  while not g.dialogue_rows.is_empty():g._next_line()
  check(not p.locked and not g.busy,"movement released after conversation")
 g.queue_free();await process_frame;await create_timer(.4).timeout
 print("COMRADE_STANCE_CHECK failures=",failures);quit(1 if failures else 0)
