extends SceneTree
var errors := 0
func _initialize(): call_deferred("run")
func check(value: bool, text_value: String):
	print(("PASS: " if value else "FAIL: ")+text_value)
	if not value: errors+=1
func run():
	var game = load("res://game/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await create_timer(0.3).timeout
	game.finish_intro()
	game.toggle_pause()
	check(not game.combat.fire_player(),"pause blocks combat")
	game.toggle_pause()
	game.enemies[0].damage(1000)
	game.enemies[1].damage(1000)
	await create_timer(3.2).timeout
	game.player.position = Vector3(0.9,0.1,2)
	game.interact()
	await create_timer(1.6).timeout
	game.player.damage(1000)
	check(game.failed,"carrying player can fail")
	game.retry_checkpoint()
	check(game.phase == game.Phase.PICKUP and not game.player.carrying,"carrying retry restores pickup checkpoint")
	check(game.world.board.get_parent()==game.world and not game.world.repair_enabled,"carrying retry restores timber and gap")
	check(game.enemies[0].dead and game.enemies[1].dead,"completed combat remains completed at pickup checkpoint")
	# Construct a completed repair checkpoint to isolate chain failure from prior actions.
	game.phase = game.Phase.CROSSING
	game.checkpoint = game.Phase.CROSSING
	game.world.board.position = game.world.board_final
	game.world.enable_repair()
	game.assisted = true
	game.player.position = Vector3(1.43,0.1,-16.3)
	game.interact()
	Input.action_press("move_right")
	await create_timer(2.2).timeout
	Input.action_release("move_right")
	check(game.failed,"excessive chain imbalance triggers failure")
	game.retry_checkpoint()
	check(game.world.repair_enabled and game.phase==game.Phase.CROSSING,"chain retry preserves repaired board")
	check(not game.player.climbing and not game.player.carrying and game.player.health==100,"chain retry clears incompatible states")
	var retries = game.retries
	game.restart()
	check(retries==2 and game.retries==0,"full replay resets retry statistics")
	check(not game.assisted and not game.crossed and not game.world.repair_enabled,"full replay resets completion flags")
	game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	quit(1 if errors else 0)
