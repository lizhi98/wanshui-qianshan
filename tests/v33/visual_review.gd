extends SceneTree
var game
func _initialize():call_deferred("run")
func shot(label:String):
	await process_frame;await process_frame;RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png("res://test_evidence/v33/"+label+".png")
func run():
	DirAccess.make_dir_recursive_absolute("res://test_evidence/v33")
	game=load("res://game/v2/main.tscn").instantiate();root.add_child(game)
	await create_timer(.5).timeout;game.save_store.path="user://v33_visual_fixture.json"
	for action in InputMap.get_actions():InputMap.action_erase_events(action)
	game._apply_snapshot({"version":3,"ledger":{"current":"repair","done":{"march":true,"recon":true,"escort":true}},"modules":{},"position":[0,.05,-6.5],"elapsed":0,"retries":0,"choice":0})
	game.view.set_process_input(false);game.view.camera_rotation=Vector3(-9,0,0)
	await create_timer(9).timeout;await shot("01_forward_cover_across_gap")
	game.view.set_physics_process(false);game.view.camera.position=Vector3.ZERO;game.view.position=Vector3(-13,game.world._ground_height(-13,8,true)+.9,8);game.view.rotation=Vector3.ZERO;game.view.camera.look_at(Vector3(-10,game.world._ground_height(-10,12,true)+.3,12));game.view.camera.fov=60
	await create_timer(.5).timeout;await shot("02_curved_grass_ferns_and_shrubs")
	game.view.position=Vector3(-8.4,game.world._ground_height(-8.4,5.1,true)+1.5,5.1);game.view.camera.look_at(Vector3(-9,1.2,16));game.view.camera.fov=63
	await create_timer(.4).timeout;await shot("03_dressed_bank")
	game.player.set_physics_process(false);game.player.position=Vector3(0,0,10);game.player.rotation=Vector3(0,PI,0);game.player.visual.mode="idle";game.player.visual.armed=false
	game.view.position=Vector3(.85,1.6,11.5);game.view.camera.look_at(game.player.position+Vector3(0,1.17,0));game.view.camera.fov=49
	await create_timer(.5).timeout;await shot("04_cloth_and_equipment")
	print("VEGETATION groups=",game.vegetation.groups.size()," FORWARD shots=",game.vanguard.shots)
	game.main_menu();game.audio.clear_voice()
	for node in game.find_children("*","AudioStreamPlayer",true,false):node.stop();node.stream=null
	game.queue_free();await process_frame;await create_timer(.2).timeout;quit()
