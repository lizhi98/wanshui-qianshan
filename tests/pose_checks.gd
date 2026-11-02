extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var game = load("res://game/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await create_timer(0.3).timeout
	game.finish_intro()
	game.player.position = Vector3(1.43,0,-16.35)
	game.player.start_climb()
	await create_timer(0.5).timeout
	var skeleton = game.player.visual.skeleton
	var errors = 0
	for name in ["hand_l","hand_r"]:
		var hand = skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone(name)).origin)
		var good = absf(hand.x-1.86)<0.14 and absf(hand.y-1.37)<0.14
		print(("PASS: " if good else "FAIL: ")+name+" grips chain; "+str(hand))
		if not good: errors+=1
	game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	quit(1 if errors else 0)
