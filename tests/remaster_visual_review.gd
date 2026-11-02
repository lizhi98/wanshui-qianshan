extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var scene = Node3D.new()
	root.add_child(scene)
	current_scene = scene
	var env = WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("777d79")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("bac4c0")
	env.environment.ambient_light_energy = .5
	scene.add_child(env)
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45,-30,0)
	light.light_energy = 1.2
	light.shadow_enabled = true
	scene.add_child(light)
	var floor_mesh = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(20,20)
	floor_mesh.mesh = plane
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color("646f69")
	floor_mesh.material_override = mat
	scene.add_child(floor_mesh)
	var visual
	for i in 3:
		var actor = Node3D.new()
		actor.name = ["Player","Amu","Zhou"][i]
		scene.add_child(actor)
		actor.position.x = (i-1)*.82
		var v = load("res://game/remaster/character_visual.gd").new()
		actor.add_child(v)
		if i==0: visual=v
	var camera = Camera3D.new()
	scene.add_child(camera)
	camera.position = Vector3(0,1.45,4.1)
	camera.look_at(Vector3(0,1.05,0))
	camera.fov = 40
	await create_timer(1).timeout
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test_evidence/remaster"))
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://test_evidence/remaster/characters_group.png"))
	print("NEW HUMAN: ",visual.rig.scene_file_path," bones ",visual.skeleton.get_bone_count())
	print("HEAD ",visual.skeleton.get_bone_global_pose(visual.skeleton.find_bone("Head")).origin)
	scene.queue_free()
	await process_frame
	quit()
