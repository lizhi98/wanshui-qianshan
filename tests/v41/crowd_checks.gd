extends SceneTree
# Regression for disconnected silhouette parts in the background marching LOD.
func _initialize():
	var column=load("res://game/memorial/crowd.gd").new();var errors=0
	for link in [[0,1],[1,2],[0,3],[0,4],[0,5],[0,6],[0,7]]:
		var connected=true
		for sample in 16:
			var phase=sample*TAU/16
			var a=column._part(link[0],phase,true)*column._shape(link[0],10).get_aabb()
			var b=column._part(link[1],phase,true)*column._shape(link[1],10).get_aabb()
			if not a.intersects(b):connected=false
		print(("PASS " if connected else "FAIL ")+"marching LOD bounds remain connected through gait: "+str(link))
		if not connected:errors+=1
	column.free();quit(1 if errors else 0)
