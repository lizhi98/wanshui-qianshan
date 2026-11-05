extends SceneTree
var g
var failures:=0
func _initialize():call_deferred("run")
func check(ok,label):
 print("PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func follow_ok(label):
 check(not g.view.cinematic,label+" follow mode")
 check(g.view.camera.rotation.length()<.001,label+" no leftover camera rotation")
 check(g.view.camera.position.z>4,label+" third person distance")
 check(absf(g.view.camera.global_basis.x.y)<.001,label+" level horizon")
func run():
 g=load("res://game/golden_hook/main.tscn").instantiate();root.add_child(g);await process_frame
 g.begin_chapter(true);g.set_process(false);g.view.set_physics_process(false)
 check(not g.view.use_bridge_bounds,"wetland disables bridge-only camera boundaries")
 g.play_dialogue("intro")
 while not g.dialogue_rows.is_empty():g._cinematic_camera(.1);g._next_line()
 follow_ok("opening narration exit")
 g.view.cinematic=true;g.view.camera.position=Vector3(.2,.8,.3);g.view.camera.rotation=Vector3(.25,.7,.5)
 g.play_dialogue("march");follow_ok("cinematic to walking narration")
 g._cancel_dialogue();g.story.step="secret";g.view.cinematic=true;g.view.camera.rotation=Vector3(.2,-.8,.4)
 await g._start_march();follow_ok("actual secret to march transition")
 g._cancel_dialogue();g.busy=false;g.player.locked=false
 g._reset_camera();g.view.camera_rotation.y=42;g.view.rotation_degrees.y=42
 var original=g.view.camera.global_transform
 g.play_dialogue("comrade_a");check(original.is_equal_approx(g.view.camera.global_transform),"ordinary dialogue preserves existing view")
 g._cancel_dialogue();g.busy=false;g.player.locked=false
 g.fishing.enter(0);g.fishing.exit();follow_ok("fishing exit")
 g.view.focus_grace=0;Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
 if DisplayServer.get_name()!="headless":
  var before=g.view.camera_rotation
  var event=InputEventMouseMotion.new();event.relative=Vector2(10,-10);g.view._input(event)
  check(absf(g.view.camera_rotation.y-before.y+1.4)<.001 and absf(g.view.camera_rotation.x-before.x-1.2)<.001,"mouse axes map to expected yaw and pitch")
 g.view.camera.rotation=Vector3(.2,.6,.4)
 g.view._physics_process(1.0/60)
 check(absf(g.view.camera.rotation.y)<.001 and absf(g.view.camera.rotation.z)<.001,"follow update rejects residual cinematic yaw and roll")
 g.queue_free();await process_frame;await create_timer(.4).timeout
 print("CAMERA_HANDOFF_CHECK failures=",failures);quit(1 if failures else 0)
