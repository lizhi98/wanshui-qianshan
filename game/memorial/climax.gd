extends Node
# Physical actors, speech-gated beats and stable, tested camera alternatives.
# Positions are changed only by ordinary NPC routes outside reset/load.
var game
var commander
var guard
var phase:=-1
var beat_clock:=0.0
var reported:=false
var guard_summoned:=false
var marching:=false
var selected_eye:=Vector3.ZERO
var camera_key:=""
var audit:Array=[]
var lines:Array=[]
var music_cut:=false
var speaker_audit:Array=[]
var prepared_speaker:=""
var camera_actor:=""
const BEATS=["衣物","怒问","保障","第一次沉默","再问","迟疑","身份","震惊","回应"]
const MINIMUM=[5.0,5.0,5.0,4.0,5.0,3.0,5.0,7.0,6.0]
func setup(m):
	game=m
	commander=game._actor("CommanderZhou",Vector3(3,.1,47),false)
	guard=game._actor("GuardAmu",Vector3(4,.1,45),false)
	commander.follow_distance=-3;guard.follow_distance=-5
	var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/memorial/climax_voices/manifest.json"))
	for value in manifest.values():
		if value.variant=="B":lines.append(value)
	lines.sort_custom(func(a,b):return a.file<b.file)
func reset():
	phase=-1;beat_clock=0;reported=false;guard_summoned=false;marching=false;music_cut=false;camera_key="";audit=[];speaker_audit=[];prepared_speaker="";camera_actor=""
	for a in [commander,guard]:a.moving=false;a.pose_name="";a.visual.pose("")
	commander.position=Vector3(3,.1,47);guard.position=Vector3(4,.1,45)
func update(delta):
	if not game.started or game.paused or game.failed:return
	if game.flags.get("march_started",false) and not marching:
		marching=true
		for index in 2:
			var a=commander if index==0 else guard
			var path=game._party_path(1,10 if index==0 else 11,index)
			var spot=game.world.MEMORIAL+Vector3(-1.1 if index==0 else 1.3,0,-1.7)
			if index==0:spot=game.world.route.POINTS[10]+Vector3(-.3,0,.3)
			spot.y=game.world.height_at(spot);path.append(spot);a.walk(path,3.0 if index==0 else 3.35)
	if game.stage=="SEARCH" and game.flags.get("strap_found",false) and not guard_summoned:
		guard_summoned=true;guard.pose_name="";guard.visual.pose("")
		guard.walk([game.world.route.POINTS[11],game.world.route.POINTS[12],game.player.position+Vector3(.8,0,0)],3.6)
	if guard_summoned and not reported and guard.position.distance_to(game.player.position)<4.2:
		reported=true;voice(0);voice(1)
		guard.pose_name="";guard.walk([game.world.route.POINTS[12],game.world.route.POINTS[11],game.world.MEMORIAL+Vector3(1.3,0,-1.7)],3.3)
		commander.pose_name="";commander.visual.pose("");commander.walk([game.world.route.POINTS[11],game.world.MEMORIAL+Vector3(-1.1,0,-1.7)],3.0)
	if game.stage in ["DISCOVERY","SALUTE"]:
		for a in [commander,guard]:
			if not a.moving and a.pose_name=="":a.pose_name="witness"
		if not guard.moving and game.action!="salute":
			var toward=(commander.position if game.action=="reveal" and phase<7 else game.quartermaster.position)-guard.position
			guard.request_facing(guard.position+toward)
func salute_tick(delta):
	var people=[commander,guard]+game.actors()
	for i in people.size():
		var a=people[i]
		if a==game.quartermaster:continue
		a.moving=false;a.pose_name="salute";a.visual.pose("salute")
		a.visual.narrative_clock=maxf(0,game.action_clock-.10*float(i))
		var turn=game.quartermaster.position-a.position
		a.request_facing(game.quartermaster.position)
	game._face(game.player,game.quartermaster.position)
	game.player.visual.narrative_clock=game.action_clock
func ready_for_core()->bool:
	return not commander.moving and not guard.moving and commander.position.distance_to(game.world.MEMORIAL)<6
func voice(index:int):
	if index<lines.size():game.say(lines[index].who,lines[index].text)
func start():
	phase=0;beat_clock=0;camera_key="";enter_beat()
func enter_beat():
	audit.append({"phase":BEATS[phase],"time":game.elapsed})
	match phase:
		0:commander.pose_name="concern";voice(2);voice(3)
		1:commander.pose_name="anger";voice(4)
		2:voice(5)
		3:guard.pose_name="hesitate"
		4:commander.pose_name="demand";voice(6)
		5:guard.pose_name="lowered"
		6:
			commander.pose_name="witness";guard.pose_name="identity_reply"
			# Establish the replying face before the first word, while preserving the pause.
			game.audio.voice_wait=maxf(game.audio.voice_wait,.6);voice(7);music_cut=true
		7:commander.pose_name="shock";game.flags.identity_revealed=true
		8:commander.pose_name="lowered";voice(8);voice(9)
