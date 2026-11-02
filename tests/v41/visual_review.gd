extends SceneTree
# Explicit visual fixtures. They do not count as the input-driven playthrough.
var game
var samples:Array=[]
func _process(_delta):
	if game:samples.append({"fps":Engine.get_frames_per_second(),"process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000,"physics_ms":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000})
func _initialize():call_deferred("run")
func shot(name:String):
	await process_frame;await process_frame;RenderingServer.force_draw(false);root.get_texture().get_image().save_png("res://test_evidence/v41_fixtures/"+name+".png")
func camera(eye:Vector3,target:Vector3):game.view.cinematic=true;game.view.camera.global_position=eye;game.view.camera.look_at(target)
func run():
	DirAccess.make_dir_recursive_absolute("res://test_evidence/v41_fixtures");game=load("res://game/memorial/main.tscn").instantiate();root.add_child(game);await create_timer(.5).timeout;game.save_store.path="user://v41_visual_fixture.json"
	await shot("01_title");game.begin();game.flags.intro_done=true;game.player.locked=true;game.hud.center_title.text=""
	camera(Vector3(-15,8,52),Vector3(0,1.5,32));await create_timer(1).timeout;await shot("02_camp")
	game.young.visual.set_coat(true);game.player.restore(Vector3(5,.1,36.5));game.player.locked=true;game.player.visual.pose("handover");game.player.visual.mode="idle";game.player.rotation.y=PI;game.parcel.show();game.parcel.position=Vector3(0,1.04,.35);camera(Vector3(2,2.2,37.5),Vector3(5,1.15,35.6));await create_timer(1.8).timeout;await shot("03_parcel_and_coat")
	var p=game.world.route.POINTS[8]
	for i in 6:game.world._footprints().stamp(p+Vector3((.13 if i%2 else -.13),0,-i*.36),Vector3.FORWARD,i%2==0)
	camera(p+Vector3(.35,1.6,1.4),p+Vector3(0,0,-.5));await create_timer(.6).timeout;await shot("04_boot_prints")
	game.stage="DISCOVERY";game.quartermaster.position=game.world.MEMORIAL;game.quartermaster.rotation.y=0;game.quartermaster.pose_name="seated";game.player.restore(game.world.MEMORIAL+Vector3(-1.1,.1,-1.2));game.player.locked=true;game.player.visual.mode="pickup";game.player.visual.pose("inspect");game.flags.inspected=true;game.parcel.hide();game._face(game.player,game.quartermaster.position)
	camera(game.world.MEMORIAL+Vector3(-2.8,1.8,-2.4),game.world.MEMORIAL+Vector3(0,.9,0));await create_timer(1).timeout;await shot("05_check_old_soldier")
	game.stage="SALUTE";game.flags.identity_revealed=true;game.player.visual.mode="idle";game.player.visual.pose("salute");game.zhou.position=game.world.MEMORIAL+Vector3(-1.5,.1,-.4);game.zhou.pose_name="salute";game._face(game.zhou,game.quartermaster.position)
	camera(game.world.MEMORIAL+Vector3(-4,2.6,-3.1),game.world.MEMORIAL+Vector3(0,1,0));await create_timer(3).timeout;await shot("06_salute")
	var f=FileAccess.open("res://test_evidence/v41_fixtures/render_performance.json",FileAccess.WRITE);f.store_string(JSON.stringify({"samples":samples,"mid":24,"far":48,"near":8,"peak_in_camera_frustum":game.crowd.peak_in_frame},"\t"));f.close()
	game.main_menu();game.audio.clear_voice();game.queue_free();await process_frame;quit()
