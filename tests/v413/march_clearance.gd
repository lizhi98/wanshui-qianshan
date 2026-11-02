extends SceneTree
var g
var errors:=0
func _initialize():call_deferred("run")
func check(ok,label):
 print(("PASS " if ok else "FAIL ")+label)
 if not ok:errors+=1
func run():
 g=load("res://game/memorial/main.tscn").instantiate();root.add_child(g);await create_timer(.4).timeout;g.save_store.path="user://v413_march_fixture.json";g.begin();g.flags.intro_done=true;g.stage="MARCH";g.set_process(false);g.player.locked=true;g.player.restore(g.world.route.POINTS[10]);g.player.locked=true;g.world.clear_obstacle();g.audio.clear_voice();g.crowd.set_physics_process(false)
 g._group_walk(1,6);var qm_path=[Vector3(.5,0,36)];qm_path.append_array(g._party_path(1,11,4));g.quartermaster.walk(qm_path,2.9)
 for j in 12:
  await create_timer(15).timeout
  for a in g.actors():print("MARCH_TRACE ",j," ",a.name," ",a.position," velocity=",a.velocity," intent=",a.horizontal_velocity," desired=",a.desired_speed," yaw=",a.rotation.y," route=",a.route_index,"/",a.route.size()," goal=",a.route[a.route_index] if a.route_index<a.route.size() else Vector3.ZERO)
 for a in g.actors():
  if a!=g.quartermaster:check(not a.moving,"camp group passes initial merge and reaches first march endpoint "+str(a.name))
 g.main_menu();g.queue_free();await process_frame;quit(1 if errors else 0)
