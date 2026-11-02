extends Node
# Input-only acceptance route. Never writes positions, flags, weather clocks or health.
var game
var failures:=0
var folder:=""
var showcase:=false
var timings:Dictionary={}
var events:Array=[]
var finished:=false
func wait(seconds:float):await get_tree().create_timer(seconds).timeout
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	events.append({"time":game.elapsed,"check":label,"passed":ok})
	if not ok:failures+=1
func release_move():
	for action in ["move_forward","move_back","move_left","move_right","sprint"]:Input.action_release(action)
func press(action:String,seconds:=.12):
	Input.action_press(action);await wait(seconds);Input.action_release(action);await get_tree().process_frame
func until(test:Callable,timeout:float,label:String):
	var clock=0.0
	while not test.call() and clock<timeout and not game.failed:await wait(.06);clock+=.06
	check(test.call() and not game.failed,label)
func shot(label:String):
	if DisplayServer.get_name()=="headless":return
	await get_tree().process_frame;await get_tree().process_frame;RenderingServer.force_draw(false)
	get_tree().root.get_texture().get_image().save_png(folder.path_join(label+".png"))
	if showcase:await wait(1.0)
func aim(point:Vector3):
	var d=point-game.view.global_position
	game.view.camera_rotation=Vector3(rad_to_deg(atan2(d.y,Vector2(d.x,d.z).length())),rad_to_deg(atan2(-d.x,-d.z)),0)
	game.view.camera.rotation=Vector3.ZERO
func observe(id:String):
	if not game.camera_observing:await press("observe")
	var clock=0.0
	while not game.observation.found.has(id) and clock<9:
		aim(game.world.clues[id].get("focus",game.world.clues[id].point+Vector3.UP*.15));await wait(.04);clock+=.04
	check(game.observation.found.has(id),"F gaze identifies physical clue "+id)
	if not game.observation.found.has(id):
		var target=game.world.clues[id].point+Vector3.UP*.15;var camera=game.view.camera;var query=PhysicsRayQueryParameters3D.create(camera.global_position,target,1)
		print("OBS_DIAG ",id," observing=",game.camera_observing," target=",target," eye=",camera.global_position," dot=",(-camera.global_basis.z).dot((target-camera.global_position).normalized())," dwell=",game.observation.dwell," ray=",game.get_world_3d().direct_space_state.intersect_ray(query))
	await press("observe")
func go(point:Vector3,timeout:=30.0,sprint:=false,stop_when:Callable=Callable()):
	var clock=0.0
	var difference=point-game.player.position
	game.view.camera_rotation=Vector3(-11,rad_to_deg(atan2(-difference.x,-difference.z)),0)
	while clock<timeout and not game.failed:
		difference=point-game.player.position;difference.y=0
		if difference.length()<.34 or (stop_when.is_valid() and stop_when.call()):break
		release_move()
		# Counter steer with ordinary movement axes; the world wind remains active.
		var desired=difference.normalized()*minf(2.6,difference.length()*3)
		if game.weather:desired-=game.weather.force_at(game.player.position)*.9
		var local=desired.rotated(Vector3.UP,-game.view.rotation.y)/2.6
		if absf(local.x)>.025:Input.action_press("move_right" if local.x>0 else "move_left",clampf(absf(local.x),0,1))
		if absf(local.z)>.025:Input.action_press("move_back" if local.z>0 else "move_forward",clampf(absf(local.z),0,1))
		if sprint:Input.action_press("sprint")
		await wait(.04);clock+=.04
	release_move();await wait(.12)
	var reached=Vector2(point.x-game.player.position.x,point.z-game.player.position.z).length()<.75 or (stop_when.is_valid() and stop_when.call())
	check(reached and not game.failed,"walk to "+str(point))
	print("SNOW_AT ",game.player.position," phase=",game.stage," party=",game.amu.position," ",game.amu.route_index,"/",game.amu.route.size())
	if point==game.world.route.POINTS[11] or point==game.world.route.POINTS[19]:
		for a in game.actors():print("PARTY_DIAG ",a.name," ",a.position," moving=",a.moving," route=",a.route_index,"/",a.route.size()," jumps=",a.jumps)
