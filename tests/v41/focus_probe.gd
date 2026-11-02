extends SceneTree
# Isolated camera/clue fixture, not a full playthrough.
func _initialize():call_deferred("run")
func run():
	var g=load("res://game/memorial/main.tscn").instantiate();root.add_child(g);await create_timer(.3).timeout;g.save_store.path="user://v41_focus_fixture.json";g.begin();g.flags.intro_done=true;g.flags.inspected=true;g.flags.coat_seen=true;g.stage="DISCOVERY";g.hud.center_title.text="";g.player.restore(g.world.MEMORIAL+Vector3(0,.1,-1.7));g.player.locked=false;g.quartermaster.position=g.world.MEMORIAL;g.quartermaster.pose_name="seated";g.view.set_process_input(false);g._reset_camera()
	for a in InputMap.get_actions():InputMap.action_erase_events(a)
	g.flags.erase("coat_seen");var runner=load("res://qa/memorial_replay.gd").new();root.add_child(runner);runner.game=g
	await runner.observe("coat");await runner.observe("ledger")
	var c=g.view.camera;var target:Vector3=g.world.clues.ledger.point
	print("FOCUS_DIAG found=",g.observation.found," active=",g.camera_observing," eye=",c.global_position," target=",target," dot=",(-c.global_basis.z).dot((target-c.global_position).normalized())," rotation=",g.view.camera_rotation," dwell=",g.observation.dwell," ray=",g.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(c.global_position,target,1)))
	g.queue_free();await process_frame;quit()
