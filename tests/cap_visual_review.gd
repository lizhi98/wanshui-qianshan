extends SceneTree
var scene: Node3D
var camera: Camera3D
var visuals: Array=[]
var folder="res://test_evidence/remaster/cap_fix/"
func _initialize(): call_deferred("run")
func capture(label: String):
	await create_timer(.6).timeout
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+label+".png"))
	print("CAP REVIEW ",label)
func run():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	scene=Node3D.new()
	root.add_child(scene)
	current_scene=scene
	var world=WorldEnvironment.new()
	world.environment=Environment.new()
	world.environment.background_mode=Environment.BG_COLOR
	world.environment.background_color=Color("29343a")
	world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color=Color("d5dfeb")
	world.environment.ambient_light_energy=.7
	scene.add_child(world)
	var sun=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-30,-30,0)
	sun.light_energy=1.1
	scene.add_child(sun)
	var fill=DirectionalLight3D.new()
	fill.rotation_degrees=Vector3(-15,140,0)
	fill.light_energy=.4
	scene.add_child(fill)
	camera=Camera3D.new()
	camera.fov=34
	scene.add_child(camera)
	camera.current=true
	for i in 3:
		var actor=Node3D.new()
		actor.name=["Linchuan","Amu","Zhou"][i]
		actor.position.x=(i-1)*.46
		scene.add_child(actor)
		var visual=load("res://game/remaster/character_visual.gd").new()
		actor.add_child(visual)
		visuals.append(visual)
	camera.position=Vector3(0,1.65,1.65)
	camera.look_at(Vector3(0,1.56,0))
	await capture("01_three_front")
	for visual in visuals: visual.get_parent().rotation.y=PI/2
	await capture("02_three_side")
	for i in visuals.size():
		var visual=visuals[i]
		visual.get_parent().rotation.y=0
		visual.set_conversation(i==2,"explain",5)
		visual.look_enabled=true
		visual.look_target=visual.global_position+Vector3(.65,1.5,1)
	await capture("03_turn_and_talk")
	for visual in visuals:
		visual.end_conversation()
		visual.look_enabled=false
		visual.mode="idle"
		visual.speed=4.8
	await capture("04_running_pose")
	camera.position=Vector3(0,1.2,2.75)
	camera.look_at(Vector3(0,1.03,0))
	camera.fov=40
	for i in 3:
		for j in 3:
			visuals[j].set_conversation(j==i,["concerned","talk","explain"][i],i+1)
			visuals[j].look_enabled=true
			visuals[j].look_target=visuals[i].global_position+Vector3(0,1.45,1)
		await create_timer(.6).timeout
		await capture("0%d_%s_speaks"%[i+5,["linchuan","amu","zhou"][i]])
	scene.queue_free()
	await process_frame
	quit()
