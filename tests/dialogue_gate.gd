extends SceneTree
var game
var failures := 0
var evidence := "res://test_evidence/remaster/"
func _initialize(): call_deferred("run")
func check(condition: bool,message: String):
	print(("PASS: " if condition else "FAIL: ")+message)
	if not condition: failures+=1
func capture(name: String):
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(evidence+name+".png"))
func press(action: String):
	await process_frame
	Input.action_press(action)
	await create_timer(.1).timeout
	Input.action_release(action)
func run():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(evidence))
	game=load("res://game/remaster/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	await create_timer(.7).timeout
	game.begin(true)
	var origin=game.player.position
	Input.action_press("move_forward")
	await create_timer(.65).timeout
	Input.action_release("move_forward")
	await create_timer(.5).timeout
	check(game.player.position.distance_to(origin)>1.0,"new human moves through reused controller")
	await capture("gate_01_walk_to_zhou")
	print("GATE POS ",game.player.position," distance ",game.player.position.distance_to(game.zhou.position)," state ",game.stage," started ",game.started)
	await press("interact")
	await create_timer(1.3).timeout
	check(game.dialogue.active and game.player.locked,"E starts cinematic conversation and locks movement")
	check(game.dialogue.line!=null,"Dialogue Manager compiles and returns a real line")
	if not game.dialogue.line:
		quit(1)
		return
	game.dialogue.advance()
	await capture("gate_02_two_shot")
	game.dialogue.advance()
	await create_timer(1).timeout
	game.dialogue.advance()
	await capture("gate_03_medium")
	var saw_choices=false
	for i in 35:
		if not game.dialogue.active: break
		if game.dialogue.loading:
			await process_frame
			continue
		if game.dialogue.line.responses.size()>0:
			saw_choices=true
			game.dialogue.advance()
			await create_timer(.9).timeout
			await capture("gate_04_choices")
			game.hud.choice_box.get_child(1).pressed.emit()
		else:
			game.dialogue.advance()
		await create_timer(.12).timeout
	check(saw_choices,"player receives interactive branch choices")
	check(game.choice==1,"actual choice button routes the selected branch")
	check(not game.dialogue.active and not game.player.locked,"dialogue ends and restores movement")
	await create_timer(1).timeout
	check(not game.view.cinematic,"camera smoothly returns to third person")
	await capture("gate_05_return_to_game")
	print("DIALOGUE GATE FAILURES ",failures)
	game.queue_free()
	await process_frame
	await create_timer(.2).timeout
	quit(1 if failures else 0)
