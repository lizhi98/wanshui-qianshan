extends "res://tests/v2/carry_acceptance.gd"
func shot(label:String):
	await wait(.3)
	RenderingServer.force_draw(false)
	var folder="res://test_evidence/v21"
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder+"/"+label+".png")
func run():
	Engine.max_fps=60
	game=load("res://game/v2/main.tscn").instantiate(); root.add_child(game)
	game.save_store.path="user://carry_visual_only.json"
	await wait(.5)
	for action in InputMap.get_actions(): InputMap.action_erase_events(action)
	game.view.set_process_input(false)
	await fixture(0,false)
	await prepare()
	await shot("01_prepared")
	check(await pickup(),"rendered pickup")
	game.view.camera_rotation=Vector3(-18,65,0)
	await wait(1)
	await shot("02_both_carrying")
	check(await go(Vector3(0,0,3.2)),"rendered bank turn")
	await shot("03_turn")
	game.view.camera_rotation=Vector3(-16,0,0)
	check(await go(game.world.get_v2_gap(0).approach),"rendered carry to gap")
	await shot("04_destination")
	check(await place(),"rendered placement")
	await shot("05_repaired")
	print("VISUAL HAND ERROR ",max_hand_error)
	finish()
