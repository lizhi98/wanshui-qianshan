extends "res://game/snow/audio.gd"
var music_silent:=false
var music_gain:=0.0
var cue_history:Array=[]
var subtitle_audit:Array=[]
var completed_voice:Array=[]
var step_players:Array=[]
var step_streams:Array=[]
var step_serial:=0
var footstep_audit:Array=[]
var pending_steps:Array=[]
var last_step_side:=""
func _ready():
	super._ready()
	process_priority=20
	for i in 4:
		step_streams.append(load("res://assets/memorial/snow_foley/step_%02d.wav"%(i+1)))
		var p=AudioStreamPlayer.new();add_child(p);step_players.append(p)
	var path="res://assets/memorial/voices/manifest.json"
	if FileAccess.file_exists(path):voice_manifest.merge(JSON.parse_string(FileAccess.get_file_as_string(path)),true)
	var climax=JSON.parse_string(FileAccess.get_file_as_string("res://assets/memorial/climax_voices/manifest.json"))
	for key in climax:
		if climax[key].variant=="B":voice_manifest[key]=climax[key]
func track_for_mission()->String:
	return {"CAMP":"m_camp","MARCH":"m_march","STORM":"m_storm","SEARCH":"m_search","DISCOVERY":"m_memorial","SALUTE":"m_memorial","CONTINUE":"m_continue","COMPLETE":"m_continue"}.get(mission.stage,"m_camp")
func _process(delta):
	for p in step_players:p.stream_paused=mission.paused
	_flush_snow_steps()
	voice.stream_paused=mission.paused
	if not mission.paused:
		if not voice_busy and not voice_queue.is_empty() and mission.director and mission.action=="reveal":mission.director.prepare_speaker(voice_queue[0].who)
		voice_wait=maxf(0,voice_wait-delta)
		if not voice_busy and voice_wait<=0 and not voice_queue.is_empty():_next_voice()
	var wanted=track_for_mission()
	if wanted!=current_track:
		current_track=wanted;target_player=1-target_player;crossfade=0;cue_history.append({"cue":wanted,"time":mission.elapsed})
		var path="res://assets/memorial/audio/"+wanted+".wav"
		if ResourceLoader.exists(path):players[target_player].stream=load(path);players[target_player].play()
	if mission.paused:return
	crossfade=minf(1,crossfade+delta/3)
	var approach=mission.stage=="DISCOVERY" and mission.player.position.distance_to(mission.quartermaster.position)<18
	music_silent=(approach and mission.action!="reveal") or (mission.action=="reveal" and mission.director.music_cut) or (mission.stage=="SALUTE" and mission.action_clock<1)
	var gain=0.0 if music_silent else .22*music_volume*(.33 if voice.playing else 1.0)
	music_gain=move_toward(music_gain,gain,delta*.06)
	players[target_player].volume_db=linear_to_db(maxf(.00001,music_gain*crossfade));players[1-target_player].volume_db=linear_to_db(maxf(.00001,music_gain*(1-crossfade)))
	wind.volume_db=-32+mission.weather.strength*7+mission.weather.gust*5
	if voice.playing:wind.volume_db-=4
	if mission.stage in ["SEARCH","DISCOVERY","SALUTE"]:wind.volume_db-=4
	wind.volume_db+=linear_to_db(maxf(.0001,effect_volume))
func _next_voice():
	while not voice_queue.is_empty() and _deceased_speaker(voice_queue[0].who):voice_queue.pop_front()
	if voice_queue.is_empty():return
	super._next_voice()
	if not last_voice.is_empty():
		if mission.director:mission.director.on_speaker_started(last_voice.who)
		if voice.stream:mission.hud.bark_time=voice.stream.get_length()+1.1
		voice.volume_db=float(voice_manifest.get(last_voice.key,{}).get("volume_db",-1))
		subtitle_audit.append({"key":last_voice.key,"who":last_voice.who,"text":last_voice.text,"time":mission.elapsed,"volume_db":voice.volume_db,"has_voice":voice_busy})
func _voice_finished():
	if not last_voice.is_empty():completed_voice.append(last_voice.key)
	super._voice_finished()
	if not last_voice.is_empty():voice_wait=float(voice_manifest.get(last_voice.key,{}).get("pause_after",.7))
func play_snow_footstep(actor,event:Dictionary):
	if actor!=mission.player or mission.paused or actor.locked or not actor.is_on_floor():return
	if Vector2(actor.velocity.x,actor.velocity.z).length()<.45:return
	pending_steps.append({"actor":actor,"event":event.duplicate(),"frame":Engine.get_process_frames()})
func _flush_snow_steps():
	if mission.player and (Vector2(mission.player.velocity.x,mission.player.velocity.z).length()<.45 or not mission.player.is_on_floor() or mission.player.locked):last_step_side=""
	var waiting:Array=[]
	for row in pending_steps:
		var actor=row.actor;var event=row.event
		if mission.paused or actor.locked or not actor.is_on_floor() or Vector2(actor.velocity.x,actor.velocity.z).length()<.45:continue
		if Engine.get_process_frames()-row.frame>3:continue
		var sk=actor.visual.skeleton;var foot=sk.to_global(sk.get_bone_global_pose(sk.find_bone("foot_"+event.side)).origin)
		var hit=actor.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(foot+Vector3.UP*.6,foot-Vector3.UP*.8,1))
		if hit.is_empty():continue
		var gap=absf(foot.y-hit.position.y-actor.visual.sole_offset(event.side))
		if gap>.022:waiting.append(row);continue
		_start_snow_step(event,gap,Engine.get_process_frames()-row.frame)
	pending_steps=waiting
func _start_snow_step(event:Dictionary,gap:float,delay_frames:int):
	# A stopped/transitioning planted foot may be reported again; it is not a new step.
	if event.side==last_step_side:return
	last_step_side=event.side
	var index=(step_serial*3+int(step_serial/4))%4;var p=step_players[step_serial%4]
	p.stream=step_streams[index];p.pitch_scale=1.0
	p.volume_db=-4.0+linear_to_db(maxf(.0001,effect_volume))-(4.0 if voice.playing else 0.0);p.play();step_serial+=1
	footstep_audit.append({"time":mission.elapsed,"side":event.side,"file":index+1,"position":str(event.point),"sole_gap":gap,"delay_frames":delay_frames})
	if footstep_audit.size()>1200:footstep_audit.pop_front()
func _deceased_speaker(who:String)->bool:
	return who=="老战士" and mission.quartermaster and mission.quartermaster.pose_name=="seated"
func enqueue_voice(who:String,line:String):
	if _deceased_speaker(who):return
	if mission.action=="reveal" and not voice_busy and voice_queue.is_empty():voice_wait=maxf(voice_wait,.6)
	super.enqueue_voice(who,line)
func _set_speaker(who:String,value:bool):
	if _deceased_speaker(who):value=false
	super._set_speaker(who,value)
