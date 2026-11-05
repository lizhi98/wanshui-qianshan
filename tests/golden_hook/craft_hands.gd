extends SceneTree
var failures:=0
func _initialize():call_deferred("run")
func check(ok,label):
 print("PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func run():
 var g=load("res://game/golden_hook/main.tscn").instantiate();root.add_child(g);await process_frame
 g.begin_chapter(true);g.set_process(false)
 for step in ["heat","bend","tie","mount"]:
  g.story.step=step;g._enter_craft()
  g.elder.moving=false;g.elder.position=g.world.at_ground(g.world.points.work+Vector3(-.45,0,-.6))
  g._craft_tick(.016)
  check(not g.player.visual.visible and g.elder.visual.visible,"only elder rendered during "+step)
  check(g.player.visual.hand_targets.is_empty(),"observer does not reach into workbench")
  check(g.elder.visual.external_grip and g.elder.visual.contact_prop==g.world.work_hook,"elder still operates original hook")
 g.story.step="bend";g.bend_progress=.59
 for i in 60:g._craft_tick(1.0/60);await process_frame
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(OS.get_environment("TEMP")+"/craft-two-hands.png")
 g._exit_craft();check(g.player.visual.visible and not g.player.locked,"normal exit restores player")
 g._enter_craft();g.return_to_menu();check(g.player.visual.visible,"return to menu restores player")
 g._enter_craft();g.begin_chapter(true);check(g.player.visual.visible,"new chapter restores player")
 g.queue_free();await process_frame;await create_timer(.4).timeout
 print("CRAFT_HANDS_CHECK failures=",failures);quit(1 if failures else 0)
