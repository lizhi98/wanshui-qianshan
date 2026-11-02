extends SceneTree
var failures := 0
func _initialize(): call_deferred("run")
func check(ok: bool,description: String):
	print(("PASS: " if ok else "FAIL: ")+description)
	if not ok: failures+=1
func run():
	check(FileAccess.file_exists("res://game/remaster/world.gd"),"new canyon and bridge are implemented")
	check(FileAccess.file_exists("res://game/remaster/save_store.gd"),"versioned checkpoint persistence exists")
	check(FileAccess.file_exists("res://game/remaster/modern.gd"),"interactive modern reconstruction exists")
	if failures:
		quit(1)
		return
	var game=load("res://game/remaster/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	await create_timer(.6).timeout
	game.save_store.path="user://remaster_test_checkpoint.json"
	game.begin(true)
	await create_timer(.6).timeout
	check(game.player.position.y>-.4,"mountain path supports the player collision")
	game.dialogue.close(true)
	game.stage="prepare"
	game.tasks={"supply":true,"lookout":true}
	game.choice=1
	game.save_checkpoint()
	game.stage="combat"
	game.choice=0
	check(game.continue_story(),"saved checkpoint can be loaded")
	check(game.stage=="prepare" and game.choice==1,"chapter and branch survive save/load")
	check(game.tasks.get("supply",false),"completed interactions survive save/load")
	check(game.world.bridge_span>=60,"bridge has a convincing long span")
	check(game.world.chain_count==13,"bridge has nine bottom and four side chains")
	check(not game.world.repair_enabled,"unrepaired bridge remains physically closed")
	game.stage="brace"
	game.phase=game.Phase.PICKUP
	game.player.position=Vector3(2.8,.1,3.0)
	game.amu.position=Vector3(3.7,0,3.0)
	game.interact()
	check(game.interaction_busy,"different first cooperation starts a real bracing action")
	game._brace_tick(1.1)
	var held=game.player.visual.hand_targets[0]
	var tying=game.amu.visual.hand_targets[0]
	game._brace_tick(.25)
	check(game.player.visual.hand_targets[0].distance_to(held)<.001,"holder keeps a steady grip")
	check(game.amu.visual.hand_targets[0].distance_to(tying)>.02,"teammate ties the rope instead of copying the holder")
	game._brace_tick(5.0)
	check(game.tasks.get("brace",false) and game.stage=="timber","bracing opens the timber pickup objective")
	game.world.enable_repair()
	game.stage="crossing"
	game.phase=game.Phase.CROSSING
	game.checkpoint=game.Phase.CROSSING
	game.save_checkpoint()
	game.failed=true
	game.retry_checkpoint()
	check(game.world.repair_enabled and not game.failed,"chain retry retains repaired collision")
	check(game.player.position.z<-40,"retry returns to the current chain approach")
	game.start_modern()
	check(game.modern.active,"modern section activates a real camera controller")
	game.modern.position=game.modern.scan_points[0]
	check(game.modern.collect(),"scan works near its observation point")
	check(game.modern.scanned.size()==1,"scan builds a reconstruction stage")
	check(not game.modern.collect(),"duplicate scan cannot inflate progress")
	game.modern.position=Vector3(100,100,100)
	check(not game.modern.collect(),"scan is range gated")
	game.queue_free()
	await process_frame
	await create_timer(.15).timeout
	quit(1 if failures else 0)
