extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var scene=Node3D.new()
	root.add_child(scene)
	current_scene=scene
	var document=GLTFDocument.new()
	var state=GLTFState.new()
	var error=document.append_from_file(ProjectSettings.globalize_path("res://test_evidence/remaster/candidate_head.glb"),state)
	if error!=OK:
		quit(1)
		return
	var model=document.generate_scene(state)
	scene.add_child(model)
	var bounds=AABB()
	var first=true
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		var rect=mesh.global_transform*mesh.get_aabb()
		bounds=rect if first else bounds.merge(rect)
		first=false
		var mat=StandardMaterial3D.new()
		mat.albedo_color=Color("b2a99d")
		mat.roughness=.7
		mesh.material_override=mat
	model.position=-(bounds.position+bounds.size*.5)
	var camera=Camera3D.new()
	scene.add_child(camera)
	camera.position=Vector3(0,0,maxf(bounds.size.length()*1.8,.7))
	camera.look_at(Vector3.ZERO)
	camera.fov=35
	var env=WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color("344341")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("c4d3cf")
	env.environment.ambient_light_energy=.5
	scene.add_child(env)
	var light=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-35,-25,0)
	light.light_energy=1.1
	scene.add_child(light)
	await create_timer(.8).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://test_evidence/remaster/candidate_static_head.png"))
	print("CANDIDATE IMPORT: ",model.find_children("*","Skeleton3D",true,false).size()," skeletons, ",model.find_children("*","AnimationPlayer",true,false).size()," animation players. Static-only candidate rejected as turnkey character.")
	scene.queue_free()
	await process_frame
	await create_timer(.15).timeout
	quit()
