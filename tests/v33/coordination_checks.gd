extends SceneTree
var errors:=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok:errors+=1
func run():
	Engine.time_scale=4
	var game=load("res://game/v2/main.tscn").instantiate();root.add_child(game)
	await create_timer(.4).timeout;game.save_store.path="user://v33_coordination_fixture.json"
	game._apply_snapshot({"version":3,"ledger":{"current":"repair","done":{"march":true,"recon":true,"escort":true}},"modules":{},"position":[0,.05,-7.1],"elapsed":0,"retries":0,"choice":0})
	check(game.get("vanguard")!=null,"repair has a dedicated forward covering squad")
	if game.get("vanguard")!=null:
		await create_timer(12).timeout
		check(game.vanguard.ahead_count()>0,"covering soldiers cross the unplanked gap along the chain ahead of the builder")
		check(game.vanguard.shots>0,"the forward squad fires visible covering shots")
		game.player.carrying=true;await create_timer(6).timeout;game.player.carrying=false
		check(game.vanguard.sacrifice_seen,"frontline sacrifice occurs during bridge construction")
		check(game.audio.recent.has(("林川:不能辜负同志的牺牲，冲啊！").md5_text()),"the sacrifice triggers the response dialogue")
		var state=game.vanguard.snapshot();game.vanguard.restore(state)
		check(game.vanguard.sacrifice_seen,"checkpoint restoration does not replay a completed sacrifice")
	game._apply_snapshot({"version":3,"ledger":{"current":"relay","done":{"march":true,"recon":true,"escort":true,"repair":true,"traversal":true}},"modules":{"repair":{"repaired":[true,true]}},"position":[0,.1,-80.5],"elapsed":10,"retries":0,"choice":0})
	game._module_completed("relay",{});game._process(7)
	check(game.ledger.current=="complete" and game.hud.overlay.visible,"taking the bridge leads directly to the final settlement")
	check(not game.modern.active and not game.hud.modern_panel.visible,"digital reconstruction is absent from the player ending")
	var legacy={"version":3,"ledger":{"current":"modern","done":{"march":true,"recon":true,"escort":true,"repair":true,"traversal":true,"relay":true}},"modules":{},"position":[0,.1,-80.5],"elapsed":10,"retries":0,"choice":0}
	check(game.save_store.valid(legacy),"legacy reconstruction checkpoint remains readable")
	game._apply_snapshot(legacy)
	check(game.ledger.current=="complete" and not game.modern.active,"legacy epilogue checkpoint migrates straight to the new ending")
	game.main_menu();game.audio.clear_voice()
	for node in game.find_children("*","AudioStreamPlayer",true,false):node.stop();node.stream=null
	game.queue_free();await process_frame;await create_timer(.2).timeout;quit(1 if errors else 0)
