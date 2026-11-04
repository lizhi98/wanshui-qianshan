extends SceneTree
var errors:=0
func _initialize(): call_deferred("run")
func check(ok:bool,label:String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok: errors+=1
func transfer(g,receiver,done:Array): done.append(await g._handoff(receiver,g.session_epoch))
func run():
	var g=load("res://game/golden_hook/main.tscn").instantiate(); root.add_child(g); g.store.path="user://golden_hook_acting_test.json"; g.begin_chapter(true)
	g.player.locked=true; g.player.visual.posture="standing"; g.player.visual.hold("bowl")
	g.shi.position=g.player.position+Vector3(0,0,1); g.shi.visual.posture="seated"; g.shi.moving=false
	await create_timer(.3).timeout
	var bowl=g.player.visual.held_node; var last=bowl.global_position; var maximum=0.0; var done=[]
	transfer(g,g.shi,done)
	while done.is_empty():
		await process_frame; maximum=maxf(maximum,last.distance_to(bowl.global_position)); last=bowl.global_position
	check(done[0] and g.shi.visual.held_node==bowl,"handoff preserves and transfers the same physical bowl")
	check(maximum<.08,"seated bowl transfer has no sudden 25cm height drop")
	var visual=g.player.visual
	check(visual.has_method("set_emotion"),"chapter actors support restrained expression profiles")
	if visual.has_method("set_emotion"):
		g.set_process(false) # Isolate a known speech envelope from the scene's voice routing.
		visual.set_emotion("担心",true); visual.speech_energy=.7; await create_timer(.2).timeout
		var speaking=false
		for mesh in visual.face_meshes:
			var shape=mesh.find_blend_shape_by_name("Grass_Speech")
			if shape>=0: speaking=mesh.get_blend_shape_value(shape)>.05
		check(speaking,"speech energy opens the actual facial mesh mouth")
		visual.posture="collapsed"; await create_timer(.2).timeout
		var silent=true
		for mesh in visual.face_meshes:
			var shape=mesh.find_blend_shape_by_name("Grass_Speech")
			if shape>=0: silent=silent and mesh.get_blend_shape_value(shape)<.005
		check(silent,"collapsed actors never keep talking because of a stale speech envelope")
		g.elder.visual.posture="collapsed"; g.elder.visual.set_emotion("气息很轻",true); g.elder.visual.speech_energy=.7
		await create_timer(.2).timeout
		var mouth=g.elder.visual.face_meshes[0].find_blend_shape_by_name("Grass_Speech")
		check(g.elder.visual.face_meshes[0].get_blend_shape_value(mouth)>.02,"the living reclined elder can whisper his final words")
		g.story.elder_fate="sacrificed"; await create_timer(.2).timeout
		check(g.elder.visual.face_meshes[0].get_blend_shape_value(mouth)<.005,"after the literary farewell the elder's mouth stays still")
		g.story.elder_fate="alive"
		g.set_process(true)
	visual.reset_pose(); g.play_dialogue("secret")
	var maximum_energy=0.0; var maximum_mouth=0.0
	for i in 40:
		await create_timer(.05).timeout
		maximum_energy=maxf(maximum_energy,g.audio.voice_energy)
		var speech=visual.face_meshes[0].find_blend_shape_by_name("Grass_Speech")
		if speech>=0: maximum_mouth=maxf(maximum_mouth,visual.face_meshes[0].get_blend_shape_value(speech))
	check(maximum_energy>.05 and maximum_mouth>.02,"actual offline voice playback drives the speaking actor's mouth")
	g._cancel_dialogue()
	g.elder.visual.posture="collapsed"; g.elder.position=g.world.points.last_elder
	await create_timer(1.8).timeout
	var head=g._elder_head(); g.player.position=g.world.at_ground(head+Vector3(-.62,0,.3)); g.player.rotation.y=atan2(head.x-g.player.position.x,head.z-g.player.position.z)
	g.player.visual.posture="kneel"; g.player.visual.hold("bowl"); await create_timer(.2).timeout
	var offered=g.player.visual.held_node
	if g.has_method("_offer_bowl"): await g._offer_bowl(g.session_epoch)
	check(offered==g.player.visual.held_node and offered.global_position.distance_to(g._elder_head())<.30,"last soup physically reaches the elder's face in the same bowl")
	g.player.visual.reset_pose(); g.elder.position=g.world.points.last_elder; g.elder.visual.posture="collapsed"
	g.shi.position=g.elder.position+Vector3(.85,0,.3); g.qing.position=g.elder.position+Vector3(-.9,0,-.7)
	g.shi.moving=false; g.qing.moving=false; g.shi.rotation.y=0; g.qing.rotation.y=PI
	g.story.step="farewell"; g._farewell_scene(); await create_timer(1.5).timeout
	for actor in [g.shi,g.qing]:
		var toward=g.elder.position-actor.position; toward.y=0
		check(actor.global_basis.z.dot(toward.normalized())>.8,"farewell companion turns toward the elder: "+str(actor.name))
	check(g.player.visual.posture=="kneel","the player remains beside the elder during his last words")
	g.return_to_menu(); g.queue_free(); await process_frame; await process_frame; OS.delay_msec(50)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://golden_hook_acting_test.json")); quit(1 if errors else 0)
