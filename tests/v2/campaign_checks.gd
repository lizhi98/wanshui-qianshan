extends SceneTree
var errors=0
func _initialize(): call_deferred("run")
func check(value:bool,label:String):
	print(("PASS " if value else "FAIL ")+label)
	if not value: errors+=1
func run():
	check(FileAccess.file_exists("res://game/v2/main.tscn"),"V2 has an independent playable entry point")
	if errors: quit(1); return
	var game=load("res://game/v2/main.tscn").instantiate(); root.add_child(game)
	await create_timer(.5).timeout
	game.save_store.path="user://v2_campaign_test.json"
	game.begin(true)
	await create_timer(.7).timeout
	check(not game.failed and game.player.position.y>-.4,"opening spawn stands above the real terrain collision")
	check(game.ledger.current=="march" and game.player.position.z>40,"new game starts with playable marching")
	game.player.position=Vector3(0,0,43); game.march.tick(.1)
	check(not game.march.jumped,"walking up to log does not fake the jumping lesson")
	var before=game.elapsed
	game.toggle_pause(); await create_timer(.1).timeout
	check(game.elapsed==before and game.player.locked,"pause freezes time and controls")
	game.toggle_pause()
	check(not game.player.locked,"resume restores the previous control state")
	var key=InputEventKey.new(); key.physical_keycode=KEY_ESCAPE; key.pressed=true
	Input.parse_input_event(key)
	key=InputEventKey.new(); key.physical_keycode=KEY_ESCAPE; key.pressed=false; Input.parse_input_event(key)
	await process_frame; await process_frame
	check(game.paused,"a fast native Escape tap cannot be lost between frames")
	if game.paused: game.toggle_pause()
	game.save_checkpoint(); var saved=game.save_store.read()
	check(saved.version==3 and saved.ledger.current=="march","real campaign uses isolated version three save")
	game.main_menu(); check(not game.started and game.player.locked,"title cancels active play")
	check(game.continue_story() and game.ledger.current=="march","title can resume the V2 checkpoint")
	var damaged=saved.duplicate(true); damaged.position=["bad",0,0]
	check(not game.save_store.write(damaged),"invalid checkpoint cannot replace the good campaign save")
	check(game.save_store.read().ledger.current=="march","good campaign save survives invalid replacement")
	game.begin(true)
	check(not game.world.v2_repair_is_enabled(0) and not game.world.v2_repair_is_enabled(1),"restarting clears both repaired collisions")
	game.ledger.current="traversal"; game.player.gravity=0; game.player.jump()
	check(game.player.gravity==0,"Space inspection does not launch the player into a jump on the bridge")
	game.main_menu(); game.queue_free(); await process_frame; await create_timer(.3).timeout
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://v2_campaign_test.json"))
	quit(1 if errors else 0)
