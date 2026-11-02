extends SceneTree
var game
func _initialize(): call_deferred("run")
func shot(label:String):
	await process_frame; await process_frame; RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png("res://test_evidence/v31/"+label+".png")
func run():
	DirAccess.make_dir_recursive_absolute("res://test_evidence/v31")
	game=load("res://game/v2/main.tscn").instantiate(); root.add_child(game)
	await create_timer(.4).timeout
	game.save_store.path="user://v31_visual_fixture.json"; game.view.set_process_input(false)
	game._apply_snapshot({"version":3,"ledger":{"current":"repair","done":{"march":true,"recon":true,"escort":true}},"modules":{},"position":[.25,.1,-3.1],"elapsed":0,"retries":0,"choice":0})
	game.view.camera_rotation=Vector3(-10,0,0)
	await create_timer(5).timeout; await shot("01_two_bank_battle")
	await create_timer(8).timeout; await shot("02_squad_cover")
	game._apply_snapshot({"version":3,"ledger":{"current":"traversal","done":{"march":true,"recon":true,"escort":true,"repair":true}},"modules":{"repair":{"repaired":[true,true]}},"position":[1.43,.05,-54.35],"elapsed":0,"retries":0,"choice":0})
	game.view.camera_rotation=Vector3(-14,-15,0)
	await create_timer(1.5).timeout; game.traversal.interact(); Input.action_press("move_forward")
	await create_timer(1.3).timeout; await shot("03_climb_reach")
	await create_timer(.45).timeout; await shot("04_climb_weight_shift")
	await create_timer(3).timeout; Input.action_release("move_forward")
	await create_timer(.7).timeout; await shot("05_climb_hold")
	print("VISUAL BATTLE ",game.battlefield.diagnostics()," CLIMB_HAND_ERROR ",game.player.visual.hand_error)
	game.battlefield.stop(); game.assault.stop(); game.audio.clear_voice()
	for node in game.find_children("*","AudioStreamPlayer",true,false): node.stop(); node.stream=null
	game.queue_free(); await process_frame; await create_timer(.2).timeout; quit()
