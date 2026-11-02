extends SceneTree
var errors:=0
func _initialize(): call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok: errors+=1
func run():
	Engine.time_scale=3
	var game=load("res://game/v2/main.tscn").instantiate(); root.add_child(game)
	await create_timer(.4).timeout
	game.save_store.path="user://v31_battle_fixture.json"
	game._apply_snapshot({"version":3,"ledger":{"current":"repair","done":{"march":true,"recon":true,"escort":true}},"modules":{},"position":[0,.1,-3],"elapsed":0,"retries":0,"choice":0})
	await create_timer(18).timeout
	var d=game.battlefield.diagnostics(); print("BATTLE DIAGNOSTICS ",d)
	check(d.near_artillery_shots>0 and d.far_artillery_shots>0,"NPC artillery fires from both banks")
	check(d.impacts>0 and d.infantry_shots>0,"flying shells produce actual impacts while infantry exchange fire")
	check(d.full_rig_soldiers==16 and d.far_soldiers==72,"foreground squads and distant formations use fixed budgets")
	check(d.active_effects<20 and d.active_shells<8,"projectiles and explosion effects expire instead of accumulating")
	check(game.assault.pool.size()==8,"bridge assault has a bounded eight-person wave")
	var min_x=INF; var max_x=-INF
	for i in game.assault.rows.size():
		if game.assault.rows[i].life!="run": continue
		min_x=minf(min_x,game.assault.pool[i].position.x); max_x=maxf(max_x,game.assault.pool[i].position.x)
	check(max_x-min_x>.8,"waiting fighters fan out across safe bridge space")
	var clock=game.battlefield.clock; var pos=game.assault.pool[0].position
	game.paused=true; await create_timer(.8).timeout
	check(game.battlefield.clock==clock and pos.is_equal_approx(game.assault.pool[0].position),"pause freezes artillery and squads")
	game.paused=false; game.main_menu(); await process_frame
	check(not game.battlefield.active and game.battlefield.shells.is_empty(),"return to title clears ongoing combat effects")
	game.audio.clear_voice()
	for node in game.find_children("*","AudioStreamPlayer",true,false): node.stop(); node.stream=null
	game.queue_free(); await process_frame; await create_timer(.2).timeout; quit(1 if errors else 0)
