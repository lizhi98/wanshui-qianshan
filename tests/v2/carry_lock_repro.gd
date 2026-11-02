extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var game=load("res://game/v2/main.tscn").instantiate(); root.add_child(game)
	await create_timer(.2).timeout
	game.started=true; game.paused=false
	game.repair.start({"step":"pickup","material":"good"})
	game.player.position=game.repair.pickup_position()
	game.amu.position=Vector3(-4,0,15)
	game.repair.interact()
	game.repair.tick(.016)
	print("REGRESSION: player locked before helper arrives = ",game.player.locked)
	var failed=game.player.locked
	game.repair.stop(); game.queue_free(); await process_frame
	quit(1 if failed else 0)
