extends SceneTree
var g
func _initialize(): call_deferred("run")
func capture(name:String):
	await RenderingServer.frame_post_draw
	var p=ProjectSettings.globalize_path("res://../Test_Records/V1_1/Profiles"); DirAccess.make_dir_recursive_absolute(p)
	root.get_texture().get_image().save_png(p.path_join(name+".png"))
func sample(name:String):
	var times=[]
	for i in 180:
		var began=Time.get_ticks_usec(); await process_frame
		if i>30: times.append((Time.get_ticks_usec()-began)/1000.0)
	times.sort()
	print("FRAME_PROFILE ",name," median_ms=",times[times.size()/2]," p95_ms=",times[int(times.size()*.95)]," fixed_output=",Engine.get_frames_per_second())
func run():
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED);Engine.max_fps=0
	print("PROFILE_DEVICE ",RenderingServer.get_video_adapter_name()," renderer=",RenderingServer.get_current_rendering_method()," vsync=disabled; arranged fixed-camera sample, not a gameplay frame-rate guarantee")
	g=load("res://game/golden_hook/main.tscn").instantiate(); root.add_child(g); g.store.path="user://golden_hook_render_test.json"; g.begin_chapter(true); g.player.locked=true
	await create_timer(.8).timeout
	await capture("720_standard"); await sample("720_standard")
	g.set_performance_mode(true); await create_timer(.3).timeout
	await capture("720_performance"); await sample("720_performance")
	g.set_performance_mode(false); root.size=Vector2i(1920,1080); await create_timer(.7).timeout
	await capture("1080_standard"); await sample("1080_standard")
	g.settings_menu(); await capture("1080_settings")
	print("RENDER PROFILES PASS")
	g.return_to_menu(); g.queue_free(); await process_frame; await process_frame; OS.delay_msec(50); quit()
