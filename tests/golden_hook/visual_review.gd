extends SceneTree
## Isolated visual probes. These snapshots deliberately arrange cameras/poses;
## they are never counted as the input-only chapter playthrough.
var game
var folder:String
func _initialize(): call_deferred("run")
func capture(id:String):
	await create_timer(.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join(id+".png"))
	print("CAPTURE ",id)
func run():
	folder=ProjectSettings.globalize_path("res://../Test_Records/Visual")
	DirAccess.make_dir_recursive_absolute(folder)
	game=load("res://game/golden_hook/main.tscn").instantiate(); root.add_child(game)
	await capture("01_title")
	game.begin_chapter(true)
	await create_timer(.5).timeout
	await capture("02_camp_gameplay")
	game.player.locked=true; game.view.cinematic=true
	game.view.camera.global_position=Vector3(-13,2.8,16); game.view.camera.look_at(Vector3(-8,.9,10)); game.view.camera.fov=54
	await capture("03_cast_and_camp")
	for actor in [game.player]+game.actors:
		var sk=actor.visual.skeleton
		for bone in ["pelvis","foot_r","foot_l","Head"]:
			var p=sk.to_global(sk.get_bone_global_pose(sk.find_bone(bone)).origin)
			print(actor.name," ",bone,"=",p," ground=",game.world.height_at(p))
	game.view.camera.global_position=Vector3(2,3,6); game.view.camera.look_at(Vector3(14,0,-2)); game.view.camera.fov=57
	await capture("04_pond")
	game.player.position=game.world.at_ground(game.world.BANKS[0]); game.story.step="first_fishing"; game.story.inventory.hook=1
	game.fishing.enter(0)
	await capture("05_fishing_pose")
	game.fishing.exit()
	game.elder.position=game.world.points.secret; game.elder.visual.posture="seated"; game.elder.visual.hold("bowl")
	game.view.cinematic=true; game.view.camera.global_position=game.elder.position+Vector3(-1.8,1.5,2.8); game.view.camera.look_at(game.elder.position+Vector3(0,.9,0))
	await capture("06_secret_pose")
	game.elder.visual.reset_pose(); game.elder.position=game.world.points.last_elder; game.elder.visual.posture="collapsed"
	await create_timer(3).timeout
	game.view.camera.global_position=game.elder.position+Vector3(-1.5,1.4,2.2); game.view.camera.look_at(game.elder.position+Vector3(0,.35,0))
	await capture("07_collapsed_pose")
	game.elder.visual.reset_pose(); game.elder.position=game.world.points.elder
	game.story.step="heat"; game.world.update_story(game.story); game._enter_craft()
	await create_timer(3).timeout
	game.view.camera.global_position=game.world.flame.position+Vector3(-1.1,1.25,1.9); game.view.camera.look_at(game.world.flame.position+Vector3(0,.35,0))
	await capture("08_actual_crafting_pose")
	game._exit_craft(); game.elder.position=game.world.points.secret; game.elder.face(game.world.points.secret+Vector3(0,0,3))
	game.elder.visual.posture="seated"; game.elder.visual.hold("scraps")
	game.view.cinematic=true; game.view.camera.global_position=game.elder.position+Vector3(-1.5,1.4,2.8); game.view.camera.look_at(game.elder.position+Vector3(0,.7,0))
	await capture("09_secret_scraps")
	game.queue_free(); await process_frame; quit()
