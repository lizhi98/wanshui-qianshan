extends SceneTree
var errors:=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok:errors+=1
func run():
	var g=load("res://game/golden_hook/main.tscn").instantiate();root.add_child(g);g.store.path="user://golden_hook_v11_wetland_test.json";g.begin_chapter(true)
	await create_timer(.2).timeout
	check(g.world.has_method("_shore_radius"),"one irregular boundary drives pond, basin and collision")
	if g.world.has_method("_shore_radius"):
		var lo=2.0;var hi=0.0
		for i in 64:var r=g.world._shore_radius(i*TAU/64);lo=minf(lo,r);hi=maxf(hi,r)
		check(hi-lo>.20,"shoreline has distinct inlets and peninsulas")
	for i in 2:
		check(g.world.valid_water(g.world.PONDS[i],i),"pond center remains a valid cast destination "+str(i))
		check(not g.world.valid_water(g.world.BANKS[i],i),"fishing bank remains outside the catchable water "+str(i))
	var variance=absf(g.world.height_at(Vector3(-28,0,-40))-g.world.height_at(Vector3(-22,0,14)))
	check(variance>.3,"meadow elevations vary beyond the earlier flat surface")
	g.queue_free();await process_frame;await process_frame;OS.delay_msec(80);DirAccess.remove_absolute(ProjectSettings.globalize_path("user://golden_hook_v11_wetland_test.json"));quit(1 if errors else 0)
