# Isolated staging for visual review. Full input replay is a separate test.
extends SceneTree
var game
var folder="res://test_evidence/remaster/art_review/"
func _initialize(): call_deferred("run")
func capture(name: String):
	await create_timer(.4).timeout
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+name+".png"))
	print("ART ",name)
func camera(position_value: Vector3,look: Vector3,fov := 42.0):
	game.director.active=false
	game.view.cinematic=true
	game.view.camera.global_position=position_value
	game.view.camera.look_at(look)
	game.view.camera.fov=fov
func snapshot(stage: String,pos: Vector3):
	game._apply_snapshot({"stage":stage,"position":[pos.x,pos.y,pos.z],"tasks":{},"kills":2,"version":2,"repair":false})
func run():
	if "--1080" in OS.get_cmdline_user_args(): folder="res://test_evidence/remaster/art_review_1080/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	game=load("res://game/remaster/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	await create_timer(1).timeout
	game.save_store.path="user://remaster_art_review.json"
	game.begin(true)
	game.hud.root_control.hide()
	game.player.locked=true
	for actor in game.marchers+game.enemies: actor.hide()
	for i in 3:
		var actor=[game.player,game.amu,game.zhou][i]
		actor.position=Vector3((i-1)*.85,0,23)
		actor.rotation=Vector3.ZERO
		actor.visual.mode="idle"
		if actor!=game.player:
			actor.moving=false
			actor.fixed_pose="idle"
	camera(Vector3(0,1.35,27.4),Vector3(0,1.05,23),40)
	await capture("01_three_characters")
	game.amu.hide()
	game.zhou.hide()
	game.player.position.x=0
	camera(Vector3(0,1.3,26),Vector3(0,1.05,23),40)
	await capture("02_linchuan_front")
	game.player.rotation.y=PI/2
	await capture("03_linchuan_side")
	game.player.rotation.y=0
	camera(Vector3(0,1.58,24.35),Vector3(0,1.52,23),37)
	await capture("04_linchuan_face")
	game.hud.root_control.show()
	game.player.restore(Vector3(0,.1,23))
	game._reset_camera()
	Input.action_press("move_forward")
	Input.action_press("sprint")
	await create_timer(.75).timeout
	await capture("05_actual_run")
	Input.action_release("move_forward")
	Input.action_release("sprint")
	game.player.locked=true
	game.player.position=Vector3(0,0,23)
	game.zhou.show()
	game.zhou.position=Vector3(1.5,0,23)
	game.amu.position=Vector3(-1.2,0,22.9)
	game.dialogue.start("prologue")
	await create_timer(1).timeout
	game.dialogue.fully_revealed=true
	game.director.frame("close",game.zhou,game.player)
	await create_timer(1).timeout
	await capture("06_zhou_close_dialogue")
	game.director.frame("two",game.zhou,game.player)
	await create_timer(1).timeout
	await capture("07_two_shot_dialogue")
	game.dialogue.close(true)
	snapshot("brace",Vector3(2.8,.1,4.2))
	game.amu.position=Vector3(2.8,0,2.4)
	game.amu.rotation.y=0
	game.amu.moving=false
	game.interact()
	await create_timer(2.0).timeout
	await capture("08_brace_contact")
	await create_timer(2).timeout
	game.stage="carrying"
	game.phase=game.Phase.COOPERATE
	game.player.position=Vector3(.35,0,-8.1)
	game.player.rotation.y=PI
	game.player.carrying=true
	game.amu.position=Vector3(-.65,0,-8.1)
	game.amu.moving=false
	game.amu.rotation.y=PI
	game.world.board.reparent(game.player.visual.carry_anchor,false)
	game.world.board.transform=Transform3D.IDENTITY
	game.interact()
	await create_timer(.7).timeout
	await capture("09_placement_contact")
	await create_timer(1.5).timeout
	if game.dialogue.active: game.dialogue.close(true)
	game.hud.root_control.hide()
	camera(Vector3(-30,15,11),Vector3(0,-1,-39),53)
	await capture("10_bridge_panorama")
	camera(Vector3(-43,10,-23),Vector3(1,-5,-43),60)
	await capture("11_canyon")
	game.start_modern()
	game.hud.root_control.show()
	for i in 3:
		game.modern.selected=i
		game.modern.position=game.modern.scan_points[i]
		game.modern.collect()
	game.modern.orbit()
	await capture("12_modern_reconstruction")
	game.settings_menu()
	await capture("13_settings")
	game.queue_free()
	await process_frame
	await create_timer(.2).timeout
	quit()
