extends RefCounted
# Local support-aware A*: capsules test actual scene geometry, not decorative meshes.
# Paths are rebuilt on request/stall; gameplay never waits on a navigation signal.
const CELL=0.35
var host:Node3D
var graph:AStar3D
var points:Array[Vector3]=[]
var last_error=""

func setup(node:Node3D): host=node

func supported(point:Vector3)->bool:
	var space=host.get_world_3d().direct_space_state
	for offset in [Vector3.ZERO,Vector3(0,0,.12),Vector3(0,0,-.12)]:
		var q=PhysicsRayQueryParameters3D.create(point+offset+Vector3(0,.30,0),point+offset-Vector3(0,.24,0),1)
		if not space.intersect_ray(q).is_empty(): return true
	return false

func clear_at(point:Vector3)->bool:
	if not supported(point): return false
	var shape=CapsuleShape3D.new(); shape.radius=.30; shape.height=1.70
	var q=PhysicsShapeQueryParameters3D.new(); q.shape=shape
	q.transform=Transform3D(Basis.IDENTITY,point+Vector3(0,.90,0)); q.collision_mask=1; q.margin=.015
	return host.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty()

func route(start:Vector3,goal:Vector3)->Array[Vector3]:
	graph=AStar3D.new(); points.clear(); last_error=""
	var lo_z=floori((minf(start.z,goal.z)-2.0)/CELL)
	var hi_z=ceili((maxf(start.z,goal.z)+2.0)/CELL)
	var cells={}
	for z in range(lo_z,hi_z+1):
		for x in range(-21,22):
			var p=Vector3(x*CELL,0,z*CELL)
			if clear_at(p):
				var id=points.size(); points.append(p); cells[Vector2i(x,z)]=id; graph.add_point(id,p)
	for cell in cells:
		for offset in [Vector2i(1,0),Vector2i(0,1)]:
			var next=cell+offset
			if cells.has(next): graph.connect_points(cells[cell],cells[next])
	if points.is_empty(): last_error="no walkable floor"; return []
	var a=graph.get_closest_point(start); var b=graph.get_closest_point(goal)
	if points[b].distance_to(goal)>.55 or points[a].distance_to(start)>1:
		last_error="endpoint unavailable"; return []
	var raw=graph.get_point_path(a,b)
	var result:Array[Vector3]=[]
	for p in raw: result.append(p)
	if result.is_empty(): last_error="disconnected route"; return []
	if clear_at(goal): result.append(Vector3(goal.x,0,goal.z))
	return result