func jump_at(center:float):
	var route=game.world.route
	var safe=route.at(center-3.5)
	await go(safe,15)
	# Wait back from the lip and counter-steer using normal axes, just as a player must.
	var clock=0.0
	while game.weather.gust>.22 and clock<14 and not game.failed:
		var delta=safe-game.player.position;delta.y=0
		var desired=delta*3-game.weather.force_at(game.player.position)/maxf(.5,1-game.weather.exposure*.22)
		var local=desired.rotated(Vector3.UP,-game.view.rotation.y)/2.57
		release_move()
		if absf(local.x)>.01:Input.action_press("move_right" if local.x>0 else "move_left",clampf(absf(local.x),0,1))
		if absf(local.z)>.01:Input.action_press("move_back" if local.z>0 else "move_forward",clampf(absf(local.z),0,1))
		await wait(.04);clock+=.04
	release_move()
	check(not game.failed and game.weather.gust<.23,"wait back from the lip and counter-steer until the wind eases")
	if game.failed:return
	await go(route.at(center-1.05),15)
	var tangent=route.nearest(route.at(center)).tangent
	game.view.camera_rotation=Vector3(-10,rad_to_deg(atan2(-tangent.x,-tangent.z)),0);await wait(.35)
	Input.action_press("sprint");Input.action_press("move_forward");await wait(.10);await press("jump",.13);await wait(.50);release_move();await wait(.22)
	check(not game.failed and route.nearest(game.player.position).s>center+.6 and game.player.is_on_floor(),"real jump crosses the rock cleft")
	print("JUMP_DIAG pos=",game.player.position," s=",route.nearest(game.player.position).s," center=",center," on_floor=",game.player.is_on_floor()," jumps=",game.stats.jumps)
