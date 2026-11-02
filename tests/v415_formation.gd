extends SceneTree
var g
var failures:=0
func _initialize():call_deferred("run")
func run():
 g=load("res://game/memorial/main.tscn").instantiate();root.add_child(g);await create_timer(.4).timeout;g.save_store.path="user://v415_formation_fixture.json";g.begin();g.set_process(false);g.set_physics_process(false);g.flags.intro_done=true;g.stage="CONTINUE";g.flags.at_pass=true;g.crowd.hide();g.crowd.set_physics_process(false);g.audio.clear_voice()
 var data=JSON.parse_string(FileAccess.get_file_as_string("res://tests/v415_final_stuck.json"))
 g.player.restore(Vector3(6.845667,47.88541,-108.9929));g.player.locked=true
 var failed=JSON.parse_string(FileAccess.get_file_as_string("res://tests/v415_final_failed_report.json"))
 for i in g.actors().size():
  var row=data.actors[i].duplicate(true);var s=failed.party[i].position.trim_prefix("(").trim_suffix(")").split(",")
  row.position=[float(s[0]),float(s[1]),float(s[2])]
  if g.actors()[i]!=g.young:row.route=[];row.moving=false
  g.actors()[i].restore_snow(row)
 g.director.commander.restore_snow(failed.climax.commander);g.director.guard.restore_snow(failed.climax.guard)
 # Recreate the actually blocked body while keeping the exact final goal.
 var a=g.young;var goal=a.route[-1] if not a.route.is_empty() else Vector3(6.15,48.21025,-109.4)
 a.position=Vector3(5.60951,48.6275,-110.8291);a.walk([goal],1.85)
 var before=a.position;await create_timer(25).timeout
 var ok=not a.moving and Vector2(a.position.x-goal.x,a.position.z-goal.z).length()<.25
 print(("PASS " if ok else "FAIL ")+"blocked final witness walks around stationary teammates to the same final goal; "+str(a.position)+" goal="+str(goal))
 if not ok:failures+=1
 print("FORMATION_HISTORY ",a.replan_history)
 var detoured=a.replan_history.any(func(x):return x.get("kind","") in ["formation_detour","formation_yield"])
 print(("PASS " if detoured else "FAIL ")+"actual blocked witness uses physical detour or cooperative yielding")
 if not detoured:failures+=1
 g.main_menu();g.queue_free();await process_frame;quit(1 if failures else 0)
