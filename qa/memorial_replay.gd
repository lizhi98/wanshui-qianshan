extends "res://qa/snow_replay.gd"
# Full six-act acceptance: ordinary controls only; no player/NPC teleports or flags.
var stall_clock:Dictionary={}
var speech_starts:Dictionary={}
var speech_frames:Array=[]
func _process(_delta):
	if not is_instance_valid(game) or game.action!="reveal" or not game.audio.voice_busy:return
	var line=game.audio.last_voice;var key=str(line.get("key",""))
	if not speech_starts.has(key):speech_starts[key]=game.elapsed;return
	if game.elapsed-float(speech_starts[key])<.6:return
	if speech_frames.any(func(x):return x.key==key):return
	var a=game.actor_by_name(line.who);var active=[]
	for person in [game.player]+game.actors()+[game.director.commander,game.director.guard]:
		if person.visual.voice_active:active.append(str(person.name))
	check(a!=null and active==[str(a.name)],"actual dialogue has exactly its named speaker: "+str(line.who))
	check(a!=null and game.director.camera_actor==str(a.name),"actual dialogue camera frames named speaker: "+str(line.who))
	var eye=game.view.camera.global_position;var focus=a.position+Vector3.UP*1.43;var clearance=1000.0
	for person in [game.player]+game.actors()+[game.director.commander,game.director.guard]:
		if person==a:continue
		for height in [1.0,1.4,1.7]:
			var body=person.position+Vector3.UP*height
			clearance=minf(clearance,body.distance_to(Geometry3D.get_closest_point_to_segment(body,eye,focus)))
	check(clearance>.4,"actual speaking camera clears listeners including the player: "+str(line.who))
	check(not game.quartermaster.visual.voice_active,"deceased quartermaster remains silent during the reply")
	speech_frames.append({"key":key,"who":line.who,"actor":str(a.name),"camera_actor":game.director.camera_actor,"active_mouths":active,"time":game.elapsed,"phase":game.director.phase})
	if line.who=="警卫员" and game.director.phase==6:call_deferred("shot","09c_actual_guard_identity")
func _physics_process(delta):
	if not is_instance_valid(game) or not game.built:return
	for a in game.actors():
		var id=str(a.name);var t=float(stall_clock.get(id,0))
		t=t+delta if a.moving and a.desired_speed>.5 and a.actual_speed<.03 else 0.0
		if t>2:
			t=0;print("REPLAY_STALL ",game.elapsed," ",id," p=",a.position," v=",a.velocity," command=",a.horizontal_velocity," safe=",a.safe_velocity," goal=",a.route[a.route_index]," origin=",a.path_origin," target=",a.avoidance.target_position)
			for i in a.get_slide_collision_count():
				var c=a.get_slide_collision(i);print("REPLAY_BLOCK ",c.get_normal()," point=",c.get_position()," collider=",c.get_collider().get_parent().name)
		stall_clock[id]=t
func action_done(timeout:=25.0):await until(func():return game.action=="",timeout,"narrative action finishes and returns control")
func press(action_name:String,seconds:=.12):
	Input.action_press(action_name);await wait(seconds);Input.action_release(action_name)
	# process_frame is emitted before gameplay _process. Leave actual released
	# frames between consecutive F presses so the input edge can be observed.
	await wait(.08)
func aim(point:Vector3):
	var d=point-game.view.camera.global_position
	game.view.camera_rotation=Vector3(rad_to_deg(atan2(d.y,Vector2(d.x,d.z).length())),rad_to_deg(atan2(-d.x,-d.z)),0)
	game.view.camera.rotation=Vector3.ZERO
func observe(id:String):
	if not game.observation.found.has(id):
		if not game.camera_observing:await press("observe")
		var t=0.0
		while not game.observation.found.has(id) and t<10:
			aim(game.world.clues[id].point);await wait(.04);t+=.04
	check(game.observation.found.has(id),"F gaze identifies physical clue "+id)
	if not game.observation.found.has(id):print("MEM_FOCUS_DIAG ",id," active=",game.camera_observing," eye=",game.view.camera.global_position," target=",game.world.clues[id].point," found=",game.observation.found," dwell=",game.observation.dwell)
	if game.camera_observing:await press("observe")
func take_parcel():
	await go(game.world.CRATE+Vector3(0,0,1.8),15);await press("interact");await action_done(5)
	check(game.player.carrying and game.parcel.visible,"E picks up a visible parcel into the character's hands")
func give_to(actor,id:String):
	await go(actor.position+Vector3(0,0,1.65),20);await press("interact");await wait(2);await shot("give_"+id);await action_done(8)
	check(game.flags.get("gave_"+id,false),"actual handover commits for "+id)
	if id!="giver":check(actor.visual.coat_received,"recipient visibly wears the delivered coat: "+id)
