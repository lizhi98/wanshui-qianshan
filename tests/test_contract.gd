extends SceneTree

var errors := 0
var game

func _initialize():
	call_deferred("run")

func check(condition: bool, message: String):
	if condition:
		print("PASS: " + message)
	else:
		print("FAIL: " + message)
		errors += 1

func run():
	check(FileAccess.file_exists("res://game/mission.gd"), "full mission exists")
	if errors:
		quit(1)
		return
	game = load("res://game/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await create_timer(0.5).timeout
	check(game.player.visual.skeleton.get_bone_count() > 60, "human has real skeleton")
	check(game.player.visual.animator.has_animation("Walk_Loop"), "walking is a skeletal clip")
	check(game.enemies.size() == 2, "two defenders")
	check(not game.world.repair_enabled, "bridge gap initially has no collision")
	var gap_ray = PhysicsRayQueryParameters3D.create(Vector3(0, 2, -9.5), Vector3(0, -1, -9.5), 1)
	check(game.get_world_3d().direct_space_state.intersect_ray(gap_ray).is_empty(), "physical hole before repair")
	game.interact()
	check(game.phase == game.Phase.INTRO, "intro rejects interactions")
	check(not game.combat.fire_player(), "intro rejects firing")
	game.finish_intro()
	check(game.phase == game.Phase.COMBAT, "opening enters combat")
	game.interact()
	check(game.phase == game.Phase.COMBAT, "combat cannot skip to repair")
	var start = game.player.position
	Input.action_press("move_forward")
	await create_timer(0.35).timeout
	Input.action_release("move_forward")
	check(game.player.position.distance_to(start) > 0.3, "controller responds to WASD")
	var yaw = game.view.camera_rotation.y
	Input.action_press("camera_right")
	await create_timer(0.25).timeout
	Input.action_release("camera_right")
	check(abs(game.view.camera_rotation.y-yaw) > 5, "third-person camera responds")
	var enemy = game.enemies[0]
	enemy.damage(1000)
	check(enemy.health == 0 and enemy.dead, "enemy death clamps health and stops fighting")
	game.player.damage(1000)
	check(game.player.health == 0 and game.failed, "death exposes checkpoint retry")
	game.retry_checkpoint()
	check(game.player.health == 100 and not game.failed, "retry restores health")
	check(game.enemies[0].health == 100 and not game.enemies[0].dead, "combat retry restores defenders")
	check(not game.world.repair_enabled, "combat retry keeps repair gap open")
	game.enemies[0].damage(1000)
	game.enemies[1].damage(1000)
	await create_timer(3.3).timeout
	check(game.phase == game.Phase.PICKUP, "defeating two enemies unlocks board")
	check(not game.amu.moving, "teammate reaches timber along authored path")
	game.player.position = Vector3(0.9, 0.1, 2.0)
	game.interact()
	await create_timer(1.8).timeout
	check(game.player.carrying, "pickup attaches the timber")
	check(game.world.board.get_parent() == game.player.visual.carry_anchor, "timber follows carry node")
	game.player.position = Vector3(0, 0.15, -8.0)
	game.interact()
	check(not game.world.repair_enabled, "placement waits for teammate")
	await create_timer(9.0).timeout
	game.interact()
	await create_timer(2.8).timeout
	check(game.world.repair_enabled, "cooperative placement enables bridge collision")
	check(not game.player.carrying, "placement restores movement")
	check(game.phase == game.Phase.CROSSING, "repair unlocks chain traversal")
	check(not game.get_world_3d().direct_space_state.intersect_ray(gap_ray).is_empty(), "repaired board physically blocks downward ray")
	await create_timer(3.0).timeout
	game.player.position = Vector3(1.45, 0.15, -16.3)
	game.interact()
	check(game.player.climbing, "E enters traversal at chain")
	check(not game.combat.fire_player(), "climbing rejects shooting")
	Input.action_press("move_forward")
	await create_timer(8.5).timeout
	Input.action_release("move_forward")
	check(not game.player.climbing and game.crossed, "visible path traversal reaches opposite end")
	game.player.position = Vector3(0, 0.15, -24.2)
	await create_timer(8.0).timeout
	check(game.phase == game.Phase.ENDING, "complete mission reaches ending")
	game.restart()
	await create_timer(0.3).timeout
	check(game.phase == game.Phase.INTRO and not game.world.repair_enabled, "replay restores beginning and gap")
	check(game.enemies[0].health == 100, "replay restores enemies")
	print("CONTRACT RESULT: %d failures" % errors)
	game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	quit(1 if errors else 0)
