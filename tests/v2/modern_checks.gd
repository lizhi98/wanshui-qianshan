extends SceneTree
var errors=0
func _initialize(): call_deferred("run")
func check(value:bool,label:String):
	print(("PASS " if value else "FAIL ")+label)
	if not value: errors+=1
func run():
	check(FileAccess.file_exists("res://game/v2/modern.gd"),"interactive structure reconstruction exists")
	if errors: quit(1); return
	var game=load("res://game/remaster/main.tscn").instantiate(); root.add_child(game)
	await create_timer(.4).timeout
	var mod=load("res://game/v2/modern.gd").new(); mod.mission=game; game.add_child(mod)
	game.modern=mod
	mod.start()
	check(not mod.classify(0),"classification before collecting evidence rejected")
	mod.position=mod.scan_points[0]
	check(mod.evidence.global_position.is_equal_approx(Vector3.ZERO),"highlight structure remains anchored to the bridge when camera moves")
	check(mod.collect(),"nearby scan collects evidence")
	check(not mod.classify(1),"wrong structure judgment is recoverable")
	check(mod.classify(0),"observed bottom chains can be classified")
	check(not mod.place_layer(2),"bottom chains cannot be placed as handrails")
	check(mod.place_layer(0),"bottom chains install in the bearing layer")
	check(not mod.place_layer(0),"duplicate placement earns no progress")
	check(not mod.ready_to_finish(),"one layer cannot complete reconstruction")
	for i in [1,2]:
		mod.selected=i; mod.position=mod.scan_points[i]; mod.collect(); mod.classify(i); mod.place_layer([0,2,1][i])
	check(not mod.ready_to_finish(),"historical comparison remains a real required operation")
	mod.compare()
	check(mod.ready_to_finish(),"three correct layers and comparison enable completion")
	var saved=mod.snapshot(); mod.start(); mod.restore_snapshot(saved)
	check(mod.ready_to_finish(),"modern save restores classified and placed layers")
	game.queue_free(); await process_frame; await create_timer(.1).timeout
	quit(1 if errors else 0)
