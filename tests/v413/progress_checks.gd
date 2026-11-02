extends SceneTree
var g
var errors:=0
func _initialize():call_deferred("run")
func check(ok,label):
 print(("PASS " if ok else "FAIL ")+label)
 if not ok:errors+=1
func run():
 g=load("res://game/memorial/main.tscn").instantiate();root.add_child(g);await create_timer(.4).timeout;g.save_store.path="user://v413_progress_fixture.json";g.begin();g.flags.intro_done=true;g.stage="DISCOVERY";g.set_process(false);g.audio.clear_voice()
 var a=g.young;a.position=Vector3(-7.519815,22.47325,-44.89278);a.walk([g.world.route.POINTS[7],g.world.route.POINTS[8]],1.85);a.actual_speed=0;var p=a.position;var target=a.route.duplicate();var index=a.route_index
 a._check_corridor_progress(2,Vector3(0,0,-1.7))
 check(a.replan_history.size()==1 and a.position==p and a.route==target and a.route_index==index,"isolated stalled intent replans without teleporting or skipping remaining waypoints")
 a._check_corridor_progress(2,Vector3(0,0,-1.7));check(a.replan_history.size()==1,"replan cooldown prevents repeated per-frame resets")
 await create_timer(4).timeout;check(a.position.distance_to(p)>2 and not a.route.is_empty(),"the failed-recording position resumes through physical walking")
 a.restore();check(a.replan_history.is_empty() and a.corridor_index==-1,"restarting clears transient approach and replan history")
 a.position=g.zhou.position+Vector3(.8,0,0);a.walk([a.position+Vector3(0,0,-4)],1.85);a.actual_speed=0;a._check_corridor_progress(2,Vector3(0,0,-1.7));check(a.replan_history.is_empty(),"a nearby real companion causes queuing rather than an isolated-stall replan")
 g.main_menu();g.queue_free();await process_frame;quit(1 if errors else 0)
