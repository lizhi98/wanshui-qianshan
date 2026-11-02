extends SceneTree
func _initialize():call_deferred("run")
func run():
	var g=load("res://game/memorial/main.tscn").instantiate();root.add_child(g);await create_timer(.3).timeout;g.save_store.path="user://v41_gait_fixture.json";g.begin();g.flags.intro_done=true;g.player.locked=false;g._reset_camera();g.view.set_process_input(false)
	for a in InputMap.get_actions():InputMap.action_erase_events(a)
	await create_timer(.3).timeout;var marks=g.world._footprints();var before=marks.emitted;Input.action_press("move_forward");await create_timer(2.2).timeout;Input.action_release("move_forward");await create_timer(.2).timeout
	var state=marks.gait.get(g.player.get_instance_id(),{});var okay=marks.emitted>before+1 and not state.is_empty() and state.get("last","") in ["l","r"]
	print(("PASS " if okay else "FAIL "),"real animated foot contacts emit alternating ground footprints; count=",marks.emitted-before," gait=",state)
	g.main_menu();g.audio.clear_voice();g.queue_free();await process_frame;quit(0 if okay else 1)
