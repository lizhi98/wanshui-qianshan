extends SceneTree
var g
var folder:String
func _initialize():call_deferred("run")
func capture(id:String):
	await create_timer(.7).timeout;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(folder.path_join(id+".png"));print("CLOSEUP ",id)
func run():
	folder=ProjectSettings.globalize_path("res://../Test_Records/V1_1/Visual");DirAccess.make_dir_recursive_absolute(folder)
	g=load("res://game/golden_hook/main.tscn").instantiate();root.add_child(g);g.store.path="user://golden_hook_v11_closeup_test.json";g.begin_chapter(true);g.hud.root.hide();g.player.locked=true;g.view.cinematic=true
	var habitat
	for n in g.world.get_children():
		if n.get_script() and n.get_script().resource_path=="res://game/golden_hook/habitat.gd":habitat=n
	for id in habitat.palettes:
		var i=0
		for model in habitat.palettes[id]:
			if i<3:print("PALETTE ",id," ",model.name," ",model.mesh.get_aabb())
			i+=1
	var key=""
	for k in habitat.bins:
		if k.begins_with("grass_medium_01"):key=k;break
	var p=habitat.bins[key].entries[0].point
	g.view.camera.global_position=p+Vector3(.8,.7,1.1);g.view.camera.look_at(p+Vector3(0,.35,0));g.view.camera.fov=48
	await capture("grass_macro")
	g.story.step="heat";g.story.done.needle=true;g.story.done.place_parts=true;g.world.update_story(g.story);g._enter_craft();await create_timer(2).timeout
	g.world.work_hook.set_heat(.7)
	g.view.camera.global_position=g.world.work_hook.global_position+Vector3(.18,.21,.27);g.view.camera.look_at(g.world.work_hook.global_position);g.view.camera.fov=38
	await capture("needle_macro")
	g._exit_craft();g.player.rotation.y=0;g.player.visual.posture="kneel";g.player.visual.hold("bowl")
	g.view.cinematic=true;g.view.camera.global_position=g.player.position+Vector3(.4,.8,.8);g.view.camera.look_at(g.player.position+Vector3(0,.55,.33));g.view.camera.fov=38
	await capture("bowl_contact_macro")
	g.return_to_menu();g.queue_free();await process_frame;await process_frame;OS.delay_msec(80);quit()
