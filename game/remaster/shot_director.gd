extends Node
var mission
var active := false
var returning := false
var destination: Transform3D
var target_fov := 44.0
var saved: Transform3D
var saved_fov := 66.0
var return_time := 0.0
var shots_used: Dictionary = {}

func enter():
	if active:
		returning=false
		return
	var camera = mission.view.camera
	saved = camera.global_transform
	saved_fov = camera.fov
	active = true
	returning = false
	mission.view.cinematic = true
	destination = camera.global_transform

func frame(kind: String, speaker, listener):
	enter()
	shots_used[mission.dialogue.key+"/"+str(speaker.name)+"/"+kind] = true
	var a = speaker.global_position
	var b = listener.global_position
	var toward = (b-a).normalized()
	if toward.length()<.1: toward=Vector3.FORWARD
	var side = Vector3(toward.z,0,-toward.x)
	var eye = a+Vector3(0,1.48,0)
	var position_value = eye+toward*2.0+side*.3
	var look = eye-Vector3(0,.08,0)
	target_fov = 38
	match kind:
		"two", "wide":
			var middle = (a+b)*.5+Vector3(0,1.0,0)
			position_value = middle+side*3.2+Vector3(0,.55,0)
			look = middle
			target_fov = 44
		"shoulder":
			# toward points from speaker to listener. Continue behind the listener;
			# subtracting it moved the camera between close actors and cropped hats.
			position_value = b+Vector3(0,1.50,0)+toward*.65+side*.85
			look = eye-Vector3(0,.12,0)
			target_fov = 45
		"close":
			position_value = eye+toward*1.28+side*.20+Vector3(0,.04,0)
			target_fov = 33
		"medium":
			position_value = eye+toward*2.25+side*.40
			look = eye-Vector3(0,.30,0)
			target_fov = 40
	if kind=="shoulder":
		position_value=_readable_shoulder(eye,position_value,toward,side)
	else:
		var query = PhysicsRayQueryParameters3D.create(eye,position_value,1)
		var hit_info = mission.get_world_3d().direct_space_state.intersect_ray(query)
		if not hit_info.is_empty(): position_value = hit_info.position.lerp(eye,.18)
	destination = Transform3D(Basis.IDENTITY,position_value).looking_at(look,Vector3.UP)

func _readable_shoulder(eye:Vector3,wanted:Vector3,toward:Vector3,side:Vector3)->Vector3:
	const MINIMUM=1.35
	var reach=maxf((wanted-eye).dot(toward),1.55)
	var candidates=[wanted,eye+toward*reach-side*.85,eye+toward*reach+side*1.05,eye+toward*reach-side*1.35]
	var best=eye
	for candidate_value in candidates:
		var candidate:Vector3=candidate_value
		if eye.distance_to(candidate)<MINIMUM: candidate=eye+(candidate-eye).normalized()*MINIMUM
		var query=PhysicsRayQueryParameters3D.create(eye,candidate,1)
		var hit_info=mission.get_world_3d().direct_space_state.intersect_ray(query)
		if not hit_info.is_empty(): candidate=hit_info.position.lerp(eye,.18)
		if candidate.distance_to(eye)>best.distance_to(eye): best=candidate
		if candidate.distance_to(eye)>=MINIMUM-.001: return candidate
	return best

func landscape(from: Vector3, look: Vector3, fov := 50.0):
	enter()
	target_fov = fov
	destination = Transform3D(Basis.IDENTITY,from).looking_at(look,Vector3.UP)
	shots_used["landscape/"+mission.event] = true

func leave():
	if not active: return
	returning = true
	return_time = 0
	destination = saved
	target_fov = saved_fov

func _process(delta):
	if not active or mission.paused: return
	var camera = mission.view.camera
	var blend = 1.0-exp(-delta*5.5)
	camera.global_transform = camera.global_transform.interpolate_with(destination,blend)
	camera.fov = lerpf(camera.fov,target_fov,blend)
	if returning:
		return_time += delta
		if return_time>.85:
			active = false
			returning = false
			mission.view.cinematic = false
			camera.position = Vector3(.38,.12,4.6)
			camera.rotation = Vector3.ZERO
