extends SceneTree
class CameraRig extends Node3D:
	var camera:Camera3D
	var cinematic:=false
class ReviewMission extends Node3D:
	var view:CameraRig
	var dialogue={"key":"camera_review"}
	var event=""
	var paused=false
var errors:=0
func _initialize(): call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS: " if ok else "FAIL: ")+label)
	if not ok: errors+=1
func run():
	var scene=ReviewMission.new()
	root.add_child(scene)
	scene.view=CameraRig.new()
	scene.add_child(scene.view)
	scene.view.camera=Camera3D.new()
	scene.view.add_child(scene.view.camera)
	var speaker=Node3D.new(); speaker.name="Speaker"; scene.add_child(speaker)
	var listener=Node3D.new(); listener.name="Listener"; scene.add_child(listener)
	listener.position=Vector3(0,0,1.1)
	var director=load("res://game/remaster/shot_director.gd").new()
	director.mission=scene; scene.add_child(director)
	await physics_frame
	director.frame("shoulder",speaker,listener)
	var eye=speaker.position+Vector3(0,1.48,0)
	check((director.destination.origin-listener.position).dot(Vector3.BACK)>.35,"shoulder camera stays behind the listener")
	check(director.destination.origin.distance_to(eye)>1.25,"close actors retain readable camera clearance")
	scene.view.camera.global_transform=director.destination
	scene.view.camera.fov=director.target_fov
	# Use camera-space projection so the same framing check works with the
	# headless 1x1 display server as well as the real 1280x720 window.
	var hat=scene.view.camera.to_local(Vector3(0,1.81,0))
	var vertical_ndc=hat.y/(-hat.z*tan(deg_to_rad(scene.view.camera.fov*.5)))
	check(vertical_ndc<.93 and vertical_ndc>-.2,"speaker hat remains below the top frame margin")
	var obstacle=StaticBody3D.new()
	var shape=CollisionShape3D.new(); shape.shape=BoxShape3D.new(); shape.shape.size=Vector3(.36,.75,.12)
	obstacle.add_child(shape); scene.add_child(obstacle); obstacle.position=Vector3(.17,1.48,.62)
	await physics_frame
	director.frame("shoulder",speaker,listener)
	check(director.destination.origin.distance_to(eye)>1.25,"nearby obstacle uses a readable alternate shoulder angle")
	scene.queue_free()
	await process_frame
	if "--visual" in OS.get_cmdline_user_args(): await visual_review()
	quit(1 if errors else 0)
func visual_review():
	var game=load("res://game/remaster/main.tscn").instantiate()
	root.add_child(game); current_scene=game
	await create_timer(.7).timeout
	game.save_store.path="user://camera_review_checkpoint.json"
	game.begin(true)
	game.stage="prepare"
	game.player.restore(Vector3(2.69,0,3.31))
	game.amu.position=Vector3(2.9,0,4.0)
	game.amu.moving=false; game.zhou.moving=false
	game.dialogue.start("timber_check")
	await create_timer(.3).timeout
	game.director.frame("shoulder",game.amu,game.player)
	game.hud.set_text_reveal(-1)
	await create_timer(1.3).timeout
	RenderingServer.force_draw(false)
	var folder="res://test_evidence/remaster/camera_fix/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var result=root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+"01_timber_shoulder.png"))
	check(result==OK,"actual timber-check shoulder review captured")
	game.queue_free()
	await process_frame
	await create_timer(.2).timeout
