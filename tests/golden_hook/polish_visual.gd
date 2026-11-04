extends SceneTree
var g
var folder:String
func _initialize(): call_deferred("run")
func capture(id:String):
	await create_timer(.5).timeout; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join(id+".png")); print("POLISH CAPTURE ",id)
func camera_at(actor,offset:Vector3,focus:Vector3,fov:=42.0):
	g.view.cinematic=true; g.view.camera.global_position=actor.position+offset; g.view.camera.look_at(actor.position+focus); g.view.camera.fov=fov
func run():
	folder=ProjectSettings.globalize_path("res://../Test_Records/Polish/Visual"); DirAccess.make_dir_recursive_absolute(folder)
	g=load("res://game/golden_hook/main.tscn").instantiate(); root.add_child(g); g.store.path="user://golden_hook_polish_visual.json"
	await capture("01_menu")
	g.begin_chapter(true); g.player.locked=true; g.player.position=g.world.at_ground(Vector3(-3,0,0)); g.player.rotation.y=0
	var v=g.player.visual; v.posture="kneel"; v.hold("hook")
	camera_at(g.player,Vector3(.40,.81,.90),Vector3(-.01,.53,.34),37)
	await capture("02_pinch_hook")
	v.hold("bowl")
	camera_at(g.player,Vector3(-.55,1.0,1.0),Vector3(0,.65,.3),40)
	await capture("03_kneeling_bowl")
	v.posture="standing"; camera_at(g.player,Vector3(-.60,1.58,1.05),Vector3(0,1.17,.28),42)
	await capture("04_standing_bowl")
	g.story.step="first_fishing"; g.story.inventory.hook=1; g.player.position=g.world.at_ground(g.world.BANKS[0]); g.fishing.enter(0)
	camera_at(g.player,Vector3(-.6,1.65,1.2),Vector3(0,1.12,.36),38)
	await capture("05_fishing_grip")
	g.fishing.exit(); g.elder.position=g.world.points.secret; g.elder.rotation.y=0; g.elder.visual.posture="seated"; g.elder.visual.hold("scraps")
	camera_at(g.elder,Vector3(-.65,1.45,1.6),Vector3(0,.95,.1),40)
	await capture("06_elder_scraps")
	g.elder.visual.set_emotion("担心，低声",true); g.elder.visual.speech_energy=.6; g.set_process(false)
	camera_at(g.elder,Vector3(-.28,1.25,.85),Vector3(0,1.13,.08),38)
	await capture("07_elder_face")
	g.set_process(true)
	g.elder.visual.reset_pose(); g.elder.position=g.world.points.last_elder; g.elder.visual.posture="collapsed"
	await create_timer(2.6).timeout
	# Arranged shot fixture; the separate complete replay never places actors.
	var head=g._elder_head(); g.player.position=g.world.at_ground(head+Vector3(-.62,0,.45))
	g.player.rotation.y=atan2(head.x-g.player.position.x,head.z-g.player.position.z)
	g.shi.position=g.world.at_ground(head+Vector3(.85,0,-.15)); g.qing.position=g.world.at_ground(g.elder.position+Vector3(-.9,0,-.7))
	g.shi.moving=false; g.qing.moving=false; g.story.step="farewell"; g._farewell_scene()
	await create_timer(2).timeout
	await capture("08_farewell_blocking")
	g.return_to_menu(); g.queue_free(); await process_frame; await process_frame; OS.delay_msec(50); quit()
