extends SceneTree
var errors:=0
func _initialize(): call_deferred("run")
func check(value:bool,label:String):
	print(("PASS " if value else "FAIL ")+label)
	if not value: errors+=1
func run():
	check(ResourceLoader.exists("res://game/golden_hook/chapter.tscn"),"chapter has an independent launchable scene")
	if errors: quit(1); return
	var g=load("res://game/golden_hook/main.tscn").instantiate()
	root.add_child(g)
	g.store.path="user://golden_hook_integration_test.json"
	await create_timer(.5).timeout
	check(g.player.get_script().get_base_script().resource_path=="res://game/v2/player.gd","chapter inherits existing V2 controller")
	check(g.view.get_script().resource_path=="res://game/camera.gd","chapter uses the established camera directly")
	check(g.actors.size()==3,"elder and two comrades are independent 3D actors")
	for actor in [g.player]+g.actors:
		check(actor.visual.skeleton.get_bone_count()==53,"actual animated 53-bone rig: "+str(actor.name))
	for actor in [g.shi,g.qing]:
		var skeleton=actor.visual.skeleton
		for side in ["r","l"]:
			var foot=skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("foot_"+side)).origin)
			check(foot.y-g.world.height_at(foot)<.085,"seated boots stay grounded: "+str(actor.name)+side)
	check(g.world.work_hook==g.world.hook_ground,"one physical hook prop persists from crafting to preservation")
	check(g.world.distant_column.size()==6,"six skeletal marchers provide a moving distant column")
	check(g.world.surface_at(Vector3(-10,0,-24))=="swamp","dangerous bog has a dedicated terrain state")
	check(g.world.surface_at(Vector3(2,0,1))=="mud","mud has a separate movement state")
	check(g.world.surface_at(Vector3(-1,0,-14))=="shallow","shallow water is traversable and distinct from deep pond")
	check(g.world.valid_water(Vector3(14,-.16,-2),0),"first pond accepts only water landing positions")
	check(not g.world.valid_water(Vector3(-8,0,10),0),"camp cannot be a valid fishing target")
	check(not g.try_fishing(),"fishing cannot begin outside an active objective and bank")
	g.begin_chapter(true)
	await create_timer(.5).timeout
	check(g.player.position.y>-.2 and g.player.is_on_floor(),"player stands on actual wetland collision")
	print("GROUND_DIAGNOSTIC ",g.player.position," height=",g.world.height_at(g.player.position)," floor=",g.player.is_on_floor()," locked=",g.player.locked)
	var hook_points=PackedVector3Array([Vector3(0,.055,0),Vector3(0,.013,0),Vector3(0,.013,0)])
	var prop=load("res://game/golden_hook/props.gd").polyline(g,hook_points,.002,StandardMaterial3D.new())
	check(prop.get_child_count()==1,"coincident curve points never create zero-length cylinders")
	var start=g.player.position
	Input.action_press("move_forward")
	await create_timer(.5).timeout
	Input.action_release("move_forward")
	check(g.player.position.distance_to(start)>.4,"inherited camera-relative keyboard control moves the player")
	check(not g.story.done.get("greens_a",false),"nearby scenery cannot automatically grant a pickup")
	var elapsed=g.elapsed
	g.toggle_pause(); await create_timer(.1).timeout
	check(g.paused and g.player.locked and g.elapsed==elapsed,"pause freezes play, fishing and narrative clocks")
	g.toggle_pause()
	check(not g.paused and not g.player.locked,"resume restores playable control")
	g.save_checkpoint()
	check(not g.store.read().is_empty(),"real scene checkpoint writes a valid inherited store payload")
	var saved_inventory=g.story.inventory.duplicate(true)
	g.player.position=g.world.at_ground(Vector3(-10,0,-24))+Vector3(0,.04,0)
	await create_timer(5.9).timeout
	check(g.world.surface_at(g.player.position)=="grass" and g.story.inventory==saved_inventory,"actual bog sinking returns to safe ground without losing inventory")
	g.player.restore(g.world.at_ground(Vector3(6.1,0,-2))+Vector3(0,.06,0))
	g.view.camera_rotation.y=0; g.view.rotation.y=0
	Input.action_press("move_right"); await create_timer(1.6).timeout; Input.action_release("move_right")
	check(g.player.position.x<7.5 and g.player.position.y>-.3,"physical shoreline collision prevents walking into the deep fishing pond")
	g.return_to_menu(); g.queue_free(); await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://golden_hook_integration_test.json"))
	quit(1 if errors else 0)
