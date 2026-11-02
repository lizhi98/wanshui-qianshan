extends Node
var mission
var music_volume := .65
var effect_volume := .8
var players: Array[AudioStreamPlayer]=[]
var current_track := ""
var target_player := 0
var crossfade := 1.0
var wind: AudioStreamPlayer
var chain_clock := 0.0
var voice:AudioStreamPlayer
var voice_manifest:Dictionary={}
var voice_queue:Array[Dictionary]=[]
var last_voice:Dictionary={}
var voice_wait:=0.0
var voice_busy:=false
var recent:Dictionary={}
func _ready():
	voice=AudioStreamPlayer.new(); voice.name="ChineseDialogue"; add_child(voice)
	voice.finished.connect(_voice_finished)
	var path="res://assets/voices/manifest.json"
	if FileAccess.file_exists(path):
		var parsed=JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary: voice_manifest=parsed
	for i in 2:
		var player=AudioStreamPlayer.new()
		add_child(player)
		players.append(player)
		player.volume_db=-60
		player.finished.connect(player.play)
	wind=AudioStreamPlayer.new()
	wind.stream=load("res://assets/remaster/audio/wind.wav")
	wind.volume_db=-26
	add_child(wind)
	wind.finished.connect(wind.play)
	wind.play()
func _process(delta):
	voice.stream_paused=mission.paused
	if not mission.paused:
		voice_wait=maxf(0,voice_wait-delta)
		if not voice_busy and voice_wait<=0 and not voice_queue.is_empty(): _next_voice()
	var duck=.48 if voice.playing else 1.0
	var wanted=track_for_mission()
	if wanted!=current_track:
		current_track=wanted
		target_player=1-target_player
		players[target_player].stream=load("res://assets/remaster/audio/"+wanted+".wav")
		players[target_player].play()
		crossfade=0
	crossfade=minf(1,crossfade+delta/2.5)
	var strength=.55 if wanted in ["assault","chain_battle"] else .30
	players[target_player].volume_db=linear_to_db(maxf(.0001,crossfade*music_volume*strength*duck))
	players[1-target_player].volume_db=linear_to_db(maxf(.0001,(1-crossfade)*music_volume*strength*duck))
	wind.volume_db=-21 if mission.player and mission.player.climbing else -30
	if mission.player and mission.player.climbing and not mission.paused:
		chain_clock+=delta
		if chain_clock>2.2:
			chain_clock=0
			mission.sound("res://assets/audio/wood.wav",-27)
func track_for_mission()->String:
	if mission.stage=="complete":return "victory"
	if mission.stage=="modern":return "modern"
	if mission.get("ending_active")==true:return "victory"
	if mission.get("assault") and mission.assault.bridgehead_cleared:return "victory"
	if mission.player and mission.player.climbing:return "chain_battle"
	if mission.stage=="combat" or (mission.get("assault") and mission.assault.active):return "assault"
	return "advance"
func dialogue_tick():
	# A subdued cloth / interface cue; no synthetic voice pretending to be dialogue.
	mission.sound("res://assets/audio/wood.wav",-35)

func enqueue_voice(who:String,line:String):
	var key=(who+":"+line).md5_text()
	if line.is_empty(): return
	var now=Time.get_ticks_msec()
	if recent.has(key) and now-int(recent[key])<6000: return
	recent[key]=now
	voice_queue.append({"who":who,"text":line,"key":key})
	if voice_queue.size()>6: voice_queue.pop_front()

func _next_voice():
	last_voice=voice_queue.pop_front()
	mission.hud.dialogue(last_voice.who,last_voice.text)
	var entry=voice_manifest.get(last_voice.key,{})
	var path=str(entry.get("file",""))
	if not path.is_empty() and ResourceLoader.exists(path):
		voice_busy=true
		voice.stream=load(path); voice.volume_db=-1; voice.play()
		mission.hud.bark_time=voice.stream.get_length()+.3
		_set_speaker(last_voice.who,true)
	else:
		voice_wait=maxf(3.0,float(last_voice.text.length())*.18)
		mission.hud.bark_time=voice_wait

func _set_speaker(who:String,value:bool):
	if not mission.has_method("actor_by_name"): return
	var actor=mission.actor_by_name(who)
	if actor and actor.visual and "voice_active" in actor.visual: actor.visual.voice_active=value

func _voice_finished():
	if not last_voice.is_empty(): _set_speaker(last_voice.who,false)
	voice_busy=false
	voice_wait=.25

func clear_voice():
	if voice: voice.stop(); voice.stream=null
	if not last_voice.is_empty(): _set_speaker(last_voice.who,false)
	voice_queue.clear(); last_voice.clear(); recent.clear(); voice_wait=0; voice_busy=false
	if mission.hud: mission.hud.dialogue("","")
func _exit_tree():
	clear_voice()
	for player in players:
		player.stop()
		player.stream=null
	if wind:
		wind.stop()
		wind.stream=null
