extends SceneTree
var errors:=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok:errors+=1
func pelvis(v):return v.skeleton.get_bone_global_pose(v.skeleton.find_bone("pelvis")).origin.y
func run():
	var g=load("res://game/golden_hook/main.tscn").instantiate();root.add_child(g);g.store.path="user://golden_hook_v11_pacing_test.json";g.begin_chapter(true)
	var v=g.shi.visual;v.reset_pose();await create_timer(.5).timeout;var initial=pelvis(v)
	v.posture="seated";await create_timer(.25).timeout;var mid=pelvis(v);await create_timer(1.8).timeout;var settled=pelvis(v)
	print("SIT_TRANSITION ",initial," -> ",mid," -> ",settled)
	check(mid>settled+.10 and mid<initial+.05,"sitting uses a gradual entrance before the stable seated hold")
	g.story.step="march";g.story.hook_form=4;g.story.inventory.hook=1;g.story.fish_total=2;g.story.done.place_parts=true;g._start_march();await create_timer(3).timeout
	var start=g.player.position;Input.action_press("move_forward");await create_timer(.5).timeout;Input.action_release("move_forward")
	check(not g.dialogue_rows.is_empty() and g.dialogue_group=="march" and g.player.position.distance_to(start)>.6,"the player walks while the marching dialogue continues")
	var saved_position=g.shi.position;g.save_checkpoint();check(not g.store.read().is_empty(),"the checkpoint fixture has a valid complete chapter payload");check(g.continue_chapter(),"the saved marching checkpoint is actually loaded");await create_timer(.15).timeout
	check(g.shi.position.distance_to(saved_position)<.8,"a mid-march checkpoint restores actual companion positions")
	g.return_to_menu();g.queue_free();await process_frame;await process_frame;OS.delay_msec(80);DirAccess.remove_absolute(ProjectSettings.globalize_path("user://golden_hook_v11_pacing_test.json"));quit(1 if errors else 0)