func run(existing):
	game=existing;folder=ProjectSettings.globalize_path("user://verification/memorial_v413");DirAccess.make_dir_recursive_absolute(folder);showcase="--showcase" in OS.get_cmdline_user_args();game.save_store.path="user://memorial_input_replay_v413.json"
	for a in InputMap.get_actions():InputMap.action_erase_events(a)
	game.view.set_process_input(false);await wait(.6);await shot("01_title")
	for button in game.hud.buttons.get_children():
		if button.text=="开始 · 丰碑·雪线之上":button.pressed.emit();break
	await until(func():return game.flags.get("intro_done",false),15,"camp panorama releases normal third-person control")
	await shot("02_camp_column");await go(game.world.CRATE+Vector3(0,0,1.8),15);await observe("stock")
	await take_parcel();await give_to(game.young,"young");await take_parcel();await give_to(game.veteran,"veteran");await take_parcel();await give_to(game.giver,"giver")
	check(game.player.carrying,"the already clothed soldier redirects his parcel instead of consuming it")
	await give_to(game.amu,"amu");check(game.stock==0 and game.stats.delivered==3,"three physical parcels produce exactly three real deliveries")
	await go(game.quartermaster.position+Vector3(0,0,1.65),15);await shot("03_familiar_old_soldier");await press("interact");await action_done(25)
	check(game.stage=="MARCH" and not game.flags.get("identity_revealed",false),"march begins without revealing the old soldier's identity")
	timings.camp=game.elapsed
	if failures:await finish();return
	var route=game.world.route
	await go(route.POINTS[0]);await go(route.POINTS[1]);await go(route.POINTS[2]);await go(route.POINTS[3])
	await go(route.at(route.lengths[4]-6),20);await press("interact");await action_done(10)
	check(game.flags.get("obstacle_cleared",false) and game.world.obstacle_cleared,"player clears the actual obstruction and lets the column advance")
	for i in range(4,7):await go(route.POINTS[i],35)
	check(game.stage=="STORM","climbing changes the scene into the storm act");timings.march=game.elapsed
	await shot("04_column_in_depth");await go(route.POINTS[7],35);check(game.weather.sheltered,"the rock shelter changes physical wind exposure")
	await until(func():return game.weather.gust<.3,14,"wait for a real lull behind the rock")
	await go(route.POINTS[8],35);await observe("wind_mark");await go(route.POINTS[9],35)
	var before=game.amu.position;await press("signal");await wait(1.5)
	check(game.flags.get("storm_signal",false) and game.amu.position.distance_to(before)>.5,"Q releases the waiting rear squad after the safe route is checked")
	check(game.flags.get("warm_callback",false) and game.young.visual.coat_received,"the delivered coat returns in the storm dialogue")
	await shot("05_wind_and_coat");timings.storm=game.elapsed
	for i in range(10,16):
		await go(route.POINTS[i],35,false,func():return game.action=="count")
		if game.action=="count":break
	await until(func():return game.stage=="SEARCH",22,"a physical regroup and headcount starts the search")
	timings.search=game.elapsed;await shot("06_headcount")
	for i in [14,13]:await go(route.POINTS[i],25)
	await observe("strap");check(game.flags.get("strap_found",false),"the search recognizes the familiar satchel strap")
	await go(route.POINTS[12],20);await go(game.world.MEMORIAL+Vector3(0,0,-1.7),25)
	check(game.stage=="DISCOVERY" and game.quartermaster.pose_name=="seated","the same old soldier is found sitting at the sheltered rock")
	await shot("07_seated_silhouette");await press("interact");await wait(3);await shot("08_kneel_and_check");await action_done(10)
	check(game.flags.get("inspected",false),"E performs a real kneeling check before further investigation")
	await observe("coat");await observe("ledger");await until(func():return game.action=="reveal",180 if DisplayServer.get_name()=="headless" and Engine.get_write_movie_path().is_empty() else 120,"commander, guard and witnesses physically arrive before the identity reveal")
	check(game.director.reported and game.director.guard_summoned,"the guard reports after physically reaching the searching player")
	await until(func():return game.director.phase==1,60,"the commander discovers the thin clothing before the angry order");await wait(1.5);await shot("09a_angry_order")
	await until(func():return game.director.phase==2,30,"the concern about supplies follows the first order");await wait(1.5);await shot("09b_clenched_hand")
	await until(func():return game.director.phase>=7,200,"the commander passes through anger, unanswered orders and the identity shock")
	check(game.audio.music_silent and game.audio.music_gain<.002,"the identity reveal leaves music silent while ambience remains")
	await shot("09_truth_and_silence");await until(func():return game.stage=="SALUTE",60,"truth is revealed before the salute prompt")
	timings.reveal=game.elapsed;await press("interact");await wait(4.5);await shot("10_salute")
	for a in [game.player,game.director.commander,game.director.guard]+game.actors():
		if a==game.quartermaster:continue
		var v=a.visual;var s=v.skeleton
		var hand=v.to_local(s.to_global(s.get_bone_global_pose(s.find_bone("hand_r")).origin))
		check(hand.y>1.30,"evaluated salute raises the right hand: "+str(a.name))
	check(game.player.visual.narrative_pose=="salute" and game.zhou.pose_name=="salute","player and companions perform the salute together")
	await action_done(10);check(game.stage=="CONTINUE" and game.flags.get("honored",false),"one unscored salute returns the player to the marching column")
	timings.salute=game.elapsed
	if failures:await finish();return
	await go(route.POINTS[11],20)
	for i in range(12,game.END_INDEX+1):await go(route.POINTS[i],35,false,func():return game.flags.get("at_pass",false))
	await until(func():return game.outro_active,70,"all surviving near companions reach the final pass by walking")
	await shot("11_continuing_column")
	await until(func():return game.outro_clock>19,25,"the original literary creation credit is displayed");await shot("11a_creation_credit")
	await until(func():return game.outro_clock>29,15,"the requested dedication is displayed");await shot("11b_dedication")
	await until(func():return game.stage=="COMPLETE",15,"the memorial ending reaches its literary and historical credits")
	check(game.flags.get("complete",false) and game.quartermaster.pose_name=="seated","the ending preserves the person left on the mountain")
	check(game.young.visual.coat_received and game.amu.visual.coat_received,"the coats remain visible on the people who continue")
	check(game.crowd.mid_count==24 and game.crowd.far_count==48 and game.crowd.peak_in_frame>15,"tiered column has measurable scale in actual camera views")
	await shot("12_complete");timings.complete=game.elapsed;await finish()
