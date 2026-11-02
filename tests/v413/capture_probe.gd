extends SceneTree
var g
func _initialize():call_deferred("run")
func describe(label):
 var v=g.player.visual;var s=v.skeleton;var points={}
 for n in ["pelvis","hand_l","hand_r","Head"]:points[n]=str(v.to_local(s.to_global(s.get_bone_global_pose(s.find_bone(n)).origin)))
 print("CAPTURE_POSE ",label," mode=",v.mode," tree=",v.animation_tree.active," action=",v.action_blend," bones=",points)
func run():
 g=load("res://game/memorial/main.tscn").instantiate();root.add_child(g);await create_timer(.4).timeout;g.save_store.path="user://v413_capture_fixture.json";g.begin();g.flags.intro_done=true;g.stage="STORM";g.set_process(false);g.player.restore(g.world.route.POINTS[6]+Vector3.UP*.01);g.player.locked=false;g.view.set_process_input(false)
 for a in InputMap.get_actions():InputMap.action_erase_events(a)
 g.view.cinematic=true;g.view.camera.global_position=g.player.position+Vector3(0,3,5);g.view.camera.look_at(g.player.position+Vector3.UP)
 Input.action_press("move_forward");await create_timer(1.5).timeout;Input.action_release("move_forward");await create_timer(.12).timeout
 var folder=ProjectSettings.globalize_path("user://verification/capture_probe");DirAccess.make_dir_recursive_absolute(folder)
 for i in 4:
  await process_frame;await RenderingServer.frame_post_draw;describe("ordinary_"+str(i));root.get_texture().get_image().save_png(folder.path_join("ordinary_"+str(i)+".png"))
  RenderingServer.force_draw(false);describe("forced_"+str(i));root.get_texture().get_image().save_png(folder.path_join("forced_"+str(i)+".png"))
 g.main_menu();g.queue_free();await process_frame;quit()
