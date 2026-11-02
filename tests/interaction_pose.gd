extends SceneTree
var errors := 0
func _initialize(): call_deferred("run")
func run():
	var game = load("res://game/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await create_timer(0.3).timeout
	game.finish_intro()
	game.enemies[0].damage(1000)
	game.enemies[1].damage(1000)
	await create_timer(3.2).timeout
	game.player.position = Vector3(0.9,0.1,2.2)
	game.interact()
	await create_timer(1.05).timeout
	var skeleton = game.player.visual.skeleton
	for i in 2:
		var index = skeleton.find_bone("hand_r" if i==0 else "hand_l")
		var distance = skeleton.to_global(skeleton.get_bone_global_pose(index).origin).distance_to(game.player.visual.hand_targets[i])
		print(("PASS: " if distance<0.10 else "FAIL: ")+"pickup grip distance "+str(distance))
		if distance>=0.10: errors+=1
	if DisplayServer.get_name() != "headless":
		game.view.cinematic = true
		game.view.position = game.player.position+Vector3(-2.5,1.7,0.6)
		game.view.rotation = Vector3.ZERO
		game.view.camera.position = Vector3.ZERO
		game.view.camera.look_at(game.world.board.position+Vector3(0,0.5,0))
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://test_evidence/screenshots/12_pickup_pose_detail.png"))
	game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	quit(1 if errors else 0)
