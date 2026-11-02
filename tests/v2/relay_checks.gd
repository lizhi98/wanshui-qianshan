extends SceneTree
var errors=0
func _initialize(): call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok: errors+=1
func run():
	check(FileAccess.file_exists("res://game/v2/relay.gd"),"final relay is an actual world interaction controller")
	if errors: quit(1); return
	for action in ["observe","signal"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
	var mission=load("res://tests/v2/chain_fixture.gd").new(); root.add_child(mission)
	var module=load("res://game/v2/relay.gd").new(); mission.add_child(module); module.setup(mission)
	mission.player.position=Vector3(0,0,-75.4)
	mission.amu.position=Vector3(-.7,0,-74); mission.zhou.position=Vector3(.7,0,-74.2)
	module.start()
	module.interact()
	check(module.phase=="observe","pressing E alone cannot resolve the relay")
	mission.view.get_node("Camera").position=Vector3(0,1.5,-74)
	mission.view.get_node("Camera").look_at(Vector3(20,1,-74))
	Input.action_press("observe"); module.tick(1.0); Input.action_release("observe")
	check(module.phase=="observe","looking away does not count as observing the real obstruction")
	mission.view.get_node("Camera").look_at(module.observation_point())
	await physics_frame
	Input.action_press("observe"); module.tick(1.0); Input.action_release("observe")
	check(module.phase=="signal","a real visible target establishes the observation")
	await process_frame
	Input.action_press("signal"); module.tick(.016); Input.action_release("signal")
	check(mission.amu.moving and mission.zhou.moving,"Q causes both teammates to walk toward the rope positions")
	var before=mission.amu.position
	await create_timer(.35).timeout
	check(mission.amu.position.distance_to(before)>.2,"teammate response is movement rather than a status caption")
	module.interact()
	Input.action_press("interact"); module.tick(.5); Input.action_release("interact")
	check(module.pull<.1,"rope will not pull correctly before the support is aligned")
	module.angle=0
	Input.action_press("interact")
	for i in 200: module.tick(1.0/60)
	Input.action_release("interact")
	await create_timer(1.8).timeout
	await process_frame
	Input.action_press("jump"); module.tick(.016); Input.action_release("jump")
	check(module.clear and module.phase=="crossing","direction control, pull and confirmation visibly clear the passage")
	var query=PhysicsRayQueryParameters3D.create(Vector3(0,1,-76),Vector3(0,1,-79),1)
	await physics_frame
	check(mission.get_world_3d().direct_space_state.intersect_ray(query).is_empty(),"raised obstruction no longer blocks the human-height passage")
	var saved=module.snapshot(); module.start(saved)
	check(module.clear and module.phase=="crossing","relay checkpoint keeps the passage open on restore")
	await create_timer(3.0).timeout
	module.tick(.016)
	check(module.phase=="confirm","ending waits for the teammates to actually reach the far side")
	mission.player.position=Vector3(0,0,-80.4); module.interact()
	check(module.phase=="done","the player confirms the final relay after both allies pass")
	module.stop(); mission.queue_free(); await process_frame; await create_timer(.1).timeout; quit(errors)
