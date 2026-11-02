extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://game/memorial/main.tscn").instantiate();root.add_child(g);await create_timer(.4).timeout;g.save_store.path="user://v413_seated_reference_fixture.json";g.begin();g.flags.intro_done=true;g.stage="DISCOVERY";g.set_process(false);g.set_physics_process(false);g.hud.root_control.hide();g.crowd.hide();g.crowd.set_physics_process(false);g.weather.flakes.hide();g.weather.mist.hide();g.audio.clear_voice();g.view.cinematic=true;g.view.set_process_input(false)
 for a in g.actors():a.moving=false;a.hide()
 g.player.hide();g.player.locked=true;var a=g.quartermaster;a.show();a.position=g.world.MEMORIAL;a.rotation.y=2.214;a.pose_name="seated";a.get_node("CampName").hide();await create_timer(2.1).timeout
 var folder=""
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--reference-output="):folder=arg.trim_prefix("--reference-output=")
 DirAccess.make_dir_recursive_absolute(folder)
 var center=a.position+Vector3.UP*.45;var forward=a.global_basis.z;var right=a.global_basis.x
 var offsets=[forward*3.1+Vector3.UP*.65,right*3.1+Vector3.UP*.55,-right*3.1+Vector3.UP*.55,(forward+right)*2.5+Vector3.UP*2.6]
 var names=["SeatedFront","SeatedLeft","SeatedRight","SeatedHigh"]
 for i in 4:
  g.view.camera.global_position=center+offsets[i];g.view.camera.look_at(center);await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(folder.path_join(names[i]+".png"))
 print("SEATED_REFERENCE_RENDERED ",folder);g.main_menu();g.queue_free();await process_frame;quit()
