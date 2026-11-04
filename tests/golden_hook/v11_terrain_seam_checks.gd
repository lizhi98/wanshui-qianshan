extends SceneTree
var errors:=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok:errors+=1
func run():
	var world=load("res://game/golden_hook/wetland_world.gd").new();root.add_child(world)
	var distant=world.get_node_or_null("DistantTerrainMesh")
	check(distant!=null,"distant ground exposes its continuous stitched mesh")
	if distant:
		var vertices=distant.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var boundary={}
		for v in vertices:
			if (absf(absf(v.x)-50)<.001 and v.z>=-70.001 and v.z<=40.001) or ((absf(v.z+70)<.001 or absf(v.z-40)<.001) and absf(v.x)<=50.001):
				boundary[Vector2i(roundi(v.x),roundi(v.z))]=v.y
		var all_match=true
		for z in range(-70,41):
			for x in [-50,50]:
				var key=Vector2i(x,z)
				all_match=all_match and boundary.has(key) and absf(float(boundary.get(key,INF))-world.height_at(Vector3(x,0,z)))<.001
		for x in range(-50,51):
			for z in [-70,40]:
				var key=Vector2i(x,z)
				all_match=all_match and boundary.has(key) and absf(float(boundary.get(key,INF))-world.height_at(Vector3(x,0,z)))<.001
		check(all_match and boundary.size()==420,"every metre of the near/far boundary shares the same terrain height")
	world.queue_free();await process_frame;await process_frame;quit(1 if errors else 0)