func run(existing):
	game=existing;showcase="--showcase" in OS.get_cmdline_user_args();folder=ProjectSettings.globalize_path("user://verification/snow_v4")
	DirAccess.make_dir_recursive_absolute(folder);game.save_store.path="user://snow_input_replay_v4.json"
	for action in InputMap.get_actions():InputMap.action_erase_events(action)
	game.view.set_process_input(false)
	await wait(.6);await shot("01_title")
	for button in game.hud.buttons.get_children():
		if button.text=="开始 · 雪线之上":button.pressed.emit();break
	await until(func():return game.stage=="ROUTE_FINDING",26,"route map and opening dialogue release the player")
	await shot("02_foothill")
	var route=game.world.route
	await go(route.POINTS[1]);await go(route.POINTS[2]);await observe("false_route");await go(route.POINTS[3]);await observe("route")
	await go(game.world.clues.route.point);check(game.flags.get("route_confirmed",false),"observed route requires walking to its actual location")
	var before=game.amu.position;await press("signal");await wait(1.5)
	check(game.stage=="BLIZZARD" and game.amu.position.distance_to(before)>.8,"Q makes the waiting team advance along the mountain trail")
	timings.route_finding=game.elapsed;await shot("03_route_confirmed")
	for i in range(4,11):
		await go(route.POINTS[i],35)
		if failures:await finish();return
		if i in [7,8,9]:
			check(game.weather.sheltered,"rock shelter reduces exposure "+str(i));await shot("04_shelter_%d"%i)
			await until(func():return game.weather.gust<.30,14,"observe wind easing before leaving shelter")
	await go(route.POINTS[11]);check(game.stage=="SLOPE_COLLAPSE","physical ascent reaches the unstable slope")
	timings.blizzard=game.elapsed;await shot("05_before_slide")
	await go(route.POINTS[12],12,false,func():return game.flags.get("collapse_triggered",false))
	check(game.flags.get("collapse_triggered",false),"entering the actual slope triggers the slide")
	await go(route.POINTS[13],8,true);check(game.flags.get("collapse_evaded",false),"player actively escapes toward the rock wall")
	await wait(2.5);await shot("06_slide_and_detour")
	check(game.world.collapse_blocker.collision_layer==1,"fallen snow and rock physically block the original road")
	for i in range(14,18):await go(route.POINTS[i],25)
	if failures:await finish();return
	check(game.stage=="REUNION" and game.flags.get("detour_used",false),"the replacement route is walked instead of teleporting past the event")
	timings.collapse=game.elapsed
	await go(Vector3(-20,64,-241.3),12);await observe("ridge_false");await go(route.POINTS[17],12);await go(route.POINTS[18]);await observe("ridge");await go(route.POINTS[19]);aim(game.amu.position+Vector3.UP*1.3);await wait(.8);await shot("07_team_below")
	check(game.flags.get("overlook",false),"the overlook has a real camera line of sight to the team below")
	var old=game.amu.position;await press("signal");await wait(1.5)
	check(game.stage=="SUMMIT" and game.amu.position.distance_to(old)>.8,"second Q restores contact and visibly moves the distant team")
	if failures:await finish();return
	timings.reunion=game.elapsed
	await go(route.POINTS[20],30);await go(route.POINTS[21],30);await jump_at(game.world.jump_centers[0]);await go(route.POINTS[22],30);await go(route.POINTS[23],30)
	if failures:await finish();return
	var step=route.lengths[23]+5
	await go(route.at(step-.9),12)
	var tangent=route.nearest(route.at(step)).tangent;game.view.camera_rotation=Vector3(-10,rad_to_deg(atan2(-tangent.x,-tangent.z)),0);await wait(.35)
	Input.action_press("move_forward");Input.action_press("sprint");await press("jump");await wait(.4);release_move();await wait(.2)
	await go(route.POINTS[24],30);await jump_at(game.world.jump_centers[1]);await go(route.POINTS[25],30);await go(route.POINTS[26],30);await go(route.POINTS[27],30,false,func():return game.flags.get("at_pass",false))
	if failures:await finish();return
	await shot("08_at_pass")
	await until(func():return game.outro_active,100,"all four companions physically reach the pass")
	timings.summit=game.elapsed;await shot("09_team_gathered")
	# Fixed-FPS headless simulation can run much faster than its real-time audio driver.
	var ending_timeout=600.0 if DisplayServer.get_name()=="headless" and Engine.get_write_movie_path().is_empty() else 45.0
	await until(func():return game.stage=="COMPLETE",ending_timeout,"the pullback ending reaches the actual second-chapter settlement")
	check(game.flags.get("complete",false) and game._gathered(),"settlement is based on genuine route and NPC completion")
	check(game.stats.signals==2 and game.stats.clues>=4 and game.stats.jumps>=3,"statistics derive from the recorded actions")
	await shot("10_complete");timings.complete=game.elapsed;await finish()
func finish():
	if finished:return
	finished=true;release_move()
	for action in ["jump","observe","signal"]:Input.action_release(action)
	var people=[]
	for actor in game.actors():people.append({"name":str(actor.name),"position":str(actor.position),"moving":actor.moving,"route_index":actor.route_index,"jumps":actor.jumps})
	var report={"failures":failures,"input_replay":true,"chapter":"snow","stage":game.stage,"elapsed_seconds":game.elapsed,"timings":timings,"stats":game.stats,"flags":game.flags,"party":people,"shelters":game.weather.shelter_visits,"binary":OS.get_executable_path(),"movie_maker":not Engine.get_write_movie_path().is_empty(),"viewport":str(get_tree().root.size),"checks":events}
	var file=FileAccess.open(folder.path_join("report.json"),FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	print("SNOW_REPLAY failures=",failures," stage=",game.stage," elapsed=",game.elapsed," party=",people)
	game.audio.clear_voice();game.spatial_voice.stop();game.collapse_sound.stop()
	for audio in game.find_children("*","AudioStreamPlayer",true,false):audio.stop();audio.stream=null
	game.queue_free();await get_tree().process_frame;await wait(.4);get_tree().quit(1 if failures else 0)
