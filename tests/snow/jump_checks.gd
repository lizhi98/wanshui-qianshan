extends SceneTree
# Geometry fixture: relocate between test sites; all jumps use real player input.
func _initialize():call_deferred("run")
func run():
	var game=load("res://game/snow/main.tscn").instantiate();root.add_child(game);await create_timer(.4).timeout
	game.save_store.path="user://snow_jump_fixture.json"
	for action in InputMap.get_actions():InputMap.action_erase_events(action)
	game.begin();game.intro_clock=23;game._intro(0);game.stage="SUMMIT";game.view.set_process_input(false)
	var failures=0
	for center in game.world.jump_centers:
		var point=game.world.route.at(center-1.3);point.y=game.world.height_at(point)+.18;game.player.restore(point);game._reset_camera();game.weather.clock=7.0
		var tangent=game.world.route.nearest(point).tangent;game.view.camera_rotation=Vector3(-10,rad_to_deg(atan2(-tangent.x,-tangent.z)),0)
		await create_timer(.7).timeout
		print("JUMP_BEFORE pos=",game.player.position," s=",game.world.route.nearest(game.player.position).s," center=",center," ground=",game.player.is_on_floor())
		Input.action_press("move_forward");Input.action_press("sprint");await create_timer(.10).timeout;Input.action_press("jump");await create_timer(.13).timeout;Input.action_release("jump");await create_timer(.5).timeout;Input.action_release("move_forward");Input.action_release("sprint");await create_timer(.22).timeout
		var okay=not game.failed and game.player.is_on_floor() and game.world.route.nearest(game.player.position).s>center+.6
		print(("PASS " if okay else "FAIL "),"physical cleft jump pos=",game.player.position," s=",game.world.route.nearest(game.player.position).s," center=",center," on_floor=",game.player.is_on_floor()," count=",game.stats.jumps)
		if not okay:failures+=1;break
	game.main_menu();game.audio.clear_voice()
	for audio in game.find_children("*","AudioStreamPlayer",true,false):audio.stop();audio.stream=null
	game.queue_free();await process_frame;quit(failures)
