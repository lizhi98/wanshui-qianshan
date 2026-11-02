# Rendered replay uses actual input for locomotion, shooting, reload and interactions.
# No mission teleports, direct enemy damage or phase skips occur in this replay.
extends SceneTree

var game
var failures := 0
var folder := "res://test_evidence/screenshots"

func _initialize(): call_deferred("run")

func check(value: bool, description: String):
	print(("PASS: " if value else "FAIL: ")+description)
	if not value: failures += 1

func shot(name: String):
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+"/"+name+".png"))
	print("SCREENSHOT ",name)

func press(action: String, seconds := 0.08):
	await process_frame
	Input.action_press(action)
	await create_timer(seconds).timeout
	Input.action_release(action)

func dialogue_done():
	var time = 0.0
	while game.dialogue_locked and time < 6:
		await create_timer(0.1).timeout
		time += 0.1

func go_to(point: Vector2, timeout := 12.0):
	var time := 0.0
	game.view.camera_rotation.y = 0
	game.view.camera_rotation.x = -12
	await create_timer(0.35).timeout
	while time < timeout and not game.failed:
		var diff = point-Vector2(game.player.position.x,game.player.position.z)
		if diff.length()<0.14: break
		for action in ["move_left","move_right","move_forward","move_back"]: Input.action_release(action)
		if absf(diff.x)>0.10: Input.action_press("move_right" if diff.x>0 else "move_left")
		if absf(diff.y)>0.10: Input.action_press("move_back" if diff.y>0 else "move_forward")
		await create_timer(0.035).timeout
		time += 0.035
	for action in ["move_left","move_right","move_forward","move_back"]: Input.action_release(action)
	await create_timer(0.2).timeout
	check(Vector2(game.player.position.x,game.player.position.z).distance_to(point)<0.4,"walks to "+str(point))

func shoot_enemy(enemy):
	Input.action_press("aim")
	var time = 0.0
	while not enemy.dead and time < 16 and not game.failed:
		var direction = enemy.position-game.player.position
		game.view.camera_rotation.y = rad_to_deg(atan2(-direction.x,-direction.z))
		# Camera targeting only; weapon still executes its real camera + muzzle rays.
		game.view.camera.look_at(enemy.position+Vector3(0,1.5,0))
		if game.combat.ammo == 0 and not game.combat.reloading:
			Input.action_press("reload")
		else:
			Input.action_release("reload")
		Input.action_press("shoot")
		await process_frame
		time += 1.0/60.0
	Input.action_release("shoot")
	Input.action_release("aim")
	Input.action_release("reload")
	check(enemy.dead,"defender defeated by third-person rifle rays")

func run():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	game = load("res://game/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await create_timer(0.8).timeout
	await shot("01_menu")
	game.begin()
	await create_timer(4.0).timeout
	await shot("02_river_intro")
	await create_timer(8.0).timeout
	await shot("03_dialogue")
	await create_timer(8.8).timeout
	check(game.phase == game.Phase.COMBAT,"cinematic enters playable combat")
	await go_to(Vector2(0,0.2))
	await shoot_enemy(game.enemies[0])
	await shot("04_combat")
	await shoot_enemy(game.enemies[1])
	check(game.phase == game.Phase.PICKUP,"real combat unlocks pickup")
	if game.phase != game.Phase.PICKUP:
		game.queue_free()
		await process_frame
		quit(1)
		return
	await dialogue_done()
	await go_to(Vector2(0.8,2.2))
	await press("interact")
	await create_timer(0.55).timeout
	await shot("05_pickup")
	await create_timer(1.1).timeout
	check(game.player.carrying,"input E picks up board")
	await dialogue_done()
	await go_to(Vector2(0,1.4))
	await go_to(Vector2(0,-6.5))
	await shot("06_carry")
	await go_to(Vector2(0,-7.85))
	await create_timer(2.8).timeout
	await dialogue_done()
	await press("interact")
	await create_timer(0.95).timeout
	await shot("07_cooperative_placement")
	await create_timer(1.4).timeout
	check(game.world.repair_enabled,"input E repairs collision")
	await dialogue_done()
	await go_to(Vector2(0,-12.0))
	check(not game.failed,"player walks across new physical board")
	await shot("08_repaired_bridge")
	await go_to(Vector2(0,-15.7))
	await go_to(Vector2(1.43,-16.15))
	await press("interact")
	check(game.player.climbing,"input E enters chain path")
	Input.action_press("move_forward")
	game.view.camera_rotation.y = 38
	game.view.camera_rotation.x = -26
	await create_timer(3.8).timeout
	await shot("09_chain_traversal")
	await create_timer(3.55).timeout
	Input.action_release("move_forward")
	check(game.crossed,"W traverses chain continuously")
	await go_to(Vector2(0,-24.3))
	await create_timer(8.0).timeout
	check(game.phase == game.Phase.ENDING,"teammates arrive and ending starts")
	await shot("10_ending_dialogue")
	await create_timer(13.0).timeout
	await shot("11_settlement")
	check(game.hud.overlay.visible,"settlement with replay button displayed")
	print("REPLAY RESULT: %d failures; elapsed %.1f seconds; hits %d / shots %d; FPS %d" % [failures,game.elapsed,game.combat.hit_count,game.combat.shots,Performance.get_monitor(Performance.TIME_FPS)])
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
