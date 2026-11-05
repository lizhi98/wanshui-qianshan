extends SceneTree
var failures:=0
func _initialize():call_deferred("run")
func check(ok,label):
 if not ok:failures+=1;push_error(label)
func run():
 var g=load("res://game/golden_hook/main.tscn").instantiate();root.add_child(g);await process_frame
 g.set_process(false);g.view.set_physics_process(false);g.player.set_physics_process(false);g.started=true;g.paused=false;g.hud.menu.hide()
 var tested=0
 for group in ["comrade_a","comrade_b","serve_a","serve_b","bag_a","bag_b","ration","after_soup","craft_done","soup_ready","first_fish","two_fish","last_fish","search"]:
  if not g.Dialogue.GROUPS.has(group):continue
  g._reset_camera();g.view.camera_rotation=Vector3(-11,43,0);g.view.rotation_degrees=Vector3(-11,43,0)
  var original=g.view.camera.global_transform;var fov=g.view.camera.fov
  g._finish_action()
  check(g.view.camera.global_transform.is_equal_approx(original),"interaction preserves view: "+group)
  g.play_dialogue(group)
  check(not g.dialogue_uses_camera and not g.view.cinematic,"ordinary dialogue uses follow camera: "+group)
  while not g.dialogue_rows.is_empty():
   g._process(.01)
   check(g.view.camera.global_transform.is_equal_approx(original) and g.view.camera.fov==fov,"no forced camera cut: "+group)
   check(g.hud.dialogue_panel.visible,"subtitle remains visible: "+group)
   g._next_line();tested+=1
  check(g.view.camera.global_transform.is_equal_approx(original),"completion preserves view: "+group)
  check(not g.player.locked and not g.busy,"controls released: "+group)
 for group in ["intro","demo","secret","last_soup","onward"]:
  g.play_dialogue(group);check(g.dialogue_uses_camera and g.view.cinematic,"authored shot retained: "+group);g._cancel_dialogue()
 g.queue_free();await process_frame;await create_timer(.4).timeout
 print("DIALOGUE_CAMERA_CHECK failures=",failures," ordinary_lines=",tested);quit(1 if failures else 0)
