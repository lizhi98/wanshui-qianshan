extends SceneTree
# Isolated mechanic/save fixtures. These do not count as the full input playthrough.
var errors:=0
var game
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok:errors+=1
func run():
	game=load("res://game/snow/main.tscn").instantiate();root.add_child(game);await create_timer(.4).timeout
	game.save_store.path="user://snow_mechanics_fixture.json"
	if "--restore-fixture" in OS.get_cmdline_user_args():
		check(game.continue_story(),"a new process reads the independent snow checkpoint")
		check(game.stage=="SUMMIT" and game.flags.get("reunion_signal",false),"new process retains snow stage and flags")
		check(game.amu.moving and not game.amu.route.is_empty(),"new process restores the moving companion route")
		check(game.weather.shelter_visits.size()==3 and game.observation.found.size()==4,"new process restores investigation and shelter counts")
		await cleanup();return
	game.begin();game.intro_clock=23;game._intro(0);game.paused=true
	check(game.world.route.total>600 and game.world.route.POINTS[-1].y==119,"continuous winding ascent has real horizontal distance and height")
	var collision_ok=true
	for s in range(10,600,25):
		var p=game.world.route.at(s);var hit=game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p+Vector3.UP*15,p-Vector3.UP*15,1))
		if hit.is_empty() or absf(hit.position.y-game.world.height_at(p))>.2:collision_ok=false
	check(collision_ok,"baked terrain and fine trail collision agree with visible route heights")
	for center in game.world.jump_centers:
		var p=game.world.route.at(center)
		check(game.world.height_at(p)<p.y-5,"cleft has a physical drop rather than a painted obstacle")
	game.weather.gust=1
	var sheltered=game.world.shelter_centers[1];var open=sheltered+Vector3(0,0,6)
	check(game.weather.force_at(sheltered).length()<game.weather.force_at(open).length()*.15,"rock shelter reduces the actual movement force")
	game.player.restore(game.world.route.POINTS[8]+Vector3.UP*.1);game.view.rotation=Vector3.ZERO;game.player.locked=false
	Input.action_press("move_forward");game.weather.exposure=0;game.weather.gust=0;game.player.handle_controls(.016);var calm=game.player.movement_velocity.z
	game.weather.exposure=1;game.weather.gust=1;game.player.handle_controls(.016);var gale=game.player.movement_velocity.z;Input.action_release("move_forward")
	check(gale>calm,"headwind changes actual controller movement rather than only the HUD")
	game.stage="ROUTE_FINDING";game.flags.clear();game.signal_party();check(game.stage=="ROUTE_FINDING" and game.stats.signals==0,"Q cannot skip route investigation")
	game.flags.route_seen=true;game.signal_party();check(game.stage=="ROUTE_FINDING","observing alone cannot replace walking to confirm the path")
	game.stage="REUNION";game.signal_party();check(game.stage=="REUNION","Q cannot skip the ridge overlook")
	game.stage="SUMMIT";game.finish_level();check(game.stage=="SUMMIT","settlement requires both gaps and physically gathered NPCs")
	game.paused=false;game.world.set_collapsed(false);game.world.begin_collapse();game.world.tick(2);var clock=game.world.collapse_time;game.world.begin_collapse()
	check(game.world.collapse_time==clock,"landslide cannot restart while active")
	game.world.tick(5);game.world.begin_collapse();check(game.world.collapse_time>=7 and not game.world.collapse_active,"landslide remains a one-shot event after completion")
	check(game.world.collapse_blocker.collision_layer==1,"landslide creates an actual road blocker")
	var gate_open=true
	for child in game.world.detour_drift.get_children():
		if child is StaticBody3D and child.collision_layer!=0:gate_open=false
	check(gate_open,"landslide opens the previously blocked rock-wall detour")
	game.world.set_collapsed(false);check(game.world.collapse_blocker.collision_layer==0,"new run resets the old-road blocker")
	game.paused=true;game.weather.shelter_visits={"0":true,"1":true,"2":true};game.observation.found={"route":true,"false_route":true,"ridge":true,"ridge_false":true}
	game.flags={"route_seen":true,"route_confirmed":true,"route_signal":true,"collapse_triggered":true,"collapse_evaded":true,"detour_used":true,"ridge_seen":true,"overlook":true,"reunion_signal":true}
	game._send_party(17,27);game.amu.vertical_speed=3.5
	for stage in game.save_store.STAGES:
		game.stage=stage;game.safe_point=game.world.route.POINTS[19]+Vector3.UP*.15;game.save_checkpoint();var data=game.save_store.read()
		check(not data.is_empty() and data.stage==stage,"independent checkpoint round trip: "+stage)
		check(data.actors[0].route.size()>0 and data.actors[0].vertical_speed==3.5,"checkpoint preserves NPC route and airborne velocity: "+stage)
		game.restore_checkpoint(data)
		check(game.stage==stage and game.observation.found.size()==4 and game.amu.vertical_speed==3.5,"live task restoration: "+stage)
		game.paused=true
	game.stage="SUMMIT";game.save_checkpoint();var original=FileAccess.get_file_as_string(game.save_store.path);var bad=game.last_checkpoint.duplicate(true);bad.actors[0].position=[INF,0,0]
	check(not game.save_store.write(bad) and FileAccess.get_file_as_string(game.save_store.path)==original,"invalid save is rejected without replacing a valid checkpoint")
	game.restore_checkpoint(game.last_checkpoint);var before=game.retries;game.fail("fixture fall");game.retry_checkpoint()
	check(not game.failed and game.retries==before+1 and game.player.position.distance_to(game.safe_point)<.01,"failure returns to the latest safe checkpoint and records retry")
	check(game.world.collapse_blocker.collision_layer==1 and not game.world.collapse_active,"retry restores a settled landslide without replaying it")
	game.save_checkpoint();await cleanup()
func cleanup():
	game.main_menu();game.audio.clear_voice();game.spatial_voice.stop();game.collapse_sound.stop()
	for audio in game.find_children("*","AudioStreamPlayer",true,false):audio.stop();audio.stream=null
	game.queue_free();await process_frame;await create_timer(.2).timeout;quit(1 if errors else 0)
