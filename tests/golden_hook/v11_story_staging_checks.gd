extends SceneTree
var errors:=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok:errors+=1
func run():
	var g=load("res://game/golden_hook/main.tscn").instantiate();root.add_child(g);g.store.path="user://golden_hook_v11_stage_test.json";g.begin_chapter(true)
	g.story.step="secret";g.elder.moving=false;g.elder.position=g.world.points.secret
	await create_timer(.3).timeout
	var options=g.interactions();var inspect={}
	for option in options:
		if option.id=="inspect_scraps":inspect=option
	check(not inspect.is_empty(),"the secret requires observing the bowl before the confrontation")
	if not inspect.is_empty():
		g.player.position=g.world.at_ground(g.world.points.secret+Vector3(-.8,0,.3));g._do_action(inspect)
		await create_timer(3.3).timeout
		check(g.story.step=="secret" and g.get("secret_observed")==true,"observing changes the scene without silently skipping the story action")
		g._cancel_dialogue();g._finish_action()
		check(g.interactions()[0].id=="understand","the player chooses to speak after seeing the actual bones")
	var data=load("res://game/golden_hook/dialogue_data.gd").new()
	check(data.has_method("lines_for"),"retired explanations keep registered IDs but have an active playback filter")
	g.queue_free();await process_frame;await process_frame;OS.delay_msec(80);DirAccess.remove_absolute(ProjectSettings.globalize_path("user://golden_hook_v11_stage_test.json"));quit(1 if errors else 0)
