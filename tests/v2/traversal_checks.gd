extends SceneTree
var errors=0
func _initialize(): call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok: errors+=1
func drive(module,seconds:float,dt:float):
	Input.action_press("move_forward")
	for i in int(seconds/dt):
		Input.action_release("move_left"); Input.action_release("move_right")
		if module.mission.player.balance>.035: Input.action_press("move_left")
		elif module.mission.player.balance<-.035: Input.action_press("move_right")
		module.advance_player(dt)
		if not module.mission.player.climbing: break
	for action in ["move_forward","move_left","move_right"]: Input.action_release(action)
func run():
	check(FileAccess.file_exists("res://game/v2/traversal.gd"),"two-stage wind and support-point controller exists")
	check(FileAccess.file_exists("res://game/v2/player.gd"),"V2 player preserves and extends the old controller")
	if errors: quit(1); return
	var mission=load("res://tests/v2/chain_fixture.gd").new(); root.add_child(mission)
	var module=load("res://game/v2/traversal.gd").new(); mission.add_child(module); mission.traversal=module
	module.setup(mission); module.start()
	module.interact()
	check(mission.player.climbing and module.phase=="climb_a","E grabs the first real chain segment")
	module.advance_player(1.0)
	check(mission.player.climb_progress==0,"stopping does not force traversal progress or surprise failure")
	drive(module,4,1.0/30)
	var sample=Vector2(mission.player.position.z,mission.player.balance)
	module.start(); mission.player.position=Vector3(1.43,.05,-54.3); module.interact()
	drive(module,4,1.0/120)
	check(Vector2(mission.player.position.z,mission.player.balance).distance_to(sample)<.035,"wind and correction remain comparable at 30 and 120 FPS")
	check("风" in module.status().detail,"wind direction is warned before the stronger gust")
	check(("向左" in module.status().detail)==(module._forecast(mission.player.climb_progress)>0),"wind warning tells the player to correct against the predicted push")
	var pause_pos=mission.player.position
	var pause_balance=mission.player.balance
	mission.paused=true
	Input.action_press("move_forward"); module.advance_player(.2); Input.action_release("move_forward")
	check(mission.player.position==pause_pos and mission.player.balance==pause_balance,"paused traversal cannot advance or accumulate imbalance")
	mission.paused=false
	var before_fall=module.snapshot()
	mission.player.balance=.99
	Input.action_press("move_right")
	module.advance_player(.2)
	Input.action_release("move_right")
	check(mission.player.health==0 and not mission.player.climbing,"sustained wrong balance input can fail without a collision glitch")
	mission.player.restore(Vector3(1.43,.05,-54.3))
	module.start(before_fall)
	check(module.phase=="approach" and not mission.player.climbing and mission.player.visual.rotation==Vector3.ZERO,"early chain failure restores the nearby entrance and clears the climbing pose")
	module.interact()
	drive(module,12,1.0/60)
	check(module.phase=="shelter" and not mission.player.climbing,"first segment ends on a real safe support")
	check(module.snapshot().checkpoint==1,"support arrival is saved as a nearby retry point")
	var query=PhysicsRayQueryParameters3D.create(Vector3(1.2,1,-58.2),Vector3(1.2,-1,-58.2),1)
	await physics_frame
	check(not mission.get_world_3d().direct_space_state.intersect_ray(query).is_empty(),"safe support has actual collision")
	module.interact()
	Input.action_press("jump"); module.tick(.016); Input.action_release("jump")
	check(not module.fixed,"an unaligned support cannot be confirmed")
	module.alignment=0
	await process_frame
	Input.action_press("jump"); module.tick(.016); Input.action_release("jump")
	check(module.phase=="tension","alignment confirmation opens a separate rope task")
	Input.action_press("interact")
	for i in 90: module.tick(1.0/60)
	Input.action_release("interact")
	await create_timer(3.0).timeout
	await process_frame
	Input.action_press("jump"); module.tick(.016); Input.action_release("jump")
	check(module.fixed and module.phase=="rest","holding rope plus checking fixes the visible loose plank")
	var restored=module.snapshot()
	module.start(restored)
	check(module.fixed and module.phase=="rest" and module.safe_position().z<-58,"retry retains the repaired crisis at the middle support")
	mission.player.position=module.safe_position(); module.interact()
	drive(module,12,1.0/60)
	check(module.phase=="done" and not mission.player.climbing,"second segment completes through real directional input")
	module.stop()
	check(mission.player.visual.rotation==Vector3.ZERO and not mission.player.carrying,"leaving traversal clears special visual/input state")
	mission.queue_free(); await process_frame; await create_timer(.1).timeout; quit(errors)