func tick(delta):
	beat_clock+=delta;game.action_clock+=delta
	if phase>=6:game.reveal_music_silence+=delta
	var body=game.quartermaster.position
	var face_target=guard.position if phase in [1,2,3,4,5] else body
	var facing=face_target-commander.position;commander.request_facing(face_target)
	var who=str(game.audio.last_voice.get("who","")) if game.audio.voice_busy else prepared_speaker
	var speaker=game.actor_by_name(who) if who!="" else null
	if speaker==guard:
		# A reply belongs to the guard in performance and framing, not just subtitles.
		guard.pose_name="identity_reply" if phase==6 else "report"
		commander.pose_name="witness";commander.request_facing(guard.position)
		frame_speaker(guard,"警卫员",delta)
	elif speaker!=null and speaker!=game.quartermaster:
		guard.pose_name="lowered" if phase>=5 else "hesitate"
		frame_speaker(speaker,who,delta)
	else:
		guard.pose_name="lowered" if phase>=5 else "hesitate"
		_frame_commander(body,delta)
	if beat_clock>=MINIMUM[phase] and not game.audio.voice_busy and game.audio.voice_queue.is_empty() and game.audio.voice_wait<=0:
		if phase==BEATS.size()-1:
			game.action="";game._enter("SALUTE");game.player.locked=true;game._reset_camera();game.save_checkpoint()
		else:phase+=1;beat_clock=0;enter_beat();game.save_checkpoint()
func _frame_commander(body:Vector3,delta:float):
	match phase:
		0:shot("单衣",body+Vector3(0,.55,0),[body+Vector3(2.1,1.0,-.8),body+Vector3(2.5,1.1,.6)],delta)
		2:
			shot("握拳",commander.position+Vector3(-.27,1.1,.32),[commander.position+Vector3(.9,1.3,1.2),commander.position+Vector3(-1.0,1.3,.7)],delta)
		1,3,4,5:
			var focus=commander.position+Vector3.UP*1.34
			shot("追问",focus,[commander.position+Vector3(2,1.65,1.5),commander.position+Vector3(-2,1.65,.8)],delta)
		6:
			# Retain the answering guard through the pause after his line.
			shot("警卫员答话",guard.position+Vector3.UP*1.40,[guard.position+guard.global_basis.z*2.7+guard.global_basis.x*.75+Vector3.UP*1.55],delta)
		7:
			var focus=commander.position+Vector3.UP*1.48
			shot("震惊",focus,[commander.position+Vector3(.8,1.60,.85),commander.position+Vector3(1.05,1.60,-.3)],delta)
		8:shot("衣物与沉默",body+Vector3(0,.65,0),[body+Vector3(2.7,1.3,-.7),body+Vector3(2.7,1.2,.7)],delta)
func on_speaker_started(who:String):
	prepared_speaker=""
	var a=game.actor_by_name(who)
	speaker_audit.append({"who":who,"actor":str(a.name) if a else "","phase":phase,"time":game.elapsed})
	# Only the addressed actor moves his mouth; listeners cannot retain speech.
	for actor in [game.player]+game.actors()+[commander,guard]:actor.visual.voice_active=actor==a
	if game.action=="reveal" and a==commander:
		commander.pose_name="anger" if phase==1 else "demand" if phase in [2,4] else "concern" if phase==0 else "lowered" if phase==8 else "witness"
func prepare_speaker(who:String):prepared_speaker=who
func frame_speaker(actor,who:String,delta:float):
	camera_actor=str(actor.name)
	var front=actor.global_basis.z;var right=actor.global_basis.x
	var candidates:Array=[]
	# A close front arc can stay inside the listening ring, instead of behind a backpack.
	for distance in [1.8,2.4]:
		for angle in [0.0,.55,-.55,1.05,-1.05,1.45,-1.45]:
			candidates.append(actor.position+(front*cos(angle)+right*sin(angle))*distance+Vector3.UP*1.62)
	shot("警卫员答话" if actor==guard else "台词/"+who,actor.position+Vector3.UP*1.43,candidates,delta)
func shot(key:String,focus:Vector3,candidates:Array,delta:float):
	if camera_key!=key:
		camera_key=key;var best=-INF
		for eye in candidates:
			var hit=game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(focus,eye,1))
			var score=100.0 if hit.is_empty() else -100.0
			for a in [game.player]+game.actors()+[commander,guard]:
				if Vector2(a.position.x-focus.x,a.position.z-focus.z).length()<.7:continue
				if Vector2(a.position.x-eye.x,a.position.z-eye.z).length()<.85:score-=500
				for height in [1.0,1.4,1.7]:
					var body=a.position+Vector3.UP*height
					if body.distance_to(Geometry3D.get_closest_point_to_segment(body,eye,focus))<.5:score-=200
			if score>best:best=score;selected_eye=eye
	game._cinematic(focus,selected_eye,delta)
func snapshot()->Dictionary:
	return {"phase":phase,"clock":beat_clock,"reported":reported,"guard_summoned":guard_summoned,"marching":marching,"music_cut":music_cut,"commander":commander.snapshot(),"guard":guard.snapshot(),"audit":audit.duplicate(true)}
func restore(data:Dictionary):
	phase=int(data.get("phase",-1));beat_clock=float(data.get("clock",0));reported=data.get("reported",false);guard_summoned=data.get("guard_summoned",reported);marching=data.get("marching",false);music_cut=data.get("music_cut",false);audit=data.get("audit",[]).duplicate(true);camera_key=""
	if data.has("commander"):commander.restore_snow(data.commander)
	if data.has("guard"):guard.restore_snow(data.guard)
	if music_cut:game.audio.music_gain=0
	if phase>=0 and game.action=="reveal":
		beat_clock=0;enter_beat()

func depart():
	for index in 2:
		var a=commander if index==0 else guard
		a.pose_name="";a.visual.pose("")
		var goal=game.world.route.POINTS[game.END_INDEX]+Vector3(.6 if index==0 else -.6,0,-.5)
		a.walk([game.world.route.POINTS[11],goal],2.7)
