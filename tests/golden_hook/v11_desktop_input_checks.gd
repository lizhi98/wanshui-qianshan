extends SceneTree
var errors:=0
var g
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok:errors+=1
func key(logical:int,physical:int,pressed:bool):
	var e=InputEventKey.new();e.keycode=logical;e.physical_keycode=physical;e.pressed=pressed;Input.parse_input_event(e)
	await process_frame
func tap(logical:int,physical:int):
	await key(logical,physical,true);await key(logical,physical,false)
func run():
	g=load("res://game/golden_hook/main.tscn").instantiate();root.add_child(g);g.store.path="user://golden_hook_desktop_input_checks.json";g.begin_chapter(true)
	await create_timer(.25).timeout
	# Native desktop input was observed with a correct logical key but the
	# same nonmatching physical code for both Escape and W.
	await tap(KEY_ESCAPE,4194313)
	check(g.paused and g.hud.menu.visible,"logical Escape opens the actual pause menu with a nonmatching physical code")
	if g.paused:g.toggle_pause()
	await tap(0,KEY_ESCAPE);check(g.paused,"physical Escape remains supported")
	await tap(0,KEY_ESCAPE);check(not g.paused and not g.hud.menu.visible,"second physical Escape restores normal play")
	var before=g.player.position
	await key(KEY_W,4194313,true);await create_timer(.18).timeout
	check(Input.is_action_pressed("move_forward") and g.player.position.distance_to(before)>.03,"logical W drives the actual player controller")
	await key(KEY_W,4194313,false);await create_timer(.2).timeout
	check(not Input.is_action_pressed("move_forward"),"logical key release clears movement without a stuck key")
	# Arranged module fixture; this is separate from the continuous input video.
	g.player.restore(g.world.at_ground(g.world.points.bag_a+Vector3(0,0,.7)))
	await tap(KEY_E,4194313)
	check(g.busy,"logical E begins the ordinary nearby interaction")
	await create_timer(2.5).timeout
	check(g.story.done.get("bag_a",false),"logical E completes the real bag inspection transaction")
	g.story.step="first_fishing";g.fishing.enter(0);g.fishing.model.state=g.fishing.Model.State.WAITING
	await tap(KEY_SPACE,4194313)
	check(g.fishing.model.state==g.fishing.Model.State.ESCAPED,"logical Space reaches the unchanged early-strike failure rule")
	await tap(KEY_E,4194313)
	check(g.fishing.model.state==g.fishing.Model.State.PREPARE,"logical E retries fishing after a missed strike")
	await tap(KEY_Q,4194313)
	check(not g.fishing.active,"logical Q exits fishing and restores the controller")
	g.story.step="supplies"
	g._cancel_dialogue();g.busy=false;g.player.locked=false;g.view.cinematic=false;g.hud.menu.hide()
	for size in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size=size
		await process_frame;await process_frame;await process_frame
		var card=g.hud.task_backdrop.get_global_rect();var inv=g.hud.inventory.get_global_rect()
		print("TASK_CARD ",card," INVENTORY ",inv," visible=",g.hud.task_backdrop.visible," busy=",g.busy)
		check(card.encloses(inv),"two-line objective and inventory fit inside the task card at "+str(size))
	g.return_to_menu();g.queue_free();g=null;await process_frame;await process_frame;await create_timer(.2).timeout
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://golden_hook_desktop_input_checks.json"));quit(1 if errors else 0)
