extends SceneTree
# Visual fixtures only. Full acceptance uses qa/snow_replay.gd ordinary inputs.
var game
func _initialize():call_deferred("run")
func shot(label:String):
	await process_frame;await process_frame;RenderingServer.force_draw(false);root.get_texture().get_image().save_png("res://test_evidence/snow/"+label+".png")
func run():
	DirAccess.make_dir_recursive_absolute("res://test_evidence/snow")
	game=load("res://game/snow/main.tscn").instantiate();root.add_child(game)
	await create_timer(.6).timeout;game.save_store.path="user://snow_visual_fixture.json"
	for action in InputMap.get_actions():InputMap.action_erase_events(action)
	await shot("01_title")
	game.begin();await create_timer(1.5).timeout;await shot("02_route_map")
	game.intro_clock=23;game._intro(0);game.view.set_process_input(false)
	game.player.restore(Vector3(0,game.world.height_at(Vector3(0,0,33))+.35,33));game._reset_camera();await create_timer(1).timeout;await shot("03_foothill_trail")
	game.stage="BLIZZARD";game.player.restore(game.world.route.POINTS[8]+Vector3.UP*.2);game._reset_camera();game.view.camera_rotation=Vector3(-8,0,0);await create_timer(1).timeout;await shot("04_shelter_and_snowline")
	game.stage="SLOPE_COLLAPSE";game.player.restore(game.world.route.POINTS[11]+Vector3.UP*.2);game._reset_camera();game.view.camera_rotation=Vector3(-6,0,0);game.world.begin_collapse();await create_timer(3.3).timeout;await shot("05_active_slide")
	game.world.set_collapsed(true);game.stage="REUNION";game.player.restore(game.world.route.POINTS[18]+Vector3.UP*.2);game._reset_camera();game.view.camera_rotation=Vector3(-7,0,0);await create_timer(.8).timeout;await shot("06_high_snow_ridge")
	game.stage="SUMMIT";game.player.restore(game.world.route.POINTS[-1]+Vector3.UP*.2);game._reset_camera();game.view.set_physics_process(false);game.view.camera.global_position=game.player.position+Vector3(3,13,27);game.view.camera.look_at(game.player.position+Vector3(0,2,-15));await create_timer(.5).timeout;await shot("07_summit_panorama")
	game.main_menu();game.audio.clear_voice()
	for audio in game.find_children("*","AudioStreamPlayer",true,false):audio.stop();audio.stream=null
	game.queue_free();await process_frame;await create_timer(.2).timeout;quit()
