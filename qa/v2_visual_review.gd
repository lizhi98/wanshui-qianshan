# Authored fixture views for inspection, separate from input playthrough evidence.
extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var game=load("res://game/v2/main.tscn").instantiate(); root.add_child(game)
	await create_timer(.6).timeout
	game.begin(true); game.set_process(false)
	game.repair.start({"site":0,"step":"pickup","material":"good","repaired":[false,false]})
	game.player.position=game.repair.safe_position(); game.player.rotation.y=PI; game.player.rotation_direction=PI
	game.repair.interact(); game.amu.position=game.repair._helper_goal(); game.repair.tick(.016)
	game.ledger.current="repair"; game.current_module=game.repair
	game.paused=true; game.hud.hide_menu(); game.view.cinematic=true
	var board=game.repair.active_board
	print("BOARD ",board.global_position," scale ",board.global_basis.get_scale()," visible ",board.is_visible_in_tree()," player ",game.player.position)
	var folder=ProjectSettings.globalize_path("user://verification/v2_visual_review")
	DirAccess.make_dir_recursive_absolute(folder)
	for entry in [["carry_front",Vector3(2.3,2.5,12)],["carry_side",Vector3(8,2.6,6.4)],["carry_rear",Vector3(-3,2.6,5)]]:
		game.view.camera.global_position=entry[1]; game.view.camera.look_at(board.global_position-Vector3(0,.25,0))
		await create_timer(.3).timeout; RenderingServer.force_draw(false)
		root.get_texture().get_image().save_png(folder.path_join(entry[0]+".png"))
	game.queue_free(); await process_frame; await create_timer(.4).timeout; quit()
