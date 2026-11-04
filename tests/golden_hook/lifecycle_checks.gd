extends SceneTree
## Isolated checkpoint/interrupt fixtures, separate from the input replay.
var errors:=0
func _initialize(): call_deferred("run")
func check(value:bool,label:String):
	print(("PASS " if value else "FAIL ")+label)
	if not value: errors+=1
func run():
	var g=load("res://game/golden_hook/main.tscn").instantiate(); root.add_child(g)
	await process_frame
	g.store.path="user://golden_hook_lifecycle_test.json"
	g.begin_chapter(true)
	g.player.position=g.world.points.greens_a+Vector3(0,.02,.82)
	g._do_action(g._entry("greens_a","greens_a","test pickup"))
	await create_timer(.2).timeout
	g.return_to_menu()
	await create_timer(1.0).timeout
	check(g.story.inventory.greens==0,"returning to title cancels a pending pickup before its reward")
	check(g.player.locked,"an interrupted action cannot unlock the title-screen actor")
	g.begin_chapter(true)
	for id in ["bag_a","bag_b","comrade_a","comrade_b","ration","greens_a","greens_b","deliver_supplies","needle","thread","branch","place_parts","heat","bend","tie","mount"]: g.story.perform(id)
	g.story.add_fish(); g.story.add_fish()
	for id in ["put_fish","put_greens","light_fire"]: g.story.perform(id)
	g.save_checkpoint(); check(g.story.step=="simmer","fixture reaches a saved cooking checkpoint")
	g.continue_chapter()
	await create_timer(5.3).timeout
	check(g.story.step=="serve","loading while soup cooks restarts the finite simmer and cannot softlock")
	g._cancel_dialogue(); g.return_to_menu()
	var sample=load("res://game/golden_hook/chapter_state.gd").new().snapshot()
	sample.step="first_fishing"
	var restored=load("res://game/golden_hook/chapter_state.gd").new()
	check(not restored.restore(sample),"a fishing checkpoint without its crafted hook is rejected")
	g.queue_free(); await process_frame; await process_frame; OS.delay_msec(50)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://golden_hook_lifecycle_test.json"))
	quit(1 if errors else 0)
