extends SceneTree
func _initialize():call_deferred("run")
func run():
	var game=load("res://game/snow/main.tscn").instantiate();root.add_child(game);await create_timer(.3).timeout
	game.player.restore(game.world.route.POINTS[19]+Vector3.UP*.15);game.amu.position=game.world.route.POINTS[16];game._reset_camera();game.view.set_process_input(false)
	var d=game.amu.position+Vector3.UP*1.3-game.view.global_position
	game.view.camera_rotation=Vector3(rad_to_deg(atan2(d.y,Vector2(d.x,d.z).length())),rad_to_deg(atan2(-d.x,-d.z)),0)
	await create_timer(1).timeout
	var eye=game.view.camera.global_position;var target=game.amu.position+Vector3.UP*1.3
	print("SIGHT ",game._party_visible()," eye=",eye," target=",target," hit=",game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(eye,target,1)))
	game.queue_free();await process_frame;quit()
