extends SceneTree

func _initialize():
	call_deferred("run")

func run():
	var game = load("res://game/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/Users/17596/Documents/Codex/2026-10-14/files-pasted-by-the-user-3d/work/demo_menu.png")
	game.finish_intro()
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/Users/17596/Documents/Codex/2026-10-14/files-pasted-by-the-user-3d/work/demo_play.png")
	print("SKELETON: ",game.player.visual.skeleton.get_path())
	print("HAND ERROR: ",game.player.visual.hand_error)
	game.queue_free()
	await process_frame
	quit()
