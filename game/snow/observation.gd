extends RefCounted
var mission
var dwell:Dictionary={}
var found:Dictionary={}
var focused:=""
func setup(m):mission=m
func tick(delta:float):
	focused=""
	if not mission.camera_observing:return
	var camera=mission.view.camera
	for id in mission.world.clues:
		var target=mission.world.clues[id].get("focus",mission.world.clues[id].point+Vector3.UP*.15)
		var diff=target-camera.global_position
		if diff.length()>32 or (-camera.global_basis.z).dot(diff.normalized())<cos(deg_to_rad(8)):continue
		var query=PhysicsRayQueryParameters3D.create(camera.global_position,target,1);var hit=mission.get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and hit.position.distance_to(target)>.65:continue
		focused=id;dwell[id]=float(dwell.get(id,0))+delta
		if dwell[id]>.7 and not found.has(id):found[id]=true;mission.clue_found(id)
func reset():dwell.clear();found.clear();focused=""
