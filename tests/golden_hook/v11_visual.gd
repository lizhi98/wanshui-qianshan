extends SceneTree
## Arranged artistic inspection; not a continuous playthrough.
var g
var folder:String
func _initialize():call_deferred("run")
func shot(id:String,eye:Vector3,focus:Vector3,fov:=54.0):
	g.view.cinematic=true;g.view.camera.global_position=eye;g.view.camera.look_at(focus);g.view.camera.fov=fov
	await create_timer(.7).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join(id+".png"));print("V11_SHOT ",id)
func run():
	folder=ProjectSettings.globalize_path("res://../Test_Records/V1_1/Visual");DirAccess.make_dir_recursive_absolute(folder)
	g=load("res://game/golden_hook/main.tscn").instantiate();root.add_child(g);g.store.path="user://golden_hook_v11_visual_test.json";g.begin_chapter(true);g.player.locked=true;g.hud.root.hide()
	await shot("01_camp",Vector3(-13,2.8,16),Vector3(-8,.9,10))
	await shot("02_pond",Vector3(2,3,6),Vector3(14,0,-2),57)
	await shot("03_landscape",Vector3(-16,4.8,-13),Vector3(7,.1,-39),61)
	for actor in [g.player]+g.actors:
		if actor!=g.player:actor.moving=false
		actor.visual.reset_pose();actor.rotation.y=0
		await shot("portrait_"+str(actor.name),actor.position+Vector3(.5,1.55,1.5),actor.position+Vector3(0,1.48,0),37)
	g.elder.position=g.world.points.last_elder;g.elder.rotation.y=0;g.elder.visual.posture="collapsed"
	await create_timer(3).timeout
	var body=g.elder.position+Vector3(0,.12,-.25)
	await shot("rest_front",body+Vector3(0,.65,-2.0),body,58)
	await shot("rest_side",body+Vector3(2.3,.8,0),body,56)
	await shot("rest_overhead",body+Vector3(.01,3.8,.01),body,54)
	g.return_to_menu();g.queue_free();await process_frame;await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://golden_hook_v11_visual_test.json"));quit()
