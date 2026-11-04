extends Node
## Exactly one music player: every change fades through silence, so tracks
## cannot accumulate. Voices and ambient wind are ducked independently.
var mission
var music:AudioStreamPlayer
var voice:AudioStreamPlayer
var wind:AudioStreamPlayer
var fx:Array=[]
var current:=""
var wanted:="shortage"
var level:=0.0
var fx_index:=0
var master:=.85
var music_volume:=.85
var effects_volume:=.85
var voice_volume:=1.0
var spatial_ambience:Array=[]
const Envelopes=preload("res://game/golden_hook/voice_envelopes.gd")
var voice_id:=""
var voice_energy:=0.0
func _ready():
	music=AudioStreamPlayer.new(); voice=AudioStreamPlayer.new(); wind=AudioStreamPlayer.new()
	for node in [music,voice,wind]: add_child(node)
	for i in 4:
		var n=AudioStreamPlayer.new(); add_child(n); fx.append(n)
	wind.stream=_wave("wind",true); wind.volume_db=-31; wind.play()
	for point in mission.world.PONDS:
		_ambience("pond_ambience",point+Vector3(0,.1,0),6.0)
	for point in [mission.world.CAMP,mission.world.LAST_CAMP]:
		_ambience("camp_ambience",point+Vector3(0,.4,0),2.6)
func _ambience(id:String,point:Vector3,reach:float):
	var p=AudioStreamPlayer3D.new();add_child(p);p.position=point;p.stream=_wave(id,true);p.unit_size=reach;p.max_distance=30;p.volume_db=-27;p.play();spatial_ambience.append(p)
func _wave(id:String,loop:=false):
	var path="res://assets/golden_hook/audio/"+id+".wav"
	if not ResourceLoader.exists(path): return null
	var stream=load(path)
	if loop and stream is AudioStreamWAV: stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
	return stream
func set_mood(id:String): wanted=id
func speak(row:Dictionary)->float:
	voice.stop()
	voice_id=str(row.id); voice_energy=0
	var path="res://assets/golden_hook/audio/voice/"+str(row.id)+".wav"
	if ResourceLoader.exists(path):
		voice.stream=load(path); voice.volume_db=linear_to_db(maxf(.0001,master*voice_volume*.88)); voice.play()
		return voice.stream.get_length()+.14
	return maxf(3.0,str(row.text).length()*.16)
func stop_voice(): voice.stop(); voice_energy=0; voice_id=""
func cue(id:String):
	var stream=_wave(id)
	if not stream: return
	var p=fx[fx_index%fx.size()]; fx_index+=1; p.stream=stream; p.volume_db=linear_to_db(maxf(.0001,master*effects_volume*.23)); p.play()
func set_paused(value:bool):
	for p in [music,voice,wind]+fx+spatial_ambience: p.stream_paused=value
func _process(delta):
	if mission and mission.paused: return
	voice_energy=0
	if voice.playing and Envelopes.LINES.has(voice_id):
		var values=Envelopes.LINES[voice_id]; var index=int(voice.get_playback_position()*Envelopes.HZ)
		if index>=0 and index<values.size(): voice_energy=float(values[index])
	if wanted!=current:
		level=move_toward(level,0,delta*.34)
		if level<=.001:
			music.stop(); current=wanted
			if current!="silence": music.stream=_wave(current,true); music.play()
	else: level=move_toward(level,1,delta*.30)
	var duck=.20 if voice.playing else 1.0
	music.volume_db=linear_to_db(maxf(.00001,level*master*music_volume*.23*duck))
	voice.volume_db=linear_to_db(maxf(.00001,master*voice_volume*.88))
	wind.volume_db=linear_to_db(maxf(.00001,master*effects_volume*(.035 if voice.playing else (.11 if mission and mission.story.step in ["search","last_fishing"] else .055))))
	for p in spatial_ambience:p.volume_db=linear_to_db(maxf(.00001,master*effects_volume*(.047 if voice.playing else .09)))
func _exit_tree():
	for p in [music,voice,wind]+fx+spatial_ambience:
		if is_instance_valid(p): p.stop(); p.stream=null