func finish():
	if finished:return
	finished=true;release_move()
	for a in ["interact","observe","signal","jump"]:Input.action_release(a)
	var people=[]
	for a in game.actors():people.append({"name":str(a.name),"position":str(a.position),"pose":a.pose_name,"moving":a.moving,"coat":a.visual.coat_received})
	var report={"chapter":"memorial","input_replay":true,"failures":failures,"stage":game.stage,"elapsed_seconds":game.elapsed,"timings":timings,"stats":game.stats,"flags":game.flags,"party":people,"crowd":{"near":8,"mid":24,"far":48,"peak_in_camera_frustum":game.crowd.peak_in_frame},"reveal_music_silence_seconds":game.reveal_music_silence,"music_cues":game.audio.cue_history,"footprints":game.world._footprints().emitted,"binary":OS.get_executable_path(),"movie_maker":not Engine.get_write_movie_path().is_empty(),"checks":events}
	report.pacing={"quiet_walk_total":game.quiet_walk_total,"quiet_walk_peak":game.quiet_walk_peak};report.climax=game.director.snapshot();report.subtitle_audit=game.audio.subtitle_audit;report.completed_voice=game.audio.completed_voice
	report.navigation_replans={}
	report.speech_frames=speech_frames
	report.footstep_audio=game.audio.footstep_audit
	for a in game.actors()+[game.director.commander,game.director.guard]:report.navigation_replans[str(a.name)]=a.replan_history
	var file=FileAccess.open(folder.path_join("report.json"),FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	print("MEMORIAL_REPLAY failures=",failures," stage=",game.stage," elapsed=",game.elapsed," party=",people)
	game.main_menu();game.audio.clear_voice();game.queue_free();await get_tree().process_frame;await wait(.3);get_tree().quit(1 if failures else 0)

func go(point:Vector3,timeout:=30.0,sprint:=false,stop_when:Callable=Callable()):
	var clock=0.0
	var difference=point-game.player.position
	game.view.camera_rotation=Vector3(-11,rad_to_deg(atan2(-difference.x,-difference.z)),0)
	while clock<timeout and not game.failed:
		difference=point-game.player.position;difference.y=0
		if difference.length()<.34 or (stop_when.is_valid() and stop_when.call()):break
		release_move()
		# Counter steer with ordinary movement axes; the world wind remains active.
		var desired=difference.normalized()*minf(game.player.walk_speed,difference.length()*3)
		if game.weather:desired-=game.weather.force_at(game.player.position)*.9
		var local=desired.rotated(Vector3.UP,-game.view.rotation.y)/game.player.walk_speed
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
