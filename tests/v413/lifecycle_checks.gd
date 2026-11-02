extends SceneTree
class EdgeProbe extends "res://game/memorial/contact_ik.gd":
 var calls:=0
 func probe(point:Vector3):
  calls+=1
  if calls<=2:return {}
  return {"position":Vector3(point.x,visual.get_parent().position.y,point.z),"normal":Vector3.UP}
var g
var errors:=0
func _initialize():call_deferred("run")
func check(ok,label):
 print(("PASS " if ok else "FAIL ")+label)
 if not ok:errors+=1
func run():
 g=load("res://game/memorial/main.tscn").instantiate();root.add_child(g);await create_timer(.4).timeout;g.save_store.path="user://v413_lifecycle_fixture.json";g.begin();g.flags.intro_done=true;g.player.locked=true;g.set_process(false);await create_timer(.5).timeout
 var v=g.player.visual;var edge=EdgeProbe.new();edge.setup(v);v.rig.position.y=-.15;edge.tick(1.0/60)
 check(edge.calls>=4 and edge.contacts.has("l") and edge.contacts.has("r"),"a missed first ray and successful post-pelvis ray initialise both contacts")
 var driver=v.contact_driver;driver.contacts={"l":{"planted":false,"height":.08,"point":g.player.position,"normal":Vector3.UP,"released":false,"stop_point":g.player.position-Vector3(5,0,0)}};v.speed=1.7;driver.tick(1.0/60)
 check(not driver.contacts.l.has("stop_point"),"resuming movement releases the previous stopping anchor")
 var marks=g.world._footprints();v.speed=0;g.player.velocity=Vector3.ZERO;driver.events=[{"side":"l","point":g.player.position,"normal":Vector3.UP}];var count=marks.emitted;marks.track(g.player)
 check(marks.emitted==count and driver.events.is_empty(),"stationary actors discard queued contacts without leaving new footprints")
 g.crowd._update(.1);var assignments=g.crowd.rig_assignments.duplicate();g.view.camera.position.x+=1;g.crowd._update(.1);var stable=true
 for id in assignments:
  if g.crowd.rig_assignments.has(id) and g.crowd.rig_assignments[id]!=assignments[id]:stable=false
 check(stable and not assignments.is_empty(),"visible crowd units retain their own skeleton slot when the camera moves")
 g.action="salute";g.crowd._update(.1);g.action="";g.crowd._update(.1)
 check(g.crowd.rig_pool.all(func(a):return not a.visible or a.visual.narrative_pose==""),"marching crowd clears salute ownership on exit")
 g.main_menu();g.queue_free();await process_frame;quit(1 if errors else 0)
