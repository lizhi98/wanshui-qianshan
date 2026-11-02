extends SceneTree
var g
var folder=""
func _initialize():call_deferred("run")
func shot(label):
 await process_frame;await RenderingServer.frame_post_draw
 var v=g.player.visual;var s=v.skeleton;var points={}
 for n in ["pelvis","hand_l","hand_r","Head"]:points[n]=str(v.to_local(s.to_global(s.get_bone_global_pose(s.find_bone(n)).origin)))
 print("ACTION_REST ",label," mode=",v.mode," pose=",v.narrative_pose," action=",v.action_blend," points=",points)
 root.get_texture().get_image().save_png(folder.path_join(label+".png"))
func run():
 g=load("res://game/memorial/main.tscn").instantiate();root.add_child(g);await create_timer(.4).timeout;g.save_store.path="user://v413_action_rest_fixture.json";g.begin();g.flags.intro_done=true;g.set_process(false);g.set_physics_process(false);g.player.locked=true;g.hud.root_control.hide();g.crowd.hide();g.weather.flakes.hide();g.weather.mist.hide();g.view.cinematic=true;g.view.camera.global_position=g.player.position+Vector3(0,1.7,4);g.view.camera.look_at(g.player.position+Vector3.UP)
 folder=ProjectSettings.globalize_path("user://verification/action_rest_probe");DirAccess.make_dir_recursive_absolute(folder)
 for clip in ["Idle_Loop","Walk_Loop","Push_Loop","Push","Interact","PickUp_Table","Jump_Loop"]:
  if not g.player.visual.animator.has_animation(clip):print("MISSING_CLIP ",clip);continue
  var a=g.player.visual.animator.get_animation(clip);print("CLIP ",clip," duration=",a.length," tracks=",a.get_track_count())
 await create_timer(2).timeout;await shot("initial_idle")
 for pose in ["clear","take","inspect"]:
  g.player.visual.pose(pose);g.player.visual.mode="pickup";await create_timer(6).timeout;await shot(pose)
  g.player.visual.pose("");g.player.visual.mode="idle";await create_timer(3).timeout;await shot("idle_after_"+pose)
 g.main_menu();g.queue_free();await process_frame;quit()
