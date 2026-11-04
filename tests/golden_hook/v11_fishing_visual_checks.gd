extends SceneTree
var errors:=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok:errors+=1
func run():
	var g=load("res://game/golden_hook/main.tscn").instantiate();root.add_child(g);g.store.path="user://golden_hook_v11_fish_test.json";g.begin_chapter(true)
	g.player.position=g.world.at_ground(g.world.BANKS[0]);g.story.step="first_fishing";g.story.inventory.hook=1;g.story.hook_form=4;g.fishing.enter(0)
	var f=g.fishing;var M=f.Model.State
	check(f.get("rod_segments") is Array and f.get("rod_segments").size()>=12,"a continuous flexible rod has multiple visible sections")
	check(g.hud.fishing_panel.size.x<=370 and g.hud.fishing_panel.size.y<=185,"dedicated fishing UI leaves the water and actor visible")
	f.power=.35;f._cast();var low=f.landing;f.model.prepare();f.power=.8;f._cast()
	check(f.landing.distance_to(low)>2.5,"cast charge changes the actual world landing point")
	f.model.state=M.REELING;f.model.tension=.78;f.model.progress=.5;f.tick(.03)
	check(f.get("rod_bend")!=null and f.get("rod_bend")>.03,"line tension visibly bends the rod")
	f.model.state=M.CAUGHT;f.catch_animation=.5;f.tick(.02)
	check(f.hooked_fish.visible and f.hooked_fish.global_position.y>-.1,"the caught fish actually rises above the water")
	f.exit();await process_frame
	check(not f.active and not g.player.visual.external_grip and g.player.visual.hand_targets.is_empty(),"leaving fishing clears hand and prop pose ownership")
	g.queue_free();await process_frame;await process_frame;OS.delay_msec(80);DirAccess.remove_absolute(ProjectSettings.globalize_path("user://golden_hook_v11_fish_test.json"));quit(1 if errors else 0)
