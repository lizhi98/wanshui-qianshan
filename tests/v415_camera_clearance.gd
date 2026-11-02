extends SceneTree
var g
var failures:=0
func _initialize():call_deferred("run")
func check(ok,label):
 print(("PASS " if ok else "FAIL ")+label)
 if not ok:failures+=1
func run():
 g=load("res://game/memorial/main.tscn").instantiate();root.add_child(g);await create_timer(.4).timeout;g.save_store.path="user://v415_camera_fixture.json";g.begin();g.flags.intro_done=true;g.set_process(false);g.set_physics_process(false);g.audio.clear_voice()
 var d=g.director
 for person in g.actors()+[d.commander,d.guard]:person.position=Vector3(100,200,500);person.moving=false;person.set_physics_process(false)
 d.guard.position=Vector3(0,200,500);d.guard.rotation.y=0
 g.player.restore(Vector3(0,200,501.8));g.player.locked=true;g.player.set_physics_process(false)
 d.camera_key="";d.frame_speaker(d.guard,"警卫员",.1)
 var eye=d.selected_eye;var focus=d.guard.position+Vector3.UP*1.43
 check(Vector2(eye.x-g.player.position.x,eye.z-g.player.position.z).length()>=.85,"speaker shot rejects an eye inside the player's head or backpack")
 var clear=true
 for height in [1.0,1.4,1.7]:
  var body=g.player.position+Vector3.UP*height
  if body.distance_to(Geometry3D.get_closest_point_to_segment(body,eye,focus))<.5:clear=false
 check(clear,"guard sightline routes around the listening player")
 check(d.camera_actor=="GuardAmu","unobstructed shot retains the named speaking actor")
 print("CAMERA_CLEARANCE failures=",failures," eye=",eye)
 g.main_menu();g.queue_free();await process_frame;quit(1 if failures else 0)
