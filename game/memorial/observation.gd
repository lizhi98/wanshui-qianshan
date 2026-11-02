extends "res://game/snow/observation.gd"
func tick(delta:float):
	focused=""
	if not mission.camera_observing:return
	var camera=mission.view.camera
	for id in mission.world.clues:
		if not mission.can_observe(id):continue
		var target:Vector3=mission.world.clues[id].point;var diff=target-camera.global_position
		if diff.length()>25 or (-camera.global_basis.z).dot(diff.normalized())<cos(deg_to_rad(6.5)):continue
		var hit=mission.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(camera.global_position,target,1))
		if not hit.is_empty() and hit.position.distance_to(target)>.5:continue
		focused=id;dwell[id]=float(dwell.get(id,0))+delta
		if dwell[id]>.85 and not found.has(id):
			found[id]=true;mission.clue_found(id);return
