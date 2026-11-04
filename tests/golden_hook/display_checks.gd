extends SceneTree
var errors:=0
func _initialize(): call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok: errors+=1
func run():
	var g=load("res://game/golden_hook/main.tscn").instantiate(); root.add_child(g); g.store.path="user://golden_hook_display_test.json"; g.begin_chapter(true)
	await create_timer(.2).timeout
	var collision=g.world.get_node("WetlandCollision").get_instance_id(); var story=g.story.snapshot(); var start=g.player.position
	g.set_performance_mode(true)
	Input.action_press("move_forward"); await create_timer(.5).timeout; Input.action_release("move_forward")
	check(g.player.position.distance_to(start)>.4 and g.player.is_on_floor(),"performance mode retains actual movement and floor collision")
	check(g.world.get_node("WetlandCollision").get_instance_id()==collision and g.story.snapshot()==story,"changing graphics never rebuilds collision or changes task progress")
	check(g.world.grass_batch.multimesh.visible_instance_count>0 and g.world.grass_batch.multimesh.visible_instance_count<g.world.grass_batch.multimesh.instance_count,"the lower load profile keeps a populated wetland")
	g.set_performance_mode(false)
	check(is_equal_approx(root.scaling_3d_scale,1.0) and g.world.sun.shadow_enabled,"standard graphics restore full resolution and shadows")
	g.settings_menu(); await process_frame
	var viewport=Rect2(Vector2.ZERO,root.get_visible_rect().size)
	var inside=true
	for button in g.hud.menu_buttons.get_children(): inside=inside and viewport.encloses(button.get_global_rect())
	check(inside,"all settings buttons fit within the design viewport")
	g.begin_chapter(true); g.busy=true; g.view.cinematic=true; await process_frame
	check(not g.hud.task_backdrop.visible and not g.hud.marker.visible,"a prop close-up cannot be covered by task or target panels")
	g.return_to_menu(); g.queue_free(); await process_frame; await process_frame; OS.delay_msec(50)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://golden_hook_display_test.json")); quit(1 if errors else 0)
