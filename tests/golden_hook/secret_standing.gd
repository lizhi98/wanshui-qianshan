extends SceneTree
var failures:=0
var monitor=false
var g
func _initialize():call_deferred("run")
func _process(_delta):
 if monitor and g and g.player.visual.posture=="kneel":
  failures+=1;push_error("player kneels during secret interaction");monitor=false
 return false
func check(ok,label):
 print("PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func run():
 g=load("res://game/golden_hook/main.tscn").instantiate();root.add_child(g);await process_frame
 g.begin_chapter(true);g.set_process(false);g.story.step="secret"
 g.elder.moving=false;g.elder.position=g.world.points.secret;g.elder.visual.posture="seated";g.elder.visual.hold("scraps")
 g.player.position=g.world.at_ground(g.elder.position+Vector3(1.35,0,.3));monitor=true
 for action in ["inspect_scraps","understand"]:
  await g._do_action({"id":action,"point":g.world.points.secret})
  check(g.player.visual.posture=="standing","player stands: "+action)
  check(g.player.visual.hand_targets.is_empty(),"no ground-reaching hand targets")
  check(g.elder.visual.posture=="seated","elder remains seated")
  var gap=Vector2(g.player.position.x-g.elder.position.x,g.player.position.z-g.elder.position.z).length()
  check(gap>1.05,"comfortable observation distance: "+str(gap))
  check(not g.dialogue_rows.is_empty(),"dialogue starts normally")
  g.dialogue_finish=Callable()
  while not g.dialogue_rows.is_empty():
   g._cinematic_camera(.016);g._next_line();await process_frame
  check(not g.busy and not g.player.locked,"dialogue releases controls")
 monitor=false
 g.queue_free();await process_frame;await create_timer(.4).timeout
 print("SECRET_STANDING_CHECK failures=",failures);quit(1 if failures else 0)
